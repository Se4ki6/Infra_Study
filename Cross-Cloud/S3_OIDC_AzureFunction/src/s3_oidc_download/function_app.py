"""
Azure Function (Python, isolated) - OIDCフェデレーション経由でS3からファイルをダウンロードする。

流れ:
  1. マネージドIDでEntra IDからJWTを取得する (AZURE_TOKEN_SCOPE 宛て)
  2. そのJWTを持ってAWS STSのAssumeRoleWithWebIdentityを呼ぶ
  3. 得られた一時クレデンシャルでS3からオブジェクトを取得する

長期のAWSアクセスキーはどこにも登場しない。
"""

import base64
import json
import logging
import os

import azure.functions as func
import boto3
from azure.core.exceptions import ClientAuthenticationError
from azure.identity import ManagedIdentityCredential
from botocore.exceptions import ClientError

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)


def _get_azure_jwt() -> str:
    """マネージドIDでAZURE_TOKEN_SCOPE宛てのアクセストークンを取得する。"""
    scope = os.environ["AZURE_TOKEN_SCOPE"]  # 例: api://<client-id>/.default
    credential = ManagedIdentityCredential()
    token = credential.get_token(scope)
    return token.token


def _decode_jwt_claims(jwt: str) -> dict:
    """デバッグ用: 署名検証はせずpayload部分だけをデコードする。"""
    payload_b64 = jwt.split(".")[1]
    padding = "=" * (-len(payload_b64) % 4)
    payload_json = base64.urlsafe_b64decode(payload_b64 + padding)
    return json.loads(payload_json)


def _assume_role_with_web_identity(jwt: str) -> dict:
    """JWTを使ってAWS STSから一時クレデンシャルを取得する。"""
    sts = boto3.client("sts", region_name=os.environ["AWS_REGION"])
    response = sts.assume_role_with_web_identity(
        RoleArn=os.environ["AWS_WEB_IDENTITY_ROLE_ARN"],
        RoleSessionName="azure-function-oidc",
        WebIdentityToken=jwt,
        DurationSeconds=int(os.environ.get("AWS_STS_SESSION_DURATION_SECONDS", "3600")),
    )
    return response["Credentials"]


def _s3_client(credentials: dict):
    return boto3.client(
        "s3",
        region_name=os.environ["AWS_REGION"],
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
    )


def _full_key(key: str) -> str:
    prefix = os.environ.get("AWS_S3_PREFIX", "")
    return f"{prefix}/{key}" if prefix else key


@app.route(route="token-claims", methods=["GET"])
def token_claims(req: func.HttpRequest) -> func.HttpResponse:
    """
    Entra IDから実際に発行されたトークンのiss/aud/subを確認するデバッグ用エンドポイント。
    terraform/aws の azure_token_version / azure_oidc_audience / azure_function_principal_id が
    実際の値と一致しているかをここで確認してから apply する。
    """
    try:
        jwt = _get_azure_jwt()
        claims = _decode_jwt_claims(jwt)
        body = {
            "iss": claims.get("iss"),
            "aud": claims.get("aud"),
            "sub": claims.get("sub"),
            "appid": claims.get("appid") or claims.get("azp"),
        }
        return func.HttpResponse(json.dumps(body, ensure_ascii=False), mimetype="application/json")
    except ClientAuthenticationError:
        logging.exception("failed to acquire token from Entra ID")
        return func.HttpResponse("failed to acquire token from Entra ID", status_code=500)


@app.route(route="files", methods=["GET"])
def list_files(req: func.HttpRequest) -> func.HttpResponse:
    """AWS_S3_PREFIX配下のオブジェクト一覧を返す。"""
    try:
        jwt = _get_azure_jwt()
        credentials = _assume_role_with_web_identity(jwt)
        s3 = _s3_client(credentials)

        prefix = os.environ.get("AWS_S3_PREFIX", "")
        response = s3.list_objects_v2(Bucket=os.environ["AWS_S3_BUCKET"], Prefix=prefix)
        keys = [obj["Key"] for obj in response.get("Contents", [])]
        return func.HttpResponse(json.dumps(keys, ensure_ascii=False), mimetype="application/json")
    except ClientError:
        logging.exception("failed to list objects in S3")
        return func.HttpResponse("failed to list objects in S3", status_code=500)


@app.route(route="download/{key}", methods=["GET"])
def download(req: func.HttpRequest) -> func.HttpResponse:
    """指定したキーのオブジェクトをS3からダウンロードして返す。"""
    key = req.route_params.get("key")
    if not key:
        return func.HttpResponse("key is required", status_code=400)

    try:
        jwt = _get_azure_jwt()
        credentials = _assume_role_with_web_identity(jwt)
        s3 = _s3_client(credentials)

        obj = s3.get_object(Bucket=os.environ["AWS_S3_BUCKET"], Key=_full_key(key))
        body = obj["Body"].read()
        content_type = obj.get("ContentType", "application/octet-stream")

        return func.HttpResponse(
            body,
            mimetype=content_type,
            status_code=200,
            headers={"Content-Disposition": f'attachment; filename="{key}"'},
        )
    except ClientError as e:
        logging.exception("failed to download object from S3")
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        status_code = 404 if error_code == "NoSuchKey" else 500
        return func.HttpResponse(f"failed to download object: {error_code}", status_code=status_code)

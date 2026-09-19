"""
Azure Function (Python, isolated) - Azureリソース消し忘れチェッカー。

流れ:
  1. enqueue_check: HTMLのボタン押下を受けてjob_idを発行し、Storage Queueに投入する
  2. resource_checker: Queueメッセージをトリガーに、マネージドID(Reader)でAzure Resource
     Graphに問い合わせ、サブスクリプション内の全リソースを取得してTable Storageに書き込む
  3. get_status: HTMLがjob_idでポーリングして状態・結果を取得する

Table Storage(jobstatus)の1行がジョブ1件分の状態を表す。
"""

import json
import logging
import os
import uuid
from datetime import datetime, timezone

import azure.functions as func
from azure.core.exceptions import ResourceNotFoundError
from azure.data.tables import TableServiceClient
from azure.identity import ManagedIdentityCredential
from azure.mgmt.resourcegraph import ResourceGraphClient
from azure.mgmt.resourcegraph.models import QueryRequest
from azure.storage.queue import QueueClient

QUEUE_NAME = "resource-check-jobs"
TABLE_NAME = "jobstatus"
PARTITION_KEY = "job"

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)


def _storage_connection_string() -> str:
    # Function App作成時にstorage_account_name/access_keyから自動設定される接続文字列。
    # Queue/Tableとも同じStorage Accountに相乗りさせているので、これを使い回す。
    return os.environ["AzureWebJobsStorage"]


def _table_client():
    service = TableServiceClient.from_connection_string(_storage_connection_string())
    return service.get_table_client(TABLE_NAME)


def _queue_client() -> QueueClient:
    return QueueClient.from_connection_string(_storage_connection_string(), QUEUE_NAME)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@app.route(route="enqueue-check", methods=["POST"])
def enqueue_check(req: func.HttpRequest) -> func.HttpResponse:
    """リクエストボタン押下で呼ばれる。job_idを発行してQueueに積む。"""
    job_id = str(uuid.uuid4())

    table = _table_client()
    table.create_entity(
        {
            "PartitionKey": PARTITION_KEY,
            "RowKey": job_id,
            "status": "queued",
            "requestedAt": _now_iso(),
        }
    )

    queue = _queue_client()
    queue.send_message(json.dumps({"job_id": job_id}))

    return func.HttpResponse(
        json.dumps({"job_id": job_id}, ensure_ascii=False),
        mimetype="application/json",
        status_code=202,
    )


@app.route(route="get-status/{job_id}", methods=["GET"])
def get_status(req: func.HttpRequest) -> func.HttpResponse:
    """ブラウザがポーリングしてジョブの状態・結果を取得する。"""
    job_id = req.route_params.get("job_id")
    if not job_id:
        return func.HttpResponse("job_id is required", status_code=400)

    table = _table_client()
    try:
        entity = table.get_entity(partition_key=PARTITION_KEY, row_key=job_id)
    except ResourceNotFoundError:
        return func.HttpResponse("job not found", status_code=404)

    body = {
        "job_id": job_id,
        "status": entity.get("status"),
        "requestedAt": entity.get("requestedAt"),
        "completedAt": entity.get("completedAt"),
        "resourceCount": entity.get("resourceCount"),
        "resources": json.loads(entity["resultJson"]) if entity.get("resultJson") else None,
        "error": entity.get("error"),
    }
    return func.HttpResponse(json.dumps(body, ensure_ascii=False), mimetype="application/json")


@app.queue_trigger(arg_name="msg", queue_name=QUEUE_NAME, connection="AzureWebJobsStorage")
def resource_checker(msg: func.QueueMessage) -> None:
    """Queueメッセージをトリガーに、サブスクリプション内の全リソースを取得する。

    失敗時もジョブを"failed"としてTableに記録したいので、ここでは例外を送出せず
    捕捉してstatusに反映する（送出すると呼び出し元のHTMLに何も届かないまま
    Queueがリトライ→毒キューに落ちるだけになる）。
    """
    job_id = json.loads(msg.get_body().decode("utf-8"))["job_id"]
    table = _table_client()

    try:
        credential = ManagedIdentityCredential()
        client = ResourceGraphClient(credential)
        query = QueryRequest(
            subscriptions=[os.environ["AZURE_SUBSCRIPTION_ID"]],
            query="Resources | project name, type, resourceGroup, location, tags"
            " | order by resourceGroup asc, name asc",
        )
        resources = client.resources(query).data

        table.update_entity(
            {
                "PartitionKey": PARTITION_KEY,
                "RowKey": job_id,
                "status": "completed",
                "completedAt": _now_iso(),
                "resourceCount": len(resources),
                "resultJson": json.dumps(resources, ensure_ascii=False),
            },
            mode="merge",
        )
    except Exception as e:
        logging.exception("failed to check resources for job %s", job_id)
        table.update_entity(
            {
                "PartitionKey": PARTITION_KEY,
                "RowKey": job_id,
                "status": "failed",
                "completedAt": _now_iso(),
                "error": str(e),
            },
            mode="merge",
        )

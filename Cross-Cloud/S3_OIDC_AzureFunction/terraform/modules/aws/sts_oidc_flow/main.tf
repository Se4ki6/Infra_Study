// ==============================================================================
// module: sts_oidc_flow
// ==============================================================================
//   Azure Function（マネージドID）                    AWS
//   ① Entra ID から JWT を取得
//   ② AssumeRoleWithWebIdentity (JWT を添付)  ──▶  IAM OIDC プロバイダで署名を検証
//                                                    信頼条件: aud + sub が一致
//   ③ 一時クレデンシャル                       ◀──  IAM ロール（S3 読み取り）
//
// 長期の AWS 認証情報がどこにも登場しない。これが OIDC フェデレーションの要。
// ==============================================================================

locals {
  // 信頼する issuer。トークンのバージョンで変わる。
  //
  // ※ v1 トークンの iss は末尾スラッシュ付き ("https://sts.windows.net/<tenant>/") だが、
  //    IAM の OIDC プロバイダ URL は末尾スラッシュなしで登録する（AWS 側で正規化される）。
  issuer_url = var.azure_token_version == "v2" ? "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0" : "https://sts.windows.net/${var.azure_tenant_id}"

  // 信頼ポリシーの条件キーは「スキームを除いた issuer」を接頭辞に使う
  // 例: sts.windows.net/<tenant>:aud
  condition_prefix = replace(local.issuer_url, "https://", "")

  discovery_url = "${local.issuer_url}/.well-known/openid-configuration"
}

// Entra ID のサーバー証明書チェーンを取得する。
// サムプリントをハードコードすると証明書更新のたびに壊れるため動的に解決する。
data "tls_certificate" "azure" {
  url = local.discovery_url
}

resource "aws_iam_openid_connect_provider" "this" {
  url = local.issuer_url

  // AWS はトークンの aud クレームがこのリストに含まれることを検証する
  client_id_list = [var.azure_oidc_audience]

  // チェーンの末尾 = ルートCAのサムプリント
  thumbprint_list = [
    data.tls_certificate.azure.certificates[length(data.tls_certificate.azure.certificates) - 1].sha1_fingerprint
  ]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-entra-id"
  })
}

// ------------------------------------------------------------------------------
// Web Identity で Assume される S3 アクセス用ロール
// ------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  name                 = "${var.name_prefix}-s3-access-oidc"
  description          = "S3 read-only role assumed via Entra ID OIDC token (AssumeRoleWithWebIdentity)"
  max_session_duration = var.max_session_duration

  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = var.tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowAzureManagedIdentityToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    // aud: トークンの宛先。登録したアプリ以外向けのトークンを弾く
    condition {
      test     = "StringEquals"
      variable = "${local.condition_prefix}:aud"
      values   = [var.azure_oidc_audience]
    }

    // sub: トークンの主体 = マネージドIDのオブジェクトID。
    // これを付けないと「同じテナントの誰でも」Assumeできてしまうので必ず設定する。
    dynamic "condition" {
      for_each = var.azure_function_principal_id == "" ? [] : [1]

      content {
        test     = "StringEquals"
        variable = "${local.condition_prefix}:sub"
        values   = [var.azure_function_principal_id]
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.this.name
  policy_arn = var.s3_read_policy_arn
}

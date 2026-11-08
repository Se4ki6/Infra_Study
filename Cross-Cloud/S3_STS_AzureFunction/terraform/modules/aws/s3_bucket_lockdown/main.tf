// ==============================================================================
// module: s3_bucket_lockdown
// ==============================================================================
// この構成の中核。「S3 へのアクセスは STS 経由のみ」を *強制* している部分。
//
// なぜ IAM ポリシーだけでは足りないのか:
//   IAM ポリシーは「そのロールに許可を与える」だけで、同じアカウント内の他の
//   IAM ユーザー/ロールが自分の権限でバケットを直接触るのを止められない。
//   バケットポリシーの明示的 Deny を置いて初めて
//   「許可した STS ロール以外は誰も触れない」状態になる。
//
//   評価順序:  明示的 Deny  >  明示的 Allow  >  暗黙の Deny
//   なのでこの Deny はアカウント内の AdministratorAccess すら上書きする。
//
// バケット本体とは別モジュールにしてある。ポリシーは STS ロールの unique_id を
// 入力に取るため、バケットモジュールに同居させるとモジュール間で循環参照になるため。
// ==============================================================================

resource "aws_s3_bucket_policy" "this" {
  bucket = var.bucket_id
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  // ----------------------------------------------------------------------------
  // 1. HTTPS 以外を拒否 (ロックダウンの有無にかかわらず常に適用)
  // ----------------------------------------------------------------------------
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      var.bucket_arn,
      "${var.bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  // ----------------------------------------------------------------------------
  // 2. STS ロール / 管理者以外を全拒否
  // ----------------------------------------------------------------------------
  // aws:userId が許可リストのどれにも「一致しない」場合に Deny する。
  // StringNotLike なのでワイルドカード ("AROA...:*") が使える。
  dynamic "statement" {
    for_each = var.enable_lockdown ? [1] : []

    content {
      sid    = "DenyAllExceptStsAssumedRoles"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = ["s3:*"]

      resources = [
        var.bucket_arn,
        "${var.bucket_arn}/*",
      ]

      condition {
        test     = "StringNotLike"
        variable = "aws:userId"
        values   = var.allowed_user_ids
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !var.enable_lockdown || length(var.allowed_user_ids) > 0
      error_message = "enable_lockdown = true の場合、allowed_user_ids を空にはできません (全 principal が締め出されます)。"
    }
  }
}

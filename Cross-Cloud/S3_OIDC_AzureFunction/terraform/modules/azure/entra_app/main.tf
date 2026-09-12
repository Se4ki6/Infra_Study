// ==============================================================================
// module: entra_app
// ==============================================================================
// OIDCトークンの宛先（aud）になるEntra IDアプリ登録。
//
// マネージドIDは「誰向けのトークンか」を指定してトークンを要求する。
// その宛先として専用のアプリを1つ登録し、AWS側ではそのaudだけを信頼する。
// （management.azure.comなど既存リソース向けのトークンを流用してはいけない。
//  他用途で発行されたトークンでS3に入れてしまうことになるため）
// ==============================================================================

resource "azuread_application" "this" {
  display_name = var.display_name
  owners       = var.owner_object_ids

  // このアプリ宛のアクセストークンのバージョン。issuerとaudの形式が変わる
  api {
    requested_access_token_version = var.requested_access_token_version
  }

  // identifier_urisはazuread_application_identifier_uriが専属で管理する。
  // ここで無視しないと、無関係な変更のapplyのたびにこの属性が未設定(空)だと
  // 判定されて上書きされ、下のリソースが設定したURIが消えてしまう。
  lifecycle {
    ignore_changes = [identifier_uris]
  }
}

// identifier_uriは自分自身のclient_idを参照するため、
// 循環参照を避けて専用リソースで後付けする
resource "azuread_application_identifier_uri" "this" {
  application_id = azuread_application.this.id
  identifier_uri = "api://${azuread_application.this.client_id}"
}

// マネージドIDがこのアプリ宛のトークンを要求するには、
// テナント内にサービスプリンシパルが存在している必要がある
resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false
  owners                       = var.owner_object_ids

  depends_on = [azuread_application_identifier_uri.this]
}

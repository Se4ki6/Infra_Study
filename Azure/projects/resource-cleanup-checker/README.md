# resource-cleanup-checker

> HTMLのボタン押下でAzure Storage Queueにジョブを投入し、Queue Trigger FunctionがAzure Resource Graphでサブスクリプション内の全リソースを確認する（個人開発の消し忘れチェッカー）

## Features

- HTML（Storage静的サイト）のボタン押下 → HTTP Function → Storage Queue → Queue Trigger Function という非同期ジョブの構成
- Queue Triggerはブラウザに直接レスポンスを返せないため、結果はTable Storageに書き込み、HTML側は別のHTTP Functionをポーリングして取得する
- リソース取得はAzure Resource Graphを使い、サブスクリプション全体を1クエリで横断取得する
- Function Appのシステム割り当てマネージドIDにサブスクリプションスコープのReaderロールのみを付与（長期の認証情報は持たない）

## アーキテクチャ

```
[HTML (静的サイト)]
       │ ① POST /api/enqueue-check
       ▼
[enqueue_check (HTTP Function)] ── job_idを発行 ──▶ [Table Storage: jobstatus] (status=queued)
       │ ② メッセージ投入
       ▼
[Storage Queue: resource-check-jobs]
       │ ③ Queue Trigger
       ▼
[resource_checker (Queue Trigger Function)]
       │ ④ マネージドID(Reader)で問い合わせ
       ▼
[Azure Resource Graph] ── 全リソース ──▶ [Table Storage: jobstatus] (status=completed, resultJson)

[HTML] ── ⑤ GET /api/get-status/{job_id} を数秒間隔でポーリング ──▶ [get_status (HTTP Function)] ──▶ [Table Storage]
```

## Quick Start（構築手順）

### 前提条件

- Terraform >= 1.5
- Azure CLI（`az login` 済み。リソースグループ作成・ロール割り当てができる権限）
- Python 3.11 / Azure Functions Core Tools（デプロイ用）
- Azure CLI または Azure Storage Explorer（静的サイトへのHTMLアップロード用）

### セットアップ

1. インフラをapply

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # 必要なら値を編集（全変数にdefaultあり）
   terraform init
   terraform apply
   terraform output   # function_app_name / static_website_url / storage_account_name を控える
   ```

2. Functionのコードをデプロイ

   ```bash
   cd ../src/resource_checker
   func azure functionapp publish <function_app_name>
   ```

3. Function Keyを取得

   ```bash
   az functionapp keys list \
     --name <function_app_name> \
     --resource-group rg-rescheck-study \
     --query "functionKeys.default" -o tsv
   ```

   （`default`キーが無ければAzure Portalの Function App > 関数 > App keys から発行する）

4. HTMLにFunction App URLとFunction Keyを埋め込む

   ```bash
   cd ../../frontend
   cp index.html.example index.html
   # index.html内の FUNCTION_BASE_URL / FUNCTION_KEY を書き換える
   ```

5. 静的サイトにアップロード

   ```bash
   az storage blob upload \
     --account-name <storage_account_name> \
     --container-name '$web' \
     --name index.html \
     --file index.html \
     --auth-mode login \
     --overwrite
   ```

6. `terraform output static_website_url` のURLをブラウザで開き、「リソースを確認」を押す

## ディレクトリ構成

- `terraform/` - リソースグループ・Storage Account（Queue/Table/静的サイト）・Function App一式
- `src/resource_checker/` - Azure Function（Python）本体（enqueue_check / get_status / resource_checker）
- `frontend/` - リクエストボタンを持つ静的HTML（`index.html.example` がテンプレート）

## セキュリティ・運用上のポイント

- Functionは`http_auth_level=FUNCTION`（Function Key必須）。個人利用専用ページである前提で、キーはHTMLに埋め込む方式にしている（view-sourceで見える点は許容している）
- Function AppのマネージドIDにはサブスクリプションスコープの**Reader**のみを付与。リソースの変更・削除はできない
- Queue/Table操作はFunction App作成時に自動設定される`AzureWebJobsStorage`（Storage Accountの接続文字列）を使い回しており、追加のシークレットは持たない
- Table Storageの文字列プロパティには64KBの上限があるため、リソース数が非常に多いサブスクリプションでは`resultJson`が収まらない可能性がある（個人開発規模を想定し、対応は未実装）
- `resource_checker`はマネージドIDを直接使うため、ローカル実行では動作しない（デプロイ後にクラウド上で確認する）

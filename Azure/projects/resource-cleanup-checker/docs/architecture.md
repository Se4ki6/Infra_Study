# resource-cleanup-checker: リソース全体像

このプロジェクトで実際に作成されたAzureリソースと、それらの関係・役割をまとめる。値は`japaneast`にデプロイした実環境（`terraform apply`実行後）のもの。

## 全体フロー

```
[ブラウザ]
   │ ① 静的サイトを開く
   ▼
[streschecka7f1vz ($web コンテナ)] ── 静的サイトURL: https://streschecka7f1vz.z11.web.core.windows.net/
   │ ② index.htmlの「リソースを確認」ボタン押下
   │    POST /api/enqueue-check (Function Key付き)
   ▼
[func-rescheck-study : enqueue_check (HTTP Function)]
   │ ③ job_idを発行してTableに status=queued を書き込み
   ▼                                      ▲
[streschecka7f1vz : Table "jobstatus"] ───┘
   │
   │ ④ job_idをメッセージとしてQueueに投入
   ▼
[streschecka7f1vz : Queue "resource-check-jobs"]
   │ ⑤ Queue Trigger
   ▼
[func-rescheck-study : resource_checker (Queue Trigger Function)]
   │ ⑥ システム割り当てマネージドID(Reader)でAzure Resource Graphに問い合わせ
   ▼
[Azure Resource Graph] ── sekishiro-learnサブスクリプション内の全リソース ──┐
                                                                          ▼
                                            [streschecka7f1vz : Table "jobstatus"]
                                              (status=completed, resultJson書き込み)

[ブラウザ] ── ⑦ GET /api/get-status/{job_id} を3秒間隔でポーリング ──▶ [func-rescheck-study : get_status (HTTP Function)] ──▶ [Table "jobstatus"]
```

## 作成されたAzureリソース一覧

リソースグループ: **rg-rescheck-study**（japaneast）

| リソース名 | 種類 | 役割 |
| --- | --- | --- |
| `rg-rescheck-study` | Resource Group | このプロジェクトの全リソースの入れ物 |
| `streschecka7f1vz` | Storage Account | Functionsランタイム用ストレージ・Queue・Table・静的サイト($webコンテナ)を1つに集約 |
| `plan-rescheck-study` | App Service Plan（Y1 = Consumption） | Function Appの実行基盤。従量課金・0インスタンスまでスケールイン |
| `func-rescheck-study` | Function App（Python, Linux） | `enqueue_check` / `get_status` / `resource_checker` の3関数をホスト。システム割り当てマネージドIDを持つ |
| `log-rescheck-study` | Log Analytics Workspace | Application Insightsのログ保存先（保持30日） |
| `appi-rescheck-study` | Application Insights | Function Appの実行ログ・メトリクス監視 |
| (Storage Account内) Queue `resource-check-jobs` | Storage Queue | ジョブ投入用キュー |
| (Storage Account内) Table `jobstatus` | Table Storage | ジョブごとの状態・結果を保持（PartitionKey=`job`, RowKey=`job_id`） |
| (Storage Account内) `$web`コンテナ | Blob（静的サイト） | `index.html`を配信 |

## Function App の中身

エンドポイント: `https://func-rescheck-study.azurewebsites.net/api`（すべて`http_auth_level=FUNCTION`、Function Key必須）

| 関数名 | トリガー | 役割 |
| --- | --- | --- |
| `enqueue_check` | HTTP POST `/enqueue-check` | job_idを発行し、Tableに`status=queued`を書き込んでQueueにメッセージ投入 |
| `get_status` | HTTP GET `/get-status/{job_id}` | Tableからジョブの状態・結果を読んでブラウザに返す（ポーリング用） |
| `resource_checker` | Queue Trigger（`resource-check-jobs`） | マネージドID経由でAzure Resource Graphに問い合わせ、結果をTableに書き込む |

## 権限（マネージドID）

- Function App `func-rescheck-study` はシステム割り当てマネージドID（principal_id: `77fb2c1f-124b-46ee-a5e0-38d600a875f9`）を持つ
- サブスクリプション`sekishiro-learn`スコープで **Reader** ロールのみ付与（`azurerm_role_assignment.reader`、[terraform/modules/function_app/main.tf](../terraform/modules/function_app/main.tf)）
- Queue/Table操作は、Function App作成時に自動設定される`AzureWebJobsStorage`（Storage Accountの接続文字列）を使い回しており、追加のシークレットは持たない

## フロントエンド

- テンプレート: [frontend/index.html.example](../frontend/index.html.example)（Gitで追跡）
- 実体: `frontend/index.html`（`FUNCTION_BASE_URL`/`FUNCTION_KEY`を埋め込み済み、Function Keyを含むため`.gitignore`で除外）
- 配信先: `streschecka7f1vz`の`$web`コンテナ → `https://streschecka7f1vz.z11.web.core.windows.net/`
- アップロード方法: `az storage blob upload --auth-mode key`（自分のAADアカウントにBlobデータプレーン権限がないため`--auth-mode login`は使えない。[トラブルシューティング参照](#既知のハマりどころ)）

## Terraformのモジュール構成

```
terraform/
├── main.tf              … リソースグループを作り、下記2モジュールを呼び出すだけ
├── modules/
│   ├── storage/          … Storage Account（ランタイム用ストレージ・Queue・Table・静的サイト）
│   └── function_app/     … App Service Plan・Function App・監視・Readerロール割り当て
```

storage と function_app を分けているのは、Storage Accountが「Functionsランタイム／Queue／Table／静的サイト」という複数役割を持つため、責務ごとに分離した方が読みやすいという判断による。

## 既知のハマりどころ

- **静的サイトのURLはBlobエンドポイントと別ドメイン**: `https://streschecka7f1vz.blob.core.windows.net/$web/index.html`は404になる。必ず`https://streschecka7f1vz.z11.web.core.windows.net/`（`terraform output static_website_url`）を使う
- **`az storage blob upload --auth-mode login`は権限エラーになりうる**: サブスクリプションのOwner/Contributorはコントロールプレーン権限であり、Blobのデータプレーン操作には別途`Storage Blob Data Contributor`等のRBACロールが必要。個人利用なら`--auth-mode key`で回避するのが簡単
- **`func azure functionapp publish`はプロジェクトルート（`host.json`のある階層）で実行する必要がある**: `src/resource_checker/`配下で実行する
- **ホスティングプランはY1(Consumption)を採用**: 個人利用の低頻度アクセス規模なら無料枠（月100万実行・40万GB-s）に収まりやすい。詳細比較は[Azure Functions: Consumption plan vs Flex Consumption plan](../../../docs/functions-consumption-vs-flex-consumption.md)を参照

# コスト概算

`terraform/` が作成するリソース（East Japan / japaneast）について、個人開発規模（月数回〜数十回ボタンを押す程度の利用）を前提にコストを概算する。

> 実際の単価はAzureの価格改定やリージョン・為替レートで変動するため、正確な見積もりは[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)で都度確認すること。ここでは2026年時点の目安（1USD ≈ 150円換算）を記載する。

## 前提とする使用量

- ボタン押下（=Function実行）：月10〜50回程度
- 1回の処理で発生するFunction実行：HTTP(enqueue) 1回 + Queue Trigger 1回 + HTTP(get_status) を数回ポーリング ≒ 1回あたり合計10〜20実行
- 月間の総Function実行回数：概ね数百〜1,000回程度（無料枠の1,000,000回/月に対して極めて少ない）
- ログ出力量：個人開発規模のため月間1GB未満を想定

## リソース別の内訳

### 1. Function App（`azurerm_service_plan` + `azurerm_linux_function_app`、SKU: Y1 = Consumption）

Consumptionプランは実行課金型で、基本料金（サーバー予約料金）は発生しない。

- 無料枠：**100万実行/月 + 400,000 GB-s/月**（東日本を含む全リージョン共通）
- 超過分の目安単価：実行 $0.20/100万回、実行時間 $0.000016/GB-s
- 上記使用量（数百〜1,000実行/月、GB-sも僅少）は無料枠に収まるため、**実質 ¥0/月**

### 2. Storage Account（`azurerm_storage_account`、Standard LRS）

Queue・Table・静的サイト（$web、index.html 1枚）を1アカウントに集約している。

- 容量課金：Standard LRS Hot層で目安 ¥3〜4/GB/月。保存データはHTML1枚＋Queueメッセージ＋Tableレコード数十件程度で数MB〜数十MB → **月数円未満**
- トランザクション課金：Queue/Tableの読み書きは10,000操作あたり数円程度。月数百操作なら **月1円未満**
- 静的サイトの帯域（送信データ）：個人利用の閲覧数なら誤差レベル

合計目安：**月数円程度**

### 3. Log Analytics Workspace（`azurerm_log_analytics_workspace`、PerGB2018、保持30日）

Function App / Application Insights のログ・メトリクスがここに集約される。

- 無料枠：**5GB/月の取り込みまで無料**
- 超過分の目安単価：¥380〜420/GB程度
- 保持期間：デフォルトの31日分は無料（`log_retention_in_days = 30` は無料枠内）
- 個人開発規模のログ量（数百実行分の実行ログ）は5GB/月を大きく下回るため、**実質 ¥0/月**

### 4. Application Insights（`azurerm_application_insights`、workspace-based）

Workspace-basedのApplication Insightsは取り込みデータがLog Analytics Workspace側の課金に統合されるため、**Application Insights単体の追加コストはなし**（上記3.に含まれる）。

### 5. その他

- `azurerm_resource_group`：無料
- `azurerm_role_assignment`（Reader）：無料
- `random_string`：Terraform内部リソースのためコストなし

## 合計目安

| リソース | 月額目安 |
|---|---|
| Function App（Consumption） | ¥0（無料枠内） |
| Storage Account | 数円程度 |
| Log Analytics Workspace | ¥0（無料枠内） |
| Application Insights | ¥0（Log Analyticsに統合） |
| **合計** | **月数円〜数十円程度** |

個人開発規模で使う限りは、Function実行数・ログ量ともに各サービスの無料枠内に収まり、実質的な出費はStorage Accountの容量・トランザクション課金分（数円）のみに収まる見込み。

## Storage QueueをService Bus Queueに置き換えた場合のコスト比較

本プロジェクトのQueueは単純なジョブキュー（FIFO保証・セッション・重複検出・トランザクション不要）なので、Service Busを使う場合はBasic tierで機能要件を満たせる。Standard/Premiumは本用途にはオーバースペック（機能面の詳細は[storage-queue-vs-service-bus-queue.md](../../../docs/storage-queue-vs-service-bus-queue.md)を参照）。

### Service Busの料金体系（tier別）

| Tier | 基本料金 | 操作課金 | 備考 |
|---|---|---|---|
| Basic | なし | $0.05/100万操作 | Queueのみ、スケジュール配信可、メッセージ最大256KB |
| Standard | $0.0135/時間（≒$9.7/月 ≒ ¥1,460/月、1USD=150円換算） ※最初の1,300万操作/月分を含む | 1,300万〜1億操作/月: $0.80/100万操作、以降逓減 | Topics/Sessions/トランザクション/重複検出が使える |
| Premium | Messaging Unit単位で時間課金（1MUで月$600台〜） | 購入容量内は無料 | 専有リソース、高スループット向け。個人開発では過剰 |

> 実際の単価はAzure Pricing Calculatorで要確認。上記はUSD建ての一般的な目安であり、日本円は概算換算。

### 本プロジェクトの使用量（月数百〜1,000操作程度）で比較

| | Storage Queue（現行） | Service Bus Basic | Service Bus Standard |
|---|---|---|---|
| 基本料金 | なし | なし | 約¥1,460/月（固定） |
| 操作課金 | 10,000操作あたり数円 | $0.05/100万操作 → 月1,000操作で **¥1円未満** | 無料枠（1,300万操作/月）内のため¥0円 |
| 月額目安 | 数円未満 | **数円未満**（Storage Queueとほぼ同水準） | **約¥1,460/月**（基本料金が発生する分、明確に割高） |

- **Basic tier**であればStorage Queueとコスト面での差はほぼない（どちらも無料枠・低単価に収まる）
- **Standard tier**は時間課金の基本料金が常時発生するため、低頻度な個人利用では固定費が丸ごと無駄になる。Sessions/重複検出/トランザクションが不要な本プロジェクトでは選ぶ理由がない
- Service Busを使う場合、`azurerm_servicebus_namespace` + `azurerm_servicebus_queue` が追加リソースとして必要になり、Function App側もQueue Trigger用の接続文字列またはマネージドID（Azure Service Bus Data Receiver/Senderロール）の設定が別途必要になる（Storage Queueは既存のStorage Accountに相乗りできる分、構成がシンプル）

### 結論

コスト・構成のシンプルさの両面で、本プロジェクトの規模・要件（FIFO/セッション/トランザクション不要）ではStorage Queueを使い続ける現行構成が妥当。Service Busへの切り替えを検討する価値があるのは、将来的にPub/Sub（Topics）や重複排除、順序保証が必要になった場合。

## コストが増える可能性がある要因

- Function実行を高頻度・自動化（cron等）で回すようになり月100万実行や400,000 GB-sを超えた場合
- ログレベルを詳細化してLog Analyticsの取り込み量が5GB/月を超えた場合
- Table Storageの`resultJson`が大きくなり、Resource Graphの結果を持つサブスクリプションのリソース数が非常に多くなった場合（README記載の64KB上限の懸念とは別に、容量課金にも影響）
- `terraform destroy`を忘れて放置し、複数環境を同時に立てたままにした場合（本プロジェクトの主旨である「消し忘れ」自体がコストリスク）

# OpenTelemetryをコードで学ぶ

このガイドでは、この注文APIを動かしながら、ログ・トレース・メトリクスが何を表し、どのコードがそれを作っているかを確認します。

## まず全体像

OpenTelemetry（OTel）は、アプリケーションの動作を計測するための共通のAPIとSDKです。このサンプルでは、計測したデータを次のどちらかへ送ります。

- `APPLICATIONINSIGHTS_CONNECTION_STRING`を設定した場合: Azure Monitor OpenTelemetry DistroがテレメトリをApplication Insightsへ送ります。
- 未設定の場合: ローカル用Console Exporterがトレース・メトリクス・ログをターミナルに出します。

計測（instrumentation）と送信先（exporter）は別の役割です。たとえば注文処理のコードがActivityやログ、メトリクスを記録し、ExporterがそれをコンソールやApplication Insightsへ運びます。

```text
HTTPリクエスト
    |
    +-- ASP.NET Coreの自動計測: リクエストのスパン
    |
    +-- CreateOrderHandler: 注文作成スパン、ログ、メトリクス
    |
    +-- BlobOrderRepository: Azure Blob SDKの依存関係スパン
    |
    v
Console Exporter（ローカル）またはApplication Insights（Azure）
```

## 3つのシグナル

| シグナル | 答える問い | このサンプルで見るもの |
| --- | --- | --- |
| トレース | 1つのリクエストはどの処理を通り、どこで時間がかかったか | HTTPリクエスト、`orders.create`、Blob SDK呼び出し |
| ログ | その時に何が起きたか | 注文作成、入力拒否、保存エラーなどのメッセージ |
| メトリクス | 一定時間に何件起き、処理時間はどう変化したか | 注文要求数、処理時間、注文の商品数 |

### トレース: 1回の処理をたどる

トレースは、1回の処理に属するスパンの集まりです。ASP.NET Coreの自動計測がHTTPリクエストのスパンを作り、`CreateOrderHandler`が`orders.create`という子スパンを作ります。注文処理の中で呼ぶBlob SDKも、計測が有効なら依存関係スパンを作ります。

`ActivitySource.StartActivity`はスパンを開始します。現在のActivityがあれば、そのトレースを引き継いで子スパンになります。Application Insightsでは1つのリクエストを開き、子の注文処理とBlob Storage呼び出しが同じトレースに含まれるか見ます。

### ログ: 出来事を記録する

`ILogger`で記録したメッセージがログです。`{OrderId}`のようなプレースホルダーを使うと、値を構造化データとして記録できます。ログは「注文IDの注文を作成した」のような出来事を表し、トレースIDが関連付くと、どのリクエスト中のログか追いやすくなります。

### メトリクス: 数値を集計する

メトリクスは個々の注文の記録ではなく、数値の集計に向いています。

- `orders.requests` (`Counter<long>`): 作成要求を結果別に数えます。
- `order.processing.duration` (`Histogram<double>`): 作成処理にかかった時間を記録します。
- `orders.items` (`Histogram<long>`): 作成できた注文の商品数を記録します。

メトリクスの属性には`result=created`のような少数の値を使います。`orderId`や`productId`のようにリクエストごとに変わる値をメトリクス属性にすると時系列の数が増えすぎるため、ここではログやスパンに記録しています。

## コードを読む順番

1. [`src/Api/Program.cs`](../src/Api/Program.cs): DI、OpenTelemetryの購読設定、Exporter、HTTPエンドポイント。
2. [`src/Application/Orders/CreateOrder.cs`](../src/Application/Orders/CreateOrder.cs): 注文作成のユースケース。Activity、ログ、メトリクスを記録します。
3. [`src/Application/Telemetry.cs`](../src/Application/Telemetry.cs): 独自ActivitySource・Meter・各メトリクスの定義。
4. [`src/Application/Orders/IOrderRepository.cs`](../src/Application/Orders/IOrderRepository.cs): Applicationが必要とする保存機能の契約。
5. [`src/Infrastructure/BlobOrderRepository.cs`](../src/Infrastructure/BlobOrderRepository.cs): 契約をAzure Blob Storageで実装します。
6. [`src/Domain/Order.cs`](../src/Domain/Order.cs): 注文のデータと不変条件。

### `AddSource`と`AddMeter`は購読登録

`Program.cs`の`AddSource(Telemetry.ActivitySourceName)`と`AddMeter(Telemetry.MeterName)`は、Application側で作った計測器をOpenTelemetry SDKに購読させます。計測器を作るだけではSDKへ流れないため、名前を両側で一致させています。

### Application Insightsがない場合

ローカルモードではConsole Exporterを使い、HTTPリクエスト、Applicationの独自スパン、Azure SDKのActivity、ログ、メトリクスをターミナルへ出します。Azure SDKのActivitySource名は`Azure.*`の形式なので、ローカル側でその名前を購読しています。HTTP/RESTベースのAzure SDKトレースは標準で有効です。実験的なActivitySourceスイッチは一部の機能、特にService BusやEvent Hubsのメッセージトレースで必要になる場合があり、このBlobサンプルでは設定しません。

## 実行して観察する

必要なツールや起動方法は[プロジェクトREADME](../README.md)を参照してください。AzuriteとAPIを起動したら、正常系とエラー系を1回ずつ試します。

### 正常な注文

```sh
curl -i http://localhost:5080/orders \
  -H 'Content-Type: application/json' \
  -d '{"productId":"book-001","quantity":2}'
```

レスポンスの`id`を使って`GET /orders/{id}`を呼びます。トレース上ではHTTPリクエスト、注文処理、Blobへの保存または取得を探します。ログでは同じ注文IDを探します。

### 入力エラー

```sh
curl -i http://localhost:5080/orders \
  -H 'Content-Type: application/json' \
  -d '{"productId":"book-001","quantity":0}'
```

HTTP 400、入力拒否ログ、`result=rejected`の注文要求カウントを確認します。

### ストレージエラー

Azuriteを停止してから正常な注文を送ります。HTTP 503、保存失敗ログ、エラー状態の注文処理スパン、`result=storage_error`のカウントを確認します。Azuriteを再起動すれば、以降の保存を再び試せます。

## Application Insightsで見る

1. Azure Portalで手動作成したApplication InsightsのOverviewからConnection Stringをコピーします。
2. 環境変数`APPLICATIONINSIGHTS_CONNECTION_STRING`へ設定してAPIを再起動します。
3. 注文を数回送信し、Application InsightsのApplication Mapまたはトランザクション検索でリクエストを開きます。
4. Logsを開き、リクエスト・依存関係・ログ・メトリクスを確認します。

Application Insightsに届くまで少し時間がかかる場合があります。WorkspaceのLogs画面では、OTelのリクエストは`AppRequests`、依存関係は`AppDependencies`、ログは`AppTraces`、メトリクスは`AppMetrics`に保存されます。

直近のリクエスト:

```kusto
AppRequests
| where TimeGenerated > ago(30m)
| project TimeGenerated, Name, ResultCode, Success, DurationMs, OperationId
| order by TimeGenerated desc
```

アプリケーションログ:

```kusto
AppTraces
| where TimeGenerated > ago(30m)
| project TimeGenerated, SeverityLevel, Message, OperationId
| order by TimeGenerated desc
```

独自メトリクス:

```kusto
AppMetrics
| where TimeGenerated > ago(30m)
| where Name in ("orders.requests", "order.processing.duration", "orders.items")
| project TimeGenerated, Name, Sum, ItemCount, Properties
| order by TimeGenerated desc
```

`OperationId`は同じトレースに属するテレメトリを結び付ける識別子です。リクエスト結果からOperationIdをコピーして`AppTraces`や`AppDependencies`で絞ると、関連ログと依存関係を追えます。

## よくある疑問

### ActivityやMeterを作ったのに出力されないのはなぜ？

OpenTelemetry SDK側の`AddSource`・`AddMeter`登録が必要です。また、Exporterが起動していること、Azure Monitorを使う場合は接続文字列が設定されていることも確認します。

### Blob呼び出しのスパンが見えない

Azure SDKのActivitySource名が`Azure.*`として購読されているかを確認します。Application InsightsモードではAzure Monitor DistroがAzure SDK計測を設定し、ローカルモードでは`AddSource("Azure.*")`が購読します。SDKパッケージのバージョンや機能によって対応状況が異なる場合があります。

### メトリクスに注文IDを含めないのはなぜ？

メトリクスは多数の値を集計して傾向を見るものです。注文ごとに異なるIDを属性にすると、集計対象の系列が膨らみ、扱いにくくなります。個々の注文を追う値はログやスパンに置きます。

## 参考資料

- [Azure MonitorでOpenTelemetryを有効にする（ASP.NET Core）](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=net)
- [Azure SDK for .NETのActivitySourceとトレース](https://github.com/Azure/azure-sdk-for-net/blob/main/sdk/core/Azure.Core/samples/Diagnostics.md)
- [Application InsightsにおけるOpenTelemetry信号とLog Analyticsテーブル](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-filter)

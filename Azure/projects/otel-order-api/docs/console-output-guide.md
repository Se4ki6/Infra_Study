# `make dev` のコンソール出力の読み方

このガイドは、注文 API をローカルで動かしたときにターミナルへ出る文字を読むためのものです。OpenTelemetry（OTel）の基本的な仕組みは [初学者向けガイド](learning-guide.md)、計測しているコードの一覧は [実装ドキュメント](otel-order-api.md) を参照してください。

## まず何を見ればよいか

プロジェクト直下で `make dev` を実行すると、Make が実行コマンドを表示し、Docker Compose が Azurite を起動し、その後 .NET が API を起動します。次の順で確認してください。

1. `Now listening on: http://localhost:5080` が出たら API は起動しています。ここに表示された URL が実際の待受先です。`make dev PORT=5081` ならポートは `5081` になります。
2. `APPLICATIONINSIGHTS_CONNECTION_STRING is unset; telemetry will be printed locally.` が出たら、OTel のログ・トレース・メトリクスはこのターミナルに出ます。接続文字列を設定した場合は Azure Monitor / Application Insights に送る設定に切り替わります。
3. 起動後、注文 API や Swagger UI を操作すると出力が増えます。何も操作していなくても、メトリクスの定期的な出力やホスティングのログが表示されることがあります。

ログが多くても、最初から全行を読む必要はありません。`LogRecord`、`Activity`、`Metric Name` の目印で種類を分け、調べたい注文やリクエストに関係する行を探します。

## 出力の3種類

| 目印 | 何を表すか | 最初に見る項目 |
| --- | --- | --- |
| `LogRecord` | その時に起きた出来事 | `Body`、`SeverityText`、`CategoryName` |
| `Activity` | 1回の処理とその所要時間（スパン） | `DisplayName`、`Duration`、`TraceId` |
| `Metric Name` | 複数回の処理を数値で集計した結果 | メトリクス名、属性、`Value` または集計値 |

実際の出力には `Resource associated with ...` や `telemetry.sdk.*`、`service.name` も繰り返し表示されます。これらは「どのアプリと SDK が記録したか」という共通情報です。注文の成否を読むときは、まず上の項目に注目してください。

### ログ: `LogRecord`

次は、出力の一部を短くした例です。ID と時刻は実行ごとに変わります。

```text
LogRecord.CategoryName: OtelOrderApi.Application.Orders.CreateOrderHandler
LogRecord.SeverityText: Information
LogRecord.Body: Order <注文ID> created for product book-001 with quantity 2
LogRecord.TraceId: <トレースID>
```

`Body` が出来事の本文、`SeverityText` が重要度です。この API では、注文作成・取得・未検出は `Information`、入力拒否は `Warning`、Blob Storage の失敗は `Error` で記録します。`CategoryName` はログを書いたクラスを示します。`OrderId` などが `Attributes` に表示される場合は、後で注文を検索するための項目です。

`Microsoft.AspNetCore.*` や `Microsoft.Hosting.*` のログは ASP.NET Core 自体が書いています。たとえば `Request starting` は HTTP リクエストの開始、`Request finished` は終了です。同じリクエストに関係するアプリのログは `TraceId` で結び付けられます。

### トレース: `Activity`

`Activity` は処理の区間です。`DisplayName` に `orders.create` があれば注文作成、`orders.get` があれば注文取得の処理です。ASP.NET Core は HTTP リクエストの区間を、Azure Blob SDK は Blob 操作の区間を記録します。Blob SDK の区間が出るかどうかは SDK の計測状況にもよります。

```text
HTTP POST /orders        TraceId=A  SpanId=1
  orders.create          TraceId=A  SpanId=2  ParentSpanId=1
    Blob への操作        TraceId=A  SpanId=3  ParentSpanId=2
```

上は親子関係を説明する模式図です。実際のコンソールでは各 Activity が別の塊として表示されます。`TraceId` が同じなら同じリクエストに属し、`ParentSpanId` で親子関係を追えます。`Duration` はその区間の所要時間です。`Status: Error` や `order.result=rejected` / `storage_error` があれば、その注文処理は失敗側の結果です。

注文 ID と `TraceId` は役割が違います。注文 ID は保存された注文を識別し、`TraceId` は1回のリクエストの処理全体を識別します。

### メトリクス: `Metric Name`

メトリクスは個々の注文の記録ではなく、複数回の要求を集計した値です。この API が独自に記録するものは次の3つです。

| 名前 | 読み方 | 記録される場面 |
| --- | --- | --- |
| `orders.requests` | 注文作成の要求数。`result` 属性で結果別に見る | 成功 `created`、入力拒否 `rejected`、保存失敗 `storage_error` |
| `order.processing.duration` | 注文作成の所要時間。単位はミリ秒 | 成功・入力拒否・保存失敗のいずれでも記録 |
| `orders.items` | 作成に成功した注文の商品数 | 成功時だけ記録 |

`orders.requests` は Counter なので、出力された数値はその時点までの集計として読みます。Histogram の `order.processing.duration` と `orders.items` は、回数（`Count`）、合計（`Sum`）、分布などが表示されます。`order.processing.duration` の `Sum` は合計時間であり、1件あたりの時間ではありません。メトリクスは一定間隔でまとめて出るため、リクエストの直後に見つからない場合は少し待ってください。`GET /orders/{id}` は現状、これら3つの独自メトリクスを増やしません。

## 操作と出力を対応させる

別のターミナル、または Swagger UI から操作します。以下の URL は既定のポート `5080` の例です。

| 操作 | HTTP 応答 | 探す出力 |
| --- | --- | --- |
| `GET /health` | 200 | HTTP リクエストのログ・Activity。Blob にはアクセスせず、注文の独自メトリクスも増えない |
| 正常な `POST /orders` | 201 | `Order ... created`、`orders.create`、`orders.requests` の `result=created`、処理時間、商品数 |
| 数量 `0` の `POST /orders` | 400 | `Order request rejected`（Warning）、`orders.create` の Error、`result=rejected`、処理時間 |
| 存在しない ID の `GET /orders/{id}` | 404 | `Order ... was not found`（Information）、`orders.get` の `order.result=not_found` |
| Blob Storage 障害中の `POST /orders` | 503 | `Could not save order`（Error）、`orders.create` の Error、`result=storage_error` |

正常な注文を1件作る例:

```sh
curl -i http://localhost:5080/orders \
  -H 'Content-Type: application/json' \
  -d '{"productId":"book-001","quantity":2}'
```

この操作の後、まず `Order ... created` というログを探し、そこに表示された `TraceId` と同じ ID の `orders.create`、HTTP、Blob 操作を探します。続いて `orders.requests` の `result=created`、`order.processing.duration`、`orders.items` を見ます。Swagger UI を開いただけでも静的ファイルへの HTTP リクエストが複数発生するため、注文を追うときは `/orders` に関係する出力に絞ってください。

## よくある表示

| 表示 | 意味・確認先 |
| --- | --- |
| `NU1900` | NuGet の脆弱性情報を取得できなかったビルド時の警告。特定パッケージの脆弱性が見つかったという意味ではない。 |
| `Order request rejected` | 商品 ID が空、または数量が `0` 以下。HTTP 400 と `result=rejected` を確認する。 |
| `Could not save order` / `Could not retrieve order` | Blob Storage 操作が失敗した。Azurite が起動しているか、接続設定を確認する。 |
| `Status: Error` | その Activity がエラーとして記録された。対応するログと HTTP 応答を `TraceId` で確認する。 |

`Ctrl+C` で API を止めた際にも、残りのメトリクスなどがまとめて表示されることがあります。Azurite は `make stop` で停止します。

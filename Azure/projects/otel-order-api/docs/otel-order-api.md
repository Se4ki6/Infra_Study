# OpenTelemetry 実装とデプロイ状況

この文書は、注文 API にある OpenTelemetry（OTel）の記述が、どのコードで何を計測し、実行時にどこへ送られるかをまとめたものです。対象は `Azure/projects/otel-order-api` です。

## 現在の進捗

- 注文の作成・取得 API、Azure Blob Storage への永続化、OTel によるログ・トレース・メトリクスの計測は実装済みです。
- ローカルでは Docker Compose の Azurite をストレージとして使えます。
- `APPLICATIONINSIGHTS_CONNECTION_STRING` を設定すれば、Azure Monitor / Application Insights にテレメトリを送る構成です。
- Container Apps 向け Dockerfile と Terraform のホスト基盤は実装済みです。初回 apply は Environment・ACR・Managed Identity・`AcrPull` を作り、`enable_api = true` にする前にイメージを ACR に push します。Azure への apply、イメージの push、Container App の起動、CI/CD は未実施です。

## テレメトリの経路

```text
POST /orders または GET /orders/{id}
  |
  +-- ASP.NET Core の HTTP リクエスト計測
  |
  +-- Application の独自 Activity
  |     +-- orders.create
  |     +-- orders.get
  |
  +-- Application の ILogger
  |
  +-- Application の独自 Meter
  |     +-- orders.requests
  |     +-- order.processing.duration
  |     +-- orders.items
  |
  +-- Azure Blob SDK の依存関係 Activity
  |
  +-- 接続文字列あり: Azure Monitor / Application Insights
      接続文字列なし: Console Exporter（標準出力）
```

## OTel の記述と利用箇所

| 種類 | 定義・設定箇所 | 実際に記録する箇所 | 主な用途 |
| --- | --- | --- | --- |
| 独自トレース | `src/Application/Telemetry.cs` の `ActivitySource` | `CreateOrderHandler`、`GetOrderHandler` | 注文ユースケースを HTTP リクエスト配下の子スパンとして追跡する |
| HTTP トレース | `src/Api/Program.cs` の `AddAspNetCoreInstrumentation()`（ローカル時） | ASP.NET Core が自動記録 | HTTP メソッド、パス、応答結果、処理時間を記録する |
| Blob 依存関係トレース | `Program.cs` の `AddSource("Azure.*")`（ローカル時） | `BlobOrderRepository` が呼ぶ Azure Blob SDK | Blob 作成、アップロード、ダウンロードを依存関係スパンとして確認する |
| ログ | `Program.cs` の `AddOpenTelemetry` / `AddConsoleExporter` | 両ハンドラーの `ILogger` | 作成・取得・入力拒否・ストレージ障害を記録する |
| メトリクス | `Telemetry.cs` の `Meter` | `CreateOrderHandler` | 作成要求数、作成所要時間、商品数を時系列で集計する |
| Azure Monitor 送信 | `Program.cs` の `UseAzureMonitor()` | SDK が収集した全シグナル | Application Insights へ送る |

## 1. 起動時の登録: `src/Api/Program.cs`

### 独自計測器を SDK に購読させる

```csharp
builder.Services.ConfigureOpenTelemetryMeterProvider(meterBuilder =>
    meterBuilder.AddMeter(Telemetry.MeterName));
builder.Services.ConfigureOpenTelemetryTracerProvider(traceBuilder =>
    traceBuilder.AddSource(Telemetry.ActivitySourceName));
```

`Telemetry.cs` が作成する `ActivitySource` と `Meter` の名前を SDK に登録します。この設定がないと、アプリケーション側で `StartActivity` や `Record` を呼んでも exporter には流れません。

### 送信先の分岐

`APPLICATIONINSIGHTS_CONNECTION_STRING` の有無で動作が変わります。

| 条件 | 設定 | 出力先 |
| --- | --- | --- |
| 接続文字列あり | `AddOpenTelemetry().UseAzureMonitor(...)` | Azure Monitor / Application Insights |
| 接続文字列なし | Console Exporter、ASP.NET Core 計測、`Azure.*` 購読 | API プロセスの標準出力 |

ローカル時の `AddAspNetCoreInstrumentation()` は HTTP リクエストの親スパンを作ります。`AddSource("Azure.*")` は Blob SDK が作る依存関係スパンを受け取るための設定です。

## 2. 独自トレース: `src/Application/Orders`

### 注文作成: `CreateOrderHandler.HandleAsync`

`Telemetry.ActivitySource.StartActivity("orders.create")` が作成処理を表すスパンを開始します。HTTP リクエストから実行された場合は HTTP スパンの子になります。

- 入力不正時: `order.result=rejected`、ステータスを Error に設定
- Blob Storage 障害時: `order.result=storage_error`、ステータスを Error に設定
- 成功時: `order.item_count` と `order.result=created` を設定

このスパンの中で `BlobOrderRepository.SaveAsync` を呼ぶため、Blob SDK のスパンが有効なら、HTTP → `orders.create` → Blob 操作の親子関係を追えます。

### 注文取得: `GetOrderHandler.HandleAsync`

`StartActivity("orders.get")` が取得処理のスパンを開始します。`order.id` と、取得結果に応じた `order.result=found` / `not_found` を属性として設定します。Storage 障害時はスパンを Error にし、例外を API 層へ伝播します。

## 3. メトリクス: `src/Application/Telemetry.cs` と `CreateOrderHandler`

| メトリクス名 | 型 | 記録条件 | 属性・単位 |
| --- | --- | --- | --- |
| `orders.requests` | Counter | 作成が成功、入力拒否、Storage 障害 | `result=created` / `rejected` / `storage_error` |
| `order.processing.duration` | Histogram | すべての作成要求（`finally`） | `operation=create`、単位は ms |
| `orders.items` | Histogram | 作成成功時 | 単位は `{item}` |

`result` のように値が限定される属性だけをメトリクスに付与しています。注文 ID や商品 ID は種類が増え続けるため、メトリクスの属性には使わず、ログまたはトレースの属性として扱っています。

## 4. ログ: `CreateOrderHandler` と `GetOrderHandler`

両ハンドラーは `ILogger<T>` を使い、次の出来事を構造化ログとして記録します。

- 入力拒否: Warning
- 注文作成・取得・未検出: Information
- Storage 保存・取得の失敗: Error（例外を含む）

注文 ID は `{OrderId}` として構造化フィールドに入ります。OTel ログが有効な実行では、ログは同じリクエストのトレースと関連付けて調査できます。

## 5. Azure Blob Storage: `src/Infrastructure/BlobOrderRepository.cs`

このクラスは OTel API を直接呼びません。ただし `BlobContainerClient` / `BlobClient` を通して Azure SDK を使うため、SDK が作る Activity が依存関係テレメトリになります。

- `CreateIfNotExistsAsync`、`UploadAsync`: 注文保存時の Blob 操作
- `DownloadContentAsync`: 注文取得時の Blob 操作
- `Azure.RequestFailedException`: Application 層用の `OrderStorageException` に変換

404 は「注文なし」として `null` を返し、障害として扱いません。それ以外の Storage 障害は API 層で HTTP 503 になります。障害時はアプリケーションの Error ログと Error スパンから、その前後の Blob 依存関係を確認できます。

## 実行時の確認方法

1. `docker compose up -d` で Azurite を起動します。
2. 接続文字列を設定せずに API を起動すると、OTel はコンソール出力になります。
3. `POST /orders` を実行し、HTTP スパン、`orders.create`、Blob 操作、作成ログ、3 種のメトリクスを確認します。
4. 数量を `0` にしたリクエストでは、400、Warning ログ、`result=rejected`、Error 状態の `orders.create` を確認します。
5. Azurite を停止してから作成すると、503、Error ログ、`result=storage_error`、Error 状態のスパンを確認できます。

Application Insights で確認する場合は、接続文字列を環境変数に設定して API を起動します。確認用の Kusto クエリを含む手順は [learning-guide.md](learning-guide.md) を参照してください。

## Azure へデプロイする手順

Terraform の設計と手順は[Terraform・監視リソース設計](terraform-otel-design.md)とプロジェクトの [README](../README.md) にあります。初回 apply で監視・Storage と Container Apps の実行基盤を作り、Dockerfile からビルドしたイメージを ACR に push した後、`enable_api = true` で Container App を作成します。接続文字列は Container App secret として渡し、Azure Monitor Distro から Application Insights へテレメトリを送ります。

実リソースの作成、イメージの push、Container App の起動、CI/CD はまだ実施していません。

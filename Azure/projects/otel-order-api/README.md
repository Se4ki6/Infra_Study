# OpenTelemetry注文API

ASP.NET Core Minimal APIで注文を受け付け、Azure Blob StorageへJSONとして保存する学習用サンプルです。Clean Architectureを参考に、Domain・Application・Infrastructure・Apiの4プロジェクトに分けています。ローカルではAzuriteを使い、Application Insightsを設定するとログ・トレース・メトリクスをAzure Monitorへ送ります。

OpenTelemetryの基本と、正常系・エラー系の観察手順は[初学者向けガイド](docs/learning-guide.md)を参照してください。

## プロジェクト構成

```text
src/
├── Domain/          # Orderと注文の不変条件
├── Application/     # 注文作成・取得のユースケース、リポジトリ契約、計測
├── Infrastructure/  # Azure Blob Storageによるリポジトリ実装
└── Api/             # HTTPエンドポイント、DI、OpenTelemetryの出力先設定
```

依存の向きは`Api → Application → Domain`と`Api → Infrastructure → Application/Domain`です。ApplicationはBlob SDKを参照せず、`IOrderRepository`を通じて永続化します。HTTPのステータスコードへの変換はApi、Azure固有例外の変換はInfrastructureが担当します。

## 必要なもの

- .NET 10 SDK
- Docker Compose
- Application Insights（Azure Portalで手動作成。ローカル表示だけ試す場合は不要）

## 起動

1. Azuriteを起動します。

   ```sh
   docker compose up -d
   ```

2. APIを起動します。

   ```sh
   dotnet run --project src/Api/OtelOrderApi.Api.csproj --urls http://localhost:5080
   ```

`APPLICATIONINSIGHTS_CONNECTION_STRING`が未設定の場合、トレース・メトリクス・ログはOpenTelemetryのConsole Exporterからコンソールに出ます。Application Insightsを使う場合は、Portalで取得した接続文字列を環境変数に設定してからAPIを起動します。

```sh
export APPLICATIONINSIGHTS_CONNECTION_STRING='InstrumentationKey=...;IngestionEndpoint=...'
dotnet run --project src/Api/OtelOrderApi.Api.csproj --urls http://localhost:5080
```

Azurite以外のBlob Storage接続文字列を使う場合は`Blob__ConnectionString`、コンテナ名を変える場合は`Blob__ContainerName`を設定します。接続文字列はシェル履歴やGitに残さないようにしてください。

## APIの操作

正常な注文を作成します。

```sh
curl -i http://localhost:5080/orders \
  -H 'Content-Type: application/json' \
  -d '{"productId":"book-001","quantity":2}'
```

レスポンスの`id`を使って取得します。

```sh
curl -i http://localhost:5080/orders/<id>
```

入力エラーを発生させるには数量を0にします。ストレージエラーはAzuriteを停止して注文を作成すると発生し、APIは503を返します。Azurite停止中にAPIプロセスが継続するため、起動後の接続エラーも観察できます。

## 計測ポイント

- **トレース**: ASP.NET CoreのHTTPリクエスト、`orders.create` / `orders.get`の独自Activity、Azure Blob SDKの依存関係。
- **ログ**: 注文の作成、取得、入力拒否、ストレージエラー。注文IDを使って該当処理を追えます。
- **メトリクス**: `orders.requests`（結果別の作成要求数）、`order.processing.duration`（作成処理時間）、`orders.items`（注文の商品数）。

Azure Blob Storage SDKのActivitySourceは`AddSource("Azure.*")`で購読します。このサンプルでは実験機能スイッチを設定していません。Azure SDKの一部の実験的な計測機能（例: Service BusやEvent Hubsのメッセージトレース）を使う場合は、対象SDKの公式資料でスイッチの要否を確認してください。

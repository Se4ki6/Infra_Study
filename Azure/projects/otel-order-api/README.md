# OpenTelemetry注文API

ASP.NET Core Minimal APIで注文を受け付け、Azure Blob StorageへJSONとして保存する学習用サンプルです。Clean Architectureを参考に、Domain・Application・Infrastructure・Apiの4プロジェクトに分けています。ローカルではAzuriteを使い、Application Insightsを設定するとログ・トレース・メトリクスをAzure Monitorへ送ります。

OpenTelemetryの基本と、正常系・エラー系の観察手順は[初学者向けガイド](docs/learning-guide.md)を参照してください。Console Exporterを使う`make api`の出力は[コンソール出力ガイド](docs/console-output-guide.md)を参照してください。AzureリソースのTerraform実装方針とOTelの確認計画は[Terraform・監視リソース設計](docs/terraform-otel-design.md)にまとめています。

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
- Application Insights（Azureへ送信して試す場合に必要。Terraformによる作成方針は[設計書](docs/terraform-otel-design.md)を参照。ローカル表示だけなら不要）

## 起動

プロジェクト直下で次のコマンドを実行すると、AzuriteとAspire Dashboardをコンテナで起動し、APIをホスト上で起動します。接続文字列を設定していない場合、ログ・トレース・メトリクスはDashboardへ送ります。

```sh
make dev
```

Dashboardは[http://localhost:18888](http://localhost:18888)で開けます。ログイン URL は`make dev`の実行結果に表示されます。APIは`Ctrl+C`で停止します。コンテナを停止するときは別途次を実行してください。

```sh
make stop
```

`make stop`は`make dev`または`make api`で起動したAPIと、Azurite・Dashboardのコンテナを停止します。Azuriteの保存データは残りますが、Dashboardのテレメトリはコンテナの再起動で消えます。ビルドする場合は`make build`を使います。APIのポートを変更するには、たとえば`make dev PORT=5081`を実行します。

Swagger UIは[http://localhost:5080/swagger](http://localhost:5080/swagger)で開けます。

`make dev`では`OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`と`OTEL_EXPORTER_OTLP_PROTOCOL=grpc`をAPIへ渡します。DashboardのTraces、Structured logs、Metricsで注文処理を確認してください。メトリクスの表示は送信間隔の分だけ遅れることがあります。

`make api`では、`APPLICATIONINSIGHTS_CONNECTION_STRING`があればAzure Monitor、なければ`OTEL_EXPORTER_OTLP_ENDPOINT`が指定されているとOTLP、どちらもなければConsole Exporterを使用します。Application Insightsを使う場合は、Portalで取得した接続文字列を環境変数に設定してからAPIを起動します。接続文字列はOTLPエンドポイントより優先されます。

```sh
export APPLICATIONINSIGHTS_CONNECTION_STRING='InstrumentationKey=...;IngestionEndpoint=...'
make dev
```

Azurite以外のBlob Storage接続文字列を使う場合は`Blob__ConnectionString`、コンテナ名を変える場合は`Blob__ContainerName`を設定します。接続文字列はシェル履歴やGitに残さないようにしてください。

## APIの操作

API 起動後、[Swagger UI](http://localhost:5080/swagger) からエンドポイントを確認・実行できます。画面が読む OpenAPI 定義はリポジトリ直下の [`openapi.yml`](openapi.yml) で、実行中の API からは `http://localhost:5080/openapi.yml` で取得できます。定義を変更した場合は API を再ビルド・再起動してください。

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

## Azure リソースを Terraform で作成する

`terraform/` は Resource Group、Log Analytics Workspace、ワークスペースベースの Application Insights、Storage Account、非公開の `orders` Blob コンテナーに加え、Container Apps Environment、ACR、Managed Identity と `AcrPull` ロールを管理します。Azure にデプロイせずローカルの Aspire Dashboard と Azurite だけを使う場合、この手順は不要です。リソースの構成とテレメトリ確認計画は[設計書](docs/terraform-otel-design.md)を参照してください。

Terraform と Azure CLI を用意し、対象 subscription を選びます。`az account show` の ID と、以降の `<subscription ID>` が一致することを確認してください。

```sh
az login
az account set --subscription '<対象の subscription ID>'
az account show --query id -o tsv
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan -var='subscription_id=<対象の subscription ID>'
```

`enable_api` は既定で `false` です。最初の apply は API 本体を作らず、Resource Group、Workspace、Application Insights、Storage Account、Blob Container、Consumption の Container Apps Environment、Basic ACR、User Assigned Managed Identity、`AcrPull` ロールを作ります。Plan で対象 subscription とリソースを確認し、Azure リソースの作成とロール割り当てに必要な権限があることを確認してから実行します。

```sh
terraform -chdir=terraform apply -var='subscription_id=<対象の subscription ID>'
```

この段階でローカル API から Azure Blob Storage と Application Insights に接続して検証できます。Storage Account または ACR 名の衝突で作成できない場合は、`-var='name_suffix=<英小文字と数字>'` を `plan` と `apply` の両方に追加して別の名前を計画します。

Terraform を実行した同じシェルで次の環境変数を設定し、`make api` でローカル API を起動します。接続文字列をターミナルへ表示したり、README、tfvars、コマンド履歴、Git 管理下のファイルに貼り付けたりしないでください。

```sh
export APPLICATIONINSIGHTS_CONNECTION_STRING="$(terraform -chdir=terraform output -raw application_insights_connection_string)"
export Blob__ConnectionString="$(terraform -chdir=terraform output -raw blob_connection_string)"
export Blob__ContainerName="$(terraform -chdir=terraform output -raw container_name)"
export OTEL_SERVICE_NAME=otel-order-api
make api
```

Container App を起動するには、プロジェクト直下で一意のイメージタグを決め、Dockerfile からビルドして ACR に push します。ACR への push 権限が必要です。

```sh
IMAGE_TAG="otel-$(date +%Y%m%d%H%M%S)"
REGISTRY_NAME="$(terraform -chdir=terraform output -raw api_container_registry_name)"
REGISTRY_SERVER="$(terraform -chdir=terraform output -raw api_container_registry_login_server)"
az acr login --name "$REGISTRY_NAME"
docker build --tag "$REGISTRY_SERVER/otel-order-api:$IMAGE_TAG" .
docker push "$REGISTRY_SERVER/otel-order-api:$IMAGE_TAG"
terraform -chdir=terraform plan \
  -var='subscription_id=<対象の subscription ID>' \
  -var='enable_api=true' \
  -var="image_tag=$IMAGE_TAG"
terraform -chdir=terraform apply \
  -var='subscription_id=<対象の subscription ID>' \
  -var='enable_api=true' \
  -var="image_tag=$IMAGE_TAG"
```

2 回目の plan で Container App の作成とイメージタグを確認してから apply します。`name_suffix` を設定した場合は、2 回目の plan と apply にも同じ値を追加します。起動後、公開 FQDN とヘルス確認先を取得できます。

```sh
API_FQDN="$(terraform -chdir=terraform output -raw api_fqdn)"
curl "https://$API_FQDN/health"
```

Container App は Consumption で最小 0、最大 1 レプリカです。0 台から起動すると初回リクエストに時間がかかる場合があります。Environment、ACR、Log Analytics、Storage などには料金が発生する場合があります。演習後に削除する場合も、対象 subscription と削除内容を plan で確認してから `terraform destroy` を実行してください。

Terraform state には接続文字列や Storage Account キーが含まれます。`terraform/.gitignore` で除外しているローカル state を公開せず、`terraform output -json` の結果も共有しないでください。

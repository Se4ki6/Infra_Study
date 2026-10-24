# Azure Event Grid

Azure が提供するイベントルーティングサービス。「何かが起きた」という軽量な通知(イベント)を、発行元(パブリッシャー)から購読者(サブスクライバー)へ低遅延・高スケールで配送する。

参考:
- [What is Azure Event Grid?](https://learn.microsoft.com/azure/event-grid/overview)
- [Azure Event Grid's push delivery - concepts](https://learn.microsoft.com/azure/event-grid/concepts)
- [Azure Event Grid use cases](https://learn.microsoft.com/azure/event-grid/use-cases)
- [Choose between Azure Event Grid, Event Hubs, and Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services)

## 概要

Event Grid はフルマネージドの Pub/Sub 型イベント配信サービス。MQTT と HTTP の2プロトコルに対応し、以下の2つを中核機能として持つ。

- **MQTTメッセージング**: IoTデバイスやアプリケーション同士が MQTT v3.1.1 / v5.0 で通信する。Azureサービスやカスタムエンドポイントへのルーティングも可能。
- **Push/Pull配信によるデータ配信**: Azureサービス・自作アプリ・パートナーSaaSが発行するイベントを、HTTP経由でPush配信(Event Gridから送る)またはPull配信(購読側が取りに行く)で消費する。

イベントの標準フォーマットとして [CloudEvents 1.0](https://github.com/cloudevents/spec) をサポートし、システム間の相互運用性を確保している(最大イベントサイズ1MB、64KB超は64KB単位で課金)。

## 中核概念

| 用語 | 説明 |
| --- | --- |
| イベント(Event) | システムで起きたことを表す最小単位の情報。`source`・`time`・一意なIDなどの共通情報と、種類固有の情報を持つ |
| パブリッシャー(Publisher) | Event Gridにイベントを送信するアプリケーション。Azureサービス・自作アプリ・パートナーSaaSなど |
| イベントソース(Event source) | イベントが実際に発生した場所(例: Blob作成イベントに対するAzure Storage) |
| トピック(Topic) | 発行したイベントを保持するリソース。カスタムトピック/システムトピック/パートナートピックの3種 |
| イベントサブスクリプション | どのトピックのどのイベントを、どのハンドラーへ配送するかを定義する設定リソース。イベントタイプやsubjectでフィルタ可能 |
| イベントハンドラー | Push配信でイベントの送信先となるサービス(Webhook、Azure Functions、Event Hubsなど) |
| パートナー(Partner) | Auth0、Microsoft Graph(Entra ID/Outlook/Teams等)のように、外部SaaSからイベントを提供する仕組み(Partner Events) |

トピックの種類は用途で使い分ける。

- **カスタムトピック**: 自作アプリ用にPush配信専用のエンドポイントを持つ
- **システムトピック**: Azure Storage、Event Hubs、Service Busなど、Azureサービスが標準で提供する組み込みトピック
- **パートナートピック**: Partner Events経由で外部SaaSのイベントを受け取るためのトピック

## Push配信 vs Pull配信

| 観点 | Push配信 | Pull配信 |
| --- | --- | --- |
| 動作 | イベントサブスクリプションで指定した宛先へEvent Gridが能動的に送信 | 購読側アプリがEvent Gridに接続してイベントを取得しに行く |
| 対応トピック | カスタム/システム/パートナー/ドメイン | namespaceトピックのみ |
| 信頼性 | 24時間の指数バックオフによる再送 | 購読側が読み取り完了までイベントの処理を完全に制御できる |
| Private Link | 非対応 | 対応(受信側が仮想ネットワーク内からプライベート接続可能) |
| 向くケース | 状態変化を都度受け取りたい、アウトバウンド呼び出しができないアプリにHTTPエンドポイント経由で届けたい | 受信タイミングを自分で制御したい、ダウンストリームの障害時にイベントを未処理のままブローカーへ戻したい、エンドポイントを公開できない |

## 他のAzureメッセージングサービスとの比較

Event Grid・Event Hubs・Service Bus は目的が異なり、しばしば組み合わせて使う([S3_OIDC_AzureFunction](../../Cross-Cloud/S3_OIDC_AzureFunction)のようなイベント駆動アーキテクチャでも同様の使い分けの発想が有効)。

| 観点 | Event Grid | Event Hubs | Service Bus |
| --- | --- | --- | --- |
| 主目的 | リアクティブなイベントルーティング | ビッグデータ規模のストリーミング取り込み | エンタープライズ向けトランザクショナルメッセージング |
| データモデル | イベント(離散的な通知) | イベントストリーム(時系列) | メッセージ(高価値なペイロード) |
| 順序保証 | なし | パーティション単位であり | FIFO(セッション使用時) |
| トランザクション | なし | なし | あり |
| 重複検出 | なし | なし | あり |
| デッドレター | あり | なし | あり |
| キャプチャ/リプレイ | なし | あり(Event Hubs Capture) | なし |

詳細は [storage-queue-vs-service-bus-queue.md](storage-queue-vs-service-bus-queue.md) も参照(Service Bus Queue自体の詳細比較)。

## 実際のユースケース例

### 向いている例

- **サーバーレスなイベント駆動アーキテクチャ**: Blobアップロード → Event Grid → Azure Functionsでサムネイル生成、のようにAzureサービス(20以上のサービスがシステムトピックとして対応)からのイベントをトリガーに処理を起動する。
- **マイクロサービス間の疎結合な統合**: 自作アプリがカスタムトピック/Namespaceトピックへイベントを発行し、複数の購読者(Webhook、Logic Apps、Functionsなど)がフィルタ条件に応じて必要なイベントだけを受け取る。
- **パートナーSaaSイベントの取り込み**: Auth0のログインイベントやMicrosoft Graph(Entra ID/Outlook/Teams)の変更通知をPartner Events経由で受け取り、社内ワークフローを自動化する。
- **IoTのテレメトリ収集・制御(MQTT)**: 多数のデバイスからのテレメトリを many-to-one で集約する、逆にクラウドから特定デバイスへコマンドを送る(request-response)、複数デバイスへ一括でアラートを配信する(one-to-many)といったパターン。
- **プライベートネットワーク経由でのイベント消費**: Pull配信+Private Linkで、仮想ネットワーク内からEvent Gridへの発行/受信をパブリックエンドポイントを晒さずに行いたい場合。
- **受信ペースを自分で制御したい処理**: アプリが常時稼働していない、あるいは下流の障害時にイベントを未処理のまま戻したいなど、消費タイミングを購読側が握りたい場合(Pull配信)。

### 向いていない例

- **大量の時系列データを高スループットで取り込みたい処理**(IoTテレメトリのストリーム分析基盤そのもの、アプリログの集約など): Event Gridは離散イベントの通知に向いており、秒間数百万件規模の連続ストリームの取り込み・順序付き保持は Event Hubs の領域。
- **注文処理や決済のようにトランザクション・重複排除・厳密なFIFOが必須の業務処理**: Event Gridにはトランザクションや重複検出機能がなく、順序保証もないため、この用途は Service Bus が適する。
- **メッセージの内容そのものが処理対象のペイロードであるケース**(データを消費してファイルを生成し応答を返す、といった「メッセージ」の契約が必要な場合): Event Gridの「イベント」は状態変化の軽量な通知が前提であり、送信側は受信側の処理内容を期待しない設計。ペイロード中心の処理は Service Bus や Event Hubs のメッセージモデルの方が自然。

## まとめ

Event Grid は「何かが起きた」という軽量な通知を、Push/Pull・MQTT/HTTPの柔軟な配信モデルで多数の購読者に届けることに特化したサービス。Azureサービス間の疎結合なイベント駆動連携やIoTのMQTT通信に強みがあり、大量ストリームの取り込みが必要なら Event Hubs、トランザクション性の高いメッセージングが必要なら Service Bus と使い分ける(あるいは組み合わせる)のが公式ドキュメントの推奨スタンス。

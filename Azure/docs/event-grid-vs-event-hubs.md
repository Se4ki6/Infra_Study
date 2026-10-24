# Azure Event Grid vs Azure Event Hubs (Service Busとの比較含む)

Azureには「メッセージ/イベント」を配信する仕組みとして、[Storage Queue / Service Bus Queue](./storage-queue-vs-service-bus-queue.md) に加えて **Event Grid** と **Event Hubs** がある。この4つはよく混同されるが、それぞれ「反応的なイベントルーティング」「大量データのストリーミング取り込み」「エンタープライズ向けトランザクショナルメッセージング」という異なるシナリオを狙って設計されている。

参考:
- [Choose between Azure Event Grid, Event Hubs, and Service Bus (Microsoft Learn)](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services)
- [What is Azure Event Grid? (Microsoft Learn)](https://learn.microsoft.com/azure/event-grid/overview)
- [What is Azure Event Hubs? (Microsoft Learn)](https://learn.microsoft.com/azure/event-hubs/event-hubs-about)
- [Choose the right Event Grid tier for your solution (Microsoft Learn)](https://learn.microsoft.com/azure/event-grid/choose-right-tier)
- [Compare Azure Event Hubs tiers (Microsoft Learn)](https://learn.microsoft.com/azure/event-hubs/compare-tiers)
- [Azure Service Bus premium messaging tier (Microsoft Learn)](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-premium-messaging)

## 概要

- **Event Grid**: 高スケーラブルなフルマネージドの **Pub/Sub イベント配信サービス**。MQTT(IoTデバイス向け)とHTTP(システム状態変化の通知)の2系統をサポートし、CloudEvents 1.0仕様に準拠。「何かが起きた」という軽量な通知(Event)をルーティングするのが目的で、通知内容自体をデータパイプラインとして永続化する用途ではない。
- **Event Hubs**: フルマネージドの **リアルタイムデータストリーミング/取り込みプラットフォーム**。秒間数百万イベント規模の高スループット・低遅延な取り込みを実現し、Apache Kafkaプロトコルとの互換性を持つ。IoTテレメトリ、アプリケーションログ、クリックストリーム分析など「時系列順のイベント列(ストリーム)」を扱う用途。
- **Service Bus(再掲)**: エンタープライズ向けのトランザクショナルメッセージング。順序保証・重複検出・トランザクションなど「メッセージ1件1件の価値・整合性」を重視する用途(詳細は[Storage Queue vs Service Bus Queueの比較](./storage-queue-vs-service-bus-queue.md)を参照)。

## サービス選定の起点(公式ガイド)

| 比較項目 | Event Grid | Event Hubs | Service Bus |
| --- | --- | --- | --- |
| 主目的 | 反応的なイベントルーティング | ビッグデータのストリーミング取り込み | エンタープライズ トランザクショナルメッセージング |
| データモデル | イベント(単発の軽量通知) | イベントストリーム(時系列順の連続データ) | メッセージ(高価値なペイロード) |
| 配信保証 | At Least Once | At Least Once | At Least Once(オプションで順序保証、セッション利用でExactly Once相当) |
| 使いどころ | 状態変化への反応、サーバーレスアーキテクチャ | テレメトリ、分散データストリーミング、リアルタイム分析 | 注文処理、金融取引、ワークフロー |

### Event/Message の違い(公式定義)

- **Event(イベント)**: 状態変化の軽量な通知。発行者は受信者がどう処理するか関知しない。単発の「アクション可能な状態変化」の場合もあれば、時系列で分析可能な連続データの一部の場合もある。
- **Message(メッセージ)**: 別のどこかで消費・保存されるべき「生データそのもの」。発行者と受信者の間に契約(コントラクト)が存在する(例: 発行者が生データを送り、受信者はそれを元にファイルを生成して完了応答を返す、という取り決め)。

## スケーラビリティ・スループット比較

| 比較項目 | Event Grid | Event Hubs | Service Bus |
| --- | --- | --- | --- |
| スループット | 動的にスケール(サーバーレス) | 秒間数百万イベント | 信頼性重視の非同期配信 |
| レイテンシモデル | ニアリアルタイム配信 | 低遅延ストリーミング | ブローカー経由(オプションでロングポーリング) |
| スケーリング単位 | 自動(サーバーレス) | スループットユニット/処理ユニット(TU/PU/CU) | メッセージングユニット(Premium) |

## メッセージング機能比較

| 比較項目 | Event Grid | Event Hubs | Service Bus |
| --- | --- | --- | --- |
| プロトコル | MQTT, HTTP | AMQP, Kafka, HTTP | AMQP, HTTP |
| Pub/Sub | できる(Publish-Subscribe) | できる(コンシューマーグループ) | できる(Topics & Subscriptions) |
| 順序保証 | **できない** | パーティション単位でできる | できる(FIFO、セッション利用時) |
| トランザクション | **できない** | **できない** | できる |
| 重複検出 | **できない** | **できない** | できる |
| デッドレター | できる | **できない** | できる |
| バッチ処理 | できる | できる(イベントバッチ) | できる(セッション経由) |
| キャプチャ/リプレイ(データの再生・長期保存) | **できない** | できる(Event Hubs Capture機能でBlob/Data Lakeへ自動保存) | **できない** |

## 統合・デプロイの比較

| 比較項目 | Event Grid | Event Hubs | Service Bus |
| --- | --- | --- | --- |
| Azureサービス統合 | Azureサービス・サードパーティサービスと深く統合 | ストリーム処理基盤・分析サービスとの統合が中心 | エンタープライズアプリ、ハイブリッドクラウド、オンプレミス接続 |
| 提供形態(エディション) | Event Grid(PaaS)、Azure Arc上のKubernetes版 | Standard, Premium, Dedicated | Basic, Standard, Premium |

## Event Gridの詳細

### コア機能

1. **MQTTメッシージング**: IoTデバイス・アプリケーション間をMQTT(v3.1.1/v5.0)で通信させ、Azureサービスやカスタムエンドポイントへルーティングできる。Publish-Subscribeモデルで、One-to-Many/Many-to-One/One-to-Oneの通信パターンに対応。
2. **Push/Pull配信(HTTP)**: Push配信ではEvent Grid側からWebhookやAzureサービスへイベントを送信。Pull配信では受信側が任意のタイミングでEvent Gridに接続してイベントを取得できる(namespaceのtopicのみ対応)。

### Push配信 vs Pull配信の使い分け

- **Pull配信が向く場合**: 受信タイミングを完全に制御したい、ダウンストリームに問題がある時にイベントを「読み戻す」制御をしたい、Private Linkを使いたい(Pull配信のみ対応)、エンドポイントを公開できない場合。
- **Push配信が向く場合**: 常時ポーリングを避けたい、アウトバウンド呼び出しができない環境(データ流出を懸念する組織など)でパブリックエンドポイント経由で受信したい場合。

### ティア(Basic / Standard)

| 機能 | Standard(namespace) | Basic(従来のtopic/domain) |
| --- | --- | --- |
| スループット | 高(Ingress最大40MB/s, Egress最大80MB/s) | 低(Ingress/Egressとも最大5MB/s) |
| MQTT v5 / v3.1.1 | できる | **できない** |
| Pull配信 | できる | **できない** |
| カスタムイベントのPublish/Subscribe | できる | できる |
| Webhookへのpush配信 | できる | できる |
| Event Hubsへのpush配信 | できる | できる |
| Azureサービス(Functions, Service Bus queue/topic, Storage Queue等)へのpush配信 | **できない** | できる |
| 最大メッセージ保持期間 | 7日(namespace topic) | 1日 |
| Azureシステムイベントの購読 | **できない** | できる |
| パートナーイベントの購読 | **できない** | できる |
| ドメインスコープのサブスクリプション | **できない** | できる |
| 自動スケール(TU自動調整) | できる | **できない** |

## Event Hubsの詳細

### キー概念

- **Namespace**: 1つ以上のEvent Hubを束ねる管理コンテナ。スループット容量・ネットワークセキュリティ・Geo-DRをNamespace単位で管理。
- **Event Hub / Kafka Topic**: イベントを蓄積する追記専用の分散ログ。並列処理のために複数のPartitionを持つ。
- **Partition**: スループットをスケールするための順序付きイベント列(「高速道路のレーン」のイメージ)。
- **Consumer Group**: 同じイベントストリームを複数のコンシューマーアプリが独立して(それぞれ自分のオフセットを保持して)読める論理ビュー。

### 主要機能

- **Kafka互換**: Apache Kafka, AMQP 1.0, HTTPSのマルチプロトコル対応。既存のKafkaワークロードをコード変更なしでEvent Hubsに移行できる。
- **Capture**: リアルタイムのストリームをBlob StorageやData Lake Storageへ自動的にニアリアルタイムでコピーし、長期保存・バッチ分析に利用できる。
- **Schema Registry**: Producer/Consumer間でのスキーマ互換性・一貫性を管理(Avro/JSON対応)。
- **大容量メッセージ(プレビュー)**: 通常は1MB未満想定だが、Dedicatedクラスタでは最大20MBまで対応。

### ティア比較(Quota抜粋)

| 項目 | Basic | Standard | Premium | Dedicated |
| --- | --- | --- | --- | --- |
| スケール単位 | 最大40 TU | 最大40 TU | 最大16 PU | 最大10 CU(サポート申請でさらに拡張可) |
| Event Hubあたりのパーティション数 | 32 | 32 | PUあたり100(namespace全体でPU×200が上限) | Event Hubあたり1,024、CUあたり2,000 |
| Namespaceあたりのイベントハブ数 | 10 | 10 | PUあたり100 | 1,000 |
| 最大メッセージサイズ | 256 KB | 1 MB | 1 MB | 20 MB |
| データ保持期間の上限 | 1日 | 7日 | 90日 | 90日 |
| Capture機能 | 利用不可 | 時間課金で利用可 | 込み | 込み |
| Consumer Group数/Event Hub | 1 | 20 | 100 | 1,000(CUあたり無制限) |

## コスト比較

> 為替・料金は変動するため、正確な金額は必ず [Azure料金計算ツール](https://azure.microsoft.com/pricing/calculator/)や各サービスの公式料金ページ(下記リンク)で最新値を確認すること。ここでは**何に対して課金されるか(課金ディメンション)**の構造的な違いをまとめる。

| サービス/ティア | 課金の基本単位 | 特徴 |
| --- | --- | --- |
| **Event Grid Basic**(topic/domain) | 操作(operation)数課金。Ingress、配信試行(delivery attempt)、Advanced Match、管理呼び出し等を「100万操作あたり」で課金 | 無料枠あり。使った分だけの従量課金なので、イベント数が少ない/不定期なワークロードでは非常に安価。リトライ設定次第で配信試行課金が増えるため、[配信・リトライ設定の最適化](https://learn.microsoft.com/azure/event-grid/delivery-and-retry)がコストに直結する |
| **Event Grid Standard**(namespace) | スループットユニット(TU)ベース + 操作課金の組み合わせ。MQTT・Pull配信など高スループット機能を使う分コストが上がりうる | 自動スケール(TU自動調整)によりピーク対応と無駄なプロビジョニングの回避を両立できる |
| **Event Hubs Basic/Standard** | スループットユニット(TU)の時間課金(Ingress/Egressのレートで消費) + Capture利用時は時間課金 | 低ボリューム〜中ボリュームな取り込みに向く。TUを増減してコスト調整可能(Auto-inflate) |
| **Event Hubs Premium/Dedicated** | 処理ユニット(PU)/キャパシティユニット(CU)の固定容量課金(操作数に依存しない) | 高スループットが常時発生するワークロードでは、従量課金より単価が予測しやすく、大量処理時は割安になりやすい。Dedicatedは物理的に専有クラスタなので最も高コストだが、他テナントの影響を受けない |
| **Service Bus Basic** | 操作(operation)数課金。Queueのみ対応 | シンプルな用途で最安。Topics/Sessions/Transactions等の高度機能は使えない |
| **Service Bus Standard** | 共有キャパシティ上での操作数課金(+ 月額ベース料金) | Topics/Subscriptions、Sessions、Transactions、重複検出などが使えるようになった分、Basicより単価は高い |
| **Service Bus Premium** | メッセージングユニット(MU)の固定容量課金(操作数に依存しない、単一価格) | 専有リソースで性能が安定(予測可能なスループット・レイテンシ)。大容量メッセージ(最大100MB)、VNet統合、Geo-Replication、JMS 2.0が必要な場合はPremium一択。CPU/メモリ使用量自体は追加課金対象外 |

**コスト最適化の勘所(公式ドキュメントより)**:

- Event Grid: イベントフィルタリングを購読側で設定し、不要なイベント処理コストを削減する。出力バッチング(output batching)で1回の配信操作に複数イベントをまとめ、操作あたりのコストを下げる。
- Event Hubs/Service Bus: 常時高負荷なら固定容量課金(Premium/Dedicated/PU-CU)、負荷が波打つ/低頻度なら従量課金(Basic/Standard)が有利、というのが基本方針。TU/PUの利用率を監視して過剰プロビジョニングを避ける。

参考(公式料金ページ、金額の一次情報):
- [Event Grid の価格](https://azure.microsoft.com/pricing/details/event-grid/)
- [Event Hubs の価格](https://azure.microsoft.com/pricing/details/event-hubs/)
- [Service Bus の価格](https://azure.microsoft.com/pricing/details/service-bus/)

## 実際のユースケース例

### Event Grid

**向いている例**

- **サーバーレスアーキテクチャでのリアクティブ処理**: Blobがアップロードされたら自動でAzure Functionsを起動してサムネイル生成、のような「状態変化に反応する」設計。
- **IoTデバイスからのMQTTメッセージ収集**: 自動車・製造業などで大量のMQTTクライアント(センサー等)からのデータをEvent Grid namespace経由で収集し、Event Hubsへルーティングして後段分析につなげる。
- **SaaSパートナー連携イベントの受信**: パートナーのSaaSシステムが発行するイベント(Partner Events)を購読してワークフローをトリガーする。
- **Azureリソースの状態変化通知**: リソースの作成・削除などのシステムイベントをトリガーに、運用自動化(タグ付け、通知、コンプライアンスチェック)を行う。

**向いていない例**

- **時系列データの分析・長期保存が必要な処理**: Event Gridはキャプチャやリプレイをサポートしないため、テレメトリの蓄積・分析にはEvent Hubsの方が適する。
- **メッセージの厳密な処理順序・重複排除が必要な処理**: 順序保証・重複検出がないため、注文処理や決済にはService Busが適する。
- **1件ごとのメッセージにトランザクション整合性が必要な処理**: トランザクション機能がないため不向き。

### Event Hubs

**向いている例**

- **IoTテレメトリの大量取り込み**: 数百万台のセンサー・車両・産業機器からのデータを秒間数百万イベント規模で取り込む。
- **アプリケーションログの集約**: 分散システムの各コンポーネントからログを一箇所に集約し、監視・トラブルシューティングに使う。
- **クリックストリーム分析**: Webやモバイルアプリのユーザー行動データをリアルタイムに近い形で分析。
- **金融取引・不正検知**: 高ボリュームなトレーディングデータや不正検知シグナルの処理。
- **既存Kafkaワークロードの移行**: 自前運用のKafkaクラスタをEvent Hubs(Kafka互換エンドポイント)に置き換え、運用負荷を削減する。
- **Stream Analytics/Data Explorerと連携したリアルタイムダッシュボード**: ノーコードのストリーム処理・可視化と組み合わせる。

**向いていない例**

- **注文処理や決済のようなトランザクション性・重複排除が必須の処理**: トランザクション・重複検出がないため、Service Bus Queueの方が適する。
- **低頻度・単発のイベント通知**: 常時ストリームを流すことを前提とした料金・アーキテクチャのため、たまにしか発生しないイベント通知にはEvent Gridの方がシンプルで安価。
- **サーバーレスの「状態変化への即時反応」が主目的の処理**: Push型のイベントルーティングが主目的ならEvent Gridの方が構築が単純。

## 3サービスを組み合わせる設計

公式ドキュメントでも述べられている通り、これら3サービスは排他的ではなく**役割分担して併用する**のが一般的なパターン。

- 例: ECサイトで「注文処理はService Bus」「サイトのテレメトリ収集はEvent Hubs」「商品発送などの状態変化への反応はEvent Grid」のように、それぞれ得意な役割を担わせる。
- 例: Event GridでEvent Hubsの取り込み状況を監視し、閾値超過などのイベントをトリガーに別処理を起動する、といったパイプライン的な連携も可能。

## まとめ

| 観点 | 有利なサービス |
| --- | --- |
| 状態変化への軽量な反応(サーバーレス) | Event Grid |
| 大量データのリアルタイムストリーミング取り込み | Event Hubs |
| 厳密な順序保証・トランザクション・重複排除が必要なメッセージング | Service Bus |
| IoTデバイスとのMQTT双方向通信 | Event Grid |
| Kafka互換・既存Kafka資産の移行 | Event Hubs |
| 低頻度・従量課金でとにかく安く済ませたい単純通知 | Event Grid(Basic) |
| 常時高負荷なストリーミングで単価を抑えたい | Event Hubs(Premium/Dedicated) |
| データの長期保存・後からの再生(リプレイ) | Event Hubs(Capture) |

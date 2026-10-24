# Azure Event Hubs

秒間数百万件規模のイベントを低遅延で取り込めるフルマネージドのリアルタイムデータストリーミングプラットフォーム。Apache Kafkaとのプロトコル互換を標準で持つ。

参考:
- [What is Azure Event Hubs?](https://learn.microsoft.com/azure/event-hubs/event-hubs-about)
- [Event Hubs features and terminology](https://learn.microsoft.com/azure/event-hubs/event-hubs-features)
- [Choose between Azure Event Grid, Event Hubs, and Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services)

## 概要

| 項目 | 内容 |
| --- | --- |
| サービス種別 | フルマネージドのイベントストリーミングプラットフォーム(PaaS) |
| 対応プロトコル | Apache Kafka, AMQP 1.0, HTTPS |
| データ保持期間 | 最大7日(Standard)、最大90日(Premium/Dedicated) |
| 価格帯 | Standard, Premium, Dedicated |
| SLA | 最大99.99% |

クラスタ管理不要でKafkaワークロードをそのまま(コード変更なしで)実行できる点が特徴。IoTテレメトリ、アプリケーションログ、クリックストリーム分析、金融取引処理など、大量イベントを継続的に取り込む用途向けに設計されている。

## アーキテクチャと中核概念

| 概念 | 説明 |
| --- | --- |
| Namespace | 1つ以上のEvent Hubをまとめる管理コンテナ。スケーリング・ネットワークセキュリティ・geo-DRを名前空間単位で扱う |
| Event hub(= Kafkaのtopicに相当) | イベントを保持するappend-onlyの分散ログ |
| Partition | Event hub内の順序付きイベント列。並列処理のためのスケール単位(高速道路のレーンに例えられる) |
| Producer/Publisher | Event hubへイベントを送信するアプリケーション |
| Consumer | パーティション内の位置(offset)を追跡しながらイベントを読み取るアプリケーション |
| Consumer group | 同じイベントストリームを独立した視点で読む論理グループ。用途ごと(分析用、アーカイブ用、アラート用など)に分けるのが定石 |
| Offset | パーティション内でのイベントの位置(カーソル) |
| Checkpointing | Consumerが現在のoffsetを保存すること。再開・フェイルオーバー・リプレイの基盤になる |

### イベントの流れ

1. **Ingest**: ProducerがEvent hubへイベントを送信。パーティションキー指定時はハッシュで、未指定時はラウンドロビンでパーティションへ振り分けられる。
2. **Store**: 階層(1〜90日)に応じた保持期間でイベントを保存。長期保存が必要な場合は Capture 機能でBlob/Data Lakeへ書き出す。
3. **Process**: ConsumerがConsumer group経由でパーティションを読み取り、checkpointingで進捗を管理する。

### パーティション設計の勘所

- パーティション数はEvent hub作成時に指定し、Standard/Basicでは後から変更不可(Premium/Dedicatedは増加のみ可能、減少は不可)。
- **パーティション数 = そのConsumer group内で並列に動作できるConsumerの上限**。AMQPのepoch(排他)コンシューマーでもKafkaのgroup coordinationでも、1パーティションにつき同時に有効なオーナーは1つ。
- 課金はパーティション数ではなくスループット/処理/容量ユニット(TU/PU/CU)に基づくため、パーティション数だけを増やしてもコストは変わらない。
- 目安スループット: Standardで1パーティションあたり~1MB/s(ingress)・~2MB/s(egress)、Premium/Dedicatedで~1-2MB/s(ingress)・~2-5MB/s(egress)。期待するingress/egressをこの値で割って必要パーティション数を見積もる。
- 順序保証が必要なイベント群は同じパーティションキーを使い、同一パーティションに集約する(ただし特定パーティションへの偏りは可用性を「パーティション単位」に引き下げる点に注意)。

## プロトコル対応

| プロトコル | 送信 | 受信 | 向くケース |
| --- | --- | --- | --- |
| AMQP 1.0 | ○ | ○ | 高スループット・低レイテンシ・永続接続が必要な場合。Azure SDKが使用 |
| Apache Kafka | ○ | ○ | 既存Kafkaアプリケーションをそのまま移行したい場合(バージョン1.0+) |
| HTTPS | ○ | × | ファイアウォール制限のある環境からの、低頻度・軽量な送信専用クライアント |

## データ管理機能

- **Capture**: ストリーミングデータをほぼリアルタイムでAzure Blob Storage / Data Lake Storageへ自動保存し、長期保存やバッチ分析に使う。リアルタイム処理と同じストリーム上で自動的に動作する。
- **Log compaction**: 時間ベースの保持ではなく、キーごとに最新のイベントだけを保持する。フルの履歴ではなく最新状態の維持に有効。
- **Schema Registry**: Avro/JSONスキーマを一元管理し、ProducerとConsumer間のデータ互換性・スキーマ進化を保証する。

## 可用性・セキュリティ

- **可用性**: Premium/DedicatedではAvailability Zone対応、Geo-DRによるセカンダリリージョンへのフェイルオーバーが可能。SLAは構成に応じて最大99.99%。
- **認証**: Microsoft Entra ID(RBAC。Data Owner/Sender/Receiverロール)、Shared Access Signatures(SAS)、マネージドID。
- **ネットワーク**: Private Link、VNetサービスエンドポイント、IPファイアウォールルール。
- **暗号化**: 保存時はMicrosoft管理鍵またはカスタマー管理鍵、転送時はTLS 1.2。

## 他のAzureメッセージングサービスとの比較

| 観点 | Event Hubs | Event Grid | Service Bus |
| --- | --- | --- | --- |
| 主目的 | ビッグデータ規模のストリーミング取り込み | リアクティブなイベントルーティング | エンタープライズ向けトランザクショナルメッセージング |
| データモデル | イベントストリーム(時系列) | イベント(離散的な通知) | メッセージ(高価値なペイロード) |
| メッセージパターン | 多数のProducer、複数Consumerによる時系列イベント | フィルタ付きのPushベースルーティング | Point-to-point/Pub-SubでFIFOやトランザクションなどの配信保証付き |
| 順序保証 | パーティション単位であり | なし | FIFO(セッション使用時) |
| トランザクション/重複検出 | なし | なし | あり |
| キャプチャ/リプレイ | あり(Event Hubs Capture) | なし | なし |

詳細な観点別の比較は [Choose between Azure Event Grid, Event Hubs, and Service Bus](https://learn.microsoft.com/azure/service-bus-messaging/compare-messaging-services) を参照。Storage QueueとService Bus Queueの詳細比較は [storage-queue-vs-service-bus-queue.md](storage-queue-vs-service-bus-queue.md)、Event Gridの詳細は [event-grid.md](event-grid.md) を参照。

## 実際のユースケース例

### 向いている例

- **IoTテレメトリの取り込み**: 数百万台規模のセンサー・車両・産業機器から連続的に送られてくるデータを、パーティションで並列に取り込む。Event Gridの「デバイスからのMQTT通知」よりも、連続ストリームの大量取り込みそのものが目的の場合はこちら。
- **アプリケーションログの集約**: 分散システム全体のログを一箇所に集めて監視・トラブルシューティングに使う。Consumer groupを分析用/アーカイブ用などに分けて同じストリームを多重利用できる。
- **クリックストリーム分析**: Web/モバイルのユーザー行動イベントをStream AnalyticsやData Explorerと連携させ、ほぼリアルタイムでダッシュボード化する。
- **金融取引・不正検知**: 高頻度の取引データや不正検知シグナルを低遅延で処理し続ける必要がある場合。
- **イベントソーシング**: 状態変更を時系列の順序付きログとして永続化し、後からリプレイして状態を再構築するアーキテクチャ。
- **既存Kafkaワークロードのマネージド移行**: クラスタ運用をやめてEvent Hubs for Apache Kafkaへブローカーのエンドポイントだけ差し替えて移行したい場合。

### 向いていない例

- **注文処理や決済のようにトランザクション・厳密な重複排除が必要な処理**: Event Hubsにはトランザクションや重複検出機能がなく、Service Busの方が適する。
- **状態変化を都度リアクティブに他サービスへ配信・ルーティングしたいだけの処理**: 大量ストリームの取り込みではなく単発の通知が目的なら、フィルタ付きPushルーティングを持つEvent Gridの方がシンプル。
- **長期保存が前提のデータストアとしての利用**: Event Hubsは「リアルタイムストリーミングエンジン」であり、データベースではない。保持期間(最大90日)を超えるデータはCaptureでBlob/Data Lake等へ書き出す必要がある。
- **1メッセージが数十MBを超える巨大ペイロードを継続的に扱う処理**: 標準は1MB/publish操作、Dedicatedクラスタでも(プレビューの大容量メッセージ機能を使っても)20MBが上限。大容量データはBlob等に置いてURLだけをイベントに載せる設計が必要。

## まとめ

Event Hubs は「大量の時系列イベントを低遅延で取り込み、複数のConsumerが独立して読み進める」ことに特化したストリーミング基盤。Kafka互換によって既存資産を活かしやすく、IoT/ログ/クリックストリーム/金融データのような継続的な高スループット取り込みに強みがある。単発の状態変化通知には Event Grid、トランザクション性の高い業務メッセージングには Service Bus を使うのが公式ドキュメントの推奨スタンスであり、実際には3サービスを役割分担させて組み合わせるケースも多い。

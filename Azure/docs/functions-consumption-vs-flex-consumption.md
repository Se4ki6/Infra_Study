# Azure Functions: Consumption plan vs Flex Consumption plan

Azure Functionsのサーバーレス（従量課金）ホスティングには、従来の **Consumption plan（Y1）** と、新しい **Flex Consumption plan（FC1）** がある。[resource-cleanup-checker](../projects/resource-cleanup-checker/)プロジェクトでどちらを使うか検討した際の比較メモ。

参考:
- [Azure Functions hosting options (Microsoft Learn)](https://learn.microsoft.com/azure/azure-functions/functions-scale)
- [Azure Functions Flex Consumption plan hosting (Microsoft Learn)](https://learn.microsoft.com/azure/azure-functions/flex-consumption-plan)
- [Azure Functions Consumption plan hosting (legacy) (Microsoft Learn)](https://learn.microsoft.com/azure/azure-functions/consumption-plan)
- [Estimating consumption-based costs (Microsoft Learn)](https://learn.microsoft.com/azure/azure-functions/functions-consumption-costs)
- [Azure Functions pricing](https://azure.microsoft.com/pricing/details/functions/)

## 概要

- **Consumption plan（Y1）**: 実行時間・実行回数に応じた従量課金で、アイドル時は0インスタンスまでスケールインする、Azure Functions最初期からのサーバーレスプラン。**現在は"legacy"扱い**で、新機能・新しい言語バージョンの追加は行われない。
- **Flex Consumption plan（FC1）**: Consumption plan後継として設計された新しいサーバーレスプラン。従量課金を維持しつつ、インスタンスメモリサイズの選択・VNet統合・Always Ready インスタンス（コールドスタート対策）・per-functionスケーリングなど、Premium plan寄りの柔軟性を取り込んでいる。Microsoftは**新規のサーバーレスFunction AppにはFlex Consumptionを使うことを推奨**している。

## ステータス・廃止予定

| 項目 | Consumption plan | Flex Consumption plan |
| --- | --- | --- |
| 提供状況 | Windows: GA / **Linux: 2028年9月30日に廃止予定** | GA、現在の推奨プラン |
| 新機能・新言語バージョン | 追加されない（Linuxは凍結） | 今後も追加される |
| 移行ガイド | [Consumption→Flex移行ガイド](https://learn.microsoft.com/azure/azure-functions/migration/migrate-plan-consumption-to-flex)あり | - |

> 補足: 「v3ランタイムをLinux Consumptionで動かしているアプリは2026年9月30日で停止」という別の期限もあるが、これはEOLになった**v3プログラミングモデル**（in-process等の旧モデル）が対象で、このリポジトリで使っている`func.FunctionApp()`ベースの**v2プログラミングモデル（v4ランタイム）**には関係ない。

## 課金モデル

| 項目 | Consumption plan | Flex Consumption plan |
| --- | --- | --- |
| 課金モード | 実行回数 + 実行時間(GB-s)の1種類のみ | **On Demand**（実行回数+GB-s）と**Always Ready**（待機インスタンスの基礎料金+実行分）の2モード。混在可 |
| 無料枠（実行回数/月） | **100万回** | 250,000回（On Demandのみ） |
| 無料枠（GB-s/月） | **400,000 GB-s** | 100,000 GB-s（On Demandのみ） |
| 最小課金単位 | 実行あたり100ms刻み | 実行あたり1,000ms、以降100ms刻み |
| インスタンスメモリ | 固定（128MB刻み、最大1.5GB） | **選択式**（512MB / 2,048MB / 4,096MB） |

Consumption planの方が無料枠が4倍大きい。低頻度アクセスの個人開発規模であれば、どちらのプランでも無料枠に収まり実質無課金になりやすい（単価$/GB-s・$/百万実行は価格ページがJSレンダリングのため本メモでは未転記。最新値は[pricing page](https://azure.microsoft.com/pricing/details/functions/)を確認）。

## スケーリング・コールドスタート

| 項目 | Consumption plan | Flex Consumption plan |
| --- | --- | --- |
| スケーリング方式 | イベント駆動（アプリ単位） | イベント駆動、**per-function scaling**（トリガー種別ごとに独立してスケール。HTTP/Blob(Event Grid)/Durableはグループ内で共有） |
| 最大インスタンス数 | Windows: 200 / Linux: 100 | 1,000（function groupごと。Always Ready分は別枠） |
| コールドスタート | 発生しうる（プリウォームされたプレースホルダーである程度緩和） | **0インスタンスからでも改善済み**。Always Readyインスタンスでさらに削減可能 |
| 同時実行の制御 | 基本的に自動（細かい制御は限定的） | per-instance concurrencyを関数トリガーごとに設定可能 |

## タイムアウト・その他の制限

| 項目 | Consumption plan | Flex Consumption plan |
| --- | --- | --- |
| デフォルトタイムアウト | 5分 | 30分 |
| 最大タイムアウト | **10分** | 実質無制限（スケールイン猶予60分） |
| VNet統合（アウトバウンド） | **できない** | **できる** |
| プライベートエンドポイント（インバウンド） | **できない** | **できる** |
| デプロイスロット | 2 | **サポートなし** |
| 永続化ストレージ（Azure Files） | 1 GB | 0 GB（マウント不可） |
| 1プランあたりのFunction App数 | 最大100（相乗り可） | **1（専有）** |
| 対応OS | Windows / Linux（Linuxは廃止予定） | **Linuxのみ** |

## 技術選定の判断基準

### Consumption plan（Y1）を選んでよいケース

- 既存資産がWindows依存（フルの.NET Framework、特定のPowerShellモジュールなど）
- とにかくシンプルに、無料枠内で収めたい小規模・低頻度なワークロード
- 複数のFunction Appを1プランに相乗りさせてコストをまとめたい
- （今のところ）Linux版もまだ使えるが、長期運用するなら移行前提で見ておく

### Flex Consumption plan（FC1）を選ぶべきケース

- 新規にサーバーレスFunction Appを作る（Microsoft推奨）
- Azure Resourcesなど**VNet越しのプライベートアクセス**が必要
- コールドスタートの影響を抑えたい（Always Readyインスタンス）
- ワークロードのスパイクが激しく、per-functionでの高速スケーリングが欲しい
- 実行時間5〜10分を超える処理がある、またはタイムアウトの余裕が欲しい
- インスタンスメモリを用途に合わせて選びたい（512MB〜4GB）

## resource-cleanup-checkerでの結論

個人開発規模で低頻度アクセスのため、コスト面ではどちらも無料枠内に収まり実質差がない。VNet統合やAlways Readyも現時点では不要。**Y1のまま運用し、Linux Consumptionの廃止（2028年9月）が近づいたらFlex Consumptionへ移行する**方針とした。プラン変更は[terraform/modules/function_app](../projects/resource-cleanup-checker/terraform/modules/function_app/variables.tf)の`sku_name`を`FC1`に変えるだけで済むよう、モジュール側で変数化してある。

## まとめ

| 観点 | 有利な方 |
| --- | --- |
| 無料枠の大きさ | Consumption plan |
| 将来性・新機能 | Flex Consumption plan |
| VNet統合・プライベートアクセス | Flex Consumption plan |
| コールドスタート対策 | Flex Consumption plan |
| タイムアウトの余裕 | Flex Consumption plan |
| 複数Function Appの相乗り | Consumption plan |
| Windows依存資産のサポート | Consumption plan |
| 長期運用の安全性 | Flex Consumption plan（LinuxのConsumptionは廃止予定） |

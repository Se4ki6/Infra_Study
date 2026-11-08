# モノレポ移行インベントリ

調査日: 2026-11-08（Asia/Tokyo）

## L0: 作業開始時点

| リポジトリ | 作業パス | ブランチ | HEAD | 開始時の作業状態 |
| --- | --- | --- | --- | --- |
| 移行先 Infra_Study | `/home/sksrd/wsl_program/infra_study` | `main` | `68c4982695980d1e32956d3c065636b1ab25a148` | 追跡ファイルの変更 0、未追跡 2 (`docs/Plans/`、`docs/logs/open-telemetry/implementation-plan.md`) |
| 移行元 AWS_Study | `/mnt/c/Users/sksrd/Programing/AWS` | `main` | `055d3238fecfa77bb949170340731f50afb8db80` | 変更 150、削除 0、未追跡 4 |
| 移行元 Azure_practice | `/mnt/c/Users/sksrd/Programing/Azure` | `main` | `2c2a16acf973c4c4cb69b7a24ec7faa85484c1c8` | 変更 18、削除 36、未追跡 12 |

## 安全な作業範囲

- 移行元は参照のみ。ファイル変更、Git 操作による状態変更、コミットをしない。
- 移行先の既存未追跡ファイルは保持する。移行先で作業ブランチを作成する前に、L4 で現在のブランチと作業ツリーを再確認する。
- クラウドへのデプロイ、Terraform の `apply` / `destroy`、`git push` は行わない。

## L1 AWS

確認済み。追跡ファイルは 224 件、作業ツリー変更は 150 件、標準の未追跡一覧に現れる主な追加は `Basic/`、`AWS_Blocks/janken/`、`my-janken/`、`AWS_Blocks/my-todo-app/.hosting/`。変更の大半は改行差分で、`git diff --ignore-space-at-eol --shortstat` は 2 ファイル 3 行の差分を示す。ファイル名一覧だけでは差分件数を正しく表さないため、移行時は作業ツリーの現行内容を採用し、差分を破棄しない。

**採用候補**

- `AWS/resources/`: `Amplify/Host_Github_Repository`、`CloudFront_Functions`、`CloudFront_S3`、`CloudFront_test`、`Lambda`、`S3`。
- `AWS/projects/`: `Lambda_ApiGW_QR_Generator`、`S3_APIGW_Lambda_SimpleApp`、`AWS_Blocks/my-todo-app`。
- `Cross-Cloud/S3_STS_AzureFunction/`: 現在の AWS 側クロスクラウド実装。既存の `Cross-Cloud/S3_OIDC_AzureFunction/` とは別パス。
- `AWS/docs/` と `AWS/README.md`: AWS の説明資料と入口。
- `Basic/Bedrock/progress.md`: 他の `Basic/` 内は主に Terraform state、tfvars、lock file 等のローカル状態であり除外。progress は固有ノートとして候補に残す。
- `my-janken/` と `AWS_Blocks/janken/`: 現行ソースに差分があるため別々の候補として比較し、重複扱いでどちらかを消さない。

**保留・除外候補**

- `Project/Obsidian_Publish/`: 現在確認できたのは workflow ファイルのみ。関連ソースの有無を確認するまで保留。
- `.hosting/`、`build-temp/`、`cdk.out/`、`dist/`、`.bb-data/`、`.blocks-sandbox/` 等は生成物・ローカル状態として除外。
- 追跡済みの `.tfvars` は 8 件確認。実値を含む可能性があるため、個別内容を安全に確認できるまで全て除外する。`*.tfvars.example` は例として確認後に採用可。
- `.github/`、ルート `.gitignore` はツール・リポジトリ設定として L8 で既存設定との統合要否を判断する。

## L2 Azure

確認済み。現在の working tree で `resources/{blob,functions,vm}` は削除済み、同等の実装が `resource-learn/{blob,functions,vm}` に未追跡の現行配置として存在する。`resources/` 側の旧 HEAD 版を再コピーせず、`resource-learn/` の現行内容を採用候補にする。Azure の 36 削除、18 変更、12 未追跡という開始状態は L0 に記録済み。

**採用候補**

- `Azure/resources/{blob,functions,vm}/`: 現行の学習資料・実装。`.terraform/` のダウンロード済み module と state、ローカル設定は除外。
- `Azure/projects/{bastion-web-todo,blob-publicshere}/`: 現在の作業ツリー。既存移行先の同名プロジェクトと衝突がないことを L4 で確認する。
- `Azure/plans/`、`Azure/zenn/`、`Azure/LICENSE`: 計画、記事、ライセンス資料。
- `Azure/AGENTS.md`、`Azure/CLAUDE.md`、`.codex/`、`.github/` と `.claude/skills/`: L8 でパス修正と重複を確認して選別。

**保留・除外候補**

- `.claude/worktrees/` は作業用 checkout の複製なので除外。
- `.claude/skills/use-tavily/src/logs/` の調査ログは生成データとして除外。`.claude/skills` の他ファイルは L8 で `.codex/skills` との重複を比較する。
- `resources/` の削除済み HEAD 版は内容回復の参照にのみ用い、現行版へのコピー対象にしない。
- ローカル Terraform state、`.terraform/`、実値入り設定は除外。`.tfvars.example` は例として内容を確認して採用可。

## 作業ログ

| タスク | 状態 | 結果 |
| --- | --- | --- |
| L0 | 完了 | 3 リポジトリのブランチ、HEAD、開始時の変更数を記録。移行元は変更していない。 |
| L1 | 完了 | AWS の採用候補、保留候補、改行差分、tfvars を記録。実ソースはまだコピーしていない。 |
| L2 | 完了 | Azure の旧 `resources/` 削除と現 `resource-learn/` 配置を確認。現行の作業ツリーを候補とし、ローカル生成物は除外。 |
| L3 | 完了 | 326 ファイルを候補マニフェストに記録（320 通常候補、Terraform lock file 6）。tfvars・state・生成物を除外。パターン走査で4件一致し、3件は説明用 placeholder、1件はコピー時の置換対象。ツール型秘密情報スキャナーは未導入のため、マニフェストに検査の限界を明記。3件の telemetry 設定は L8 保留。 |
| L4 | 完了 | `codex/monorepo-migration-20261108` を作成。候補の既存ファイル衝突 0 件。共通 `.gitignore` を追加し commit `44ea4ce` を作成。既存未追跡ファイルは未変更。 |
| L5 | 完了 | 許可リストの AWS 資料・リソース・プロジェクトを個別コミットで取り込み。CRLF はコピー先のみ LF 化し、通常ファイルの mode は 100644 に統一。Markdown の hard break は `<br>` として保持。AWS 固有 `.gitignore` を追加。 |
| L6 | 完了 | `S3_STS_AzureFunction` を既存 `S3_OIDC_AzureFunction` と別パスに取り込み、lock file とサンプルを含めた。 |
| L7 | 完了 | Azure の現行 resource-learn、resource-project、plans、zenn、LICENSE を取り込み完了。旧削除パスと `.terraform/` は取り込んでいない。 |
| L8 | 完了 | janken の2版を別々に保持。telemetry projectId 設定、ローカル `.env`、worktree・調査ログは除外。必要な Codex 設定、AGENTS、GitHub prompt/agent を選別して新パスへ移植。 |

| L9 | 完了 | ルート/AWS/Azure README と移動に伴う文書参照を修正。Azure VM/TODO/Blob と Cross-Cloud の旧パス案内を更新。移行対象 Markdown 77 件で相対リンク検査を実施し、切れたローカルリンク 0 件。Terraform の `s3.tf` 整形を修正。 |
| L10 | 完了（一部未実施） | manifest 346 行（採用 343、除外 3）、重複 0、採用先欠落 0、採用元欠落 0 を確認。対象 Markdown 77 件のリンク 0 件。`terraform fmt -check` は AWS S3 APIGW の1ファイルを修正後、当該プロジェクトと STS クロスクラウドで通過。`terraform validate` は対象設定で試行したが、provider 未取得またはローカル module 未初期化のため成立せず、init/通信が必要になるため実施を止めた。Azure Bicep CLI は利用できず、Blocks の Node 依存も未導入のため Bicep build/Node test は未実施。デプロイ、apply/destroy、push は未実施。|
| L11 | 完了 | モノレポ案内と移行結果を記録。移行元リポジトリの README 更新、merge、push は行わず、旧リポジトリを参照用として残す。|

## L10 検証の範囲と制約

- 移行対象 Markdown 77 件に対するローカルリンク検査は 0 件の切れを確認。全リポジトリ走査には既存の生成済み `temp/mslearn_mcp/` と今回の移行対象外資料が混在するため、移行範囲に限定した。
- Terraform の `fmt -check` を移行した設定で実施し、`AWS/projects/S3_APIGW_Lambda_SimpleApp/s3.tf` の書式を整えた。移行対象外の既存 `Cross-Cloud/S3_OIDC_AzureFunction/terraform/azure/terraform.tfvars` にも全体再帰チェックで未整形が出るが、編集していない。
- `terraform validate` は provider/module のローカル未取得で失敗または未実施相当。ネットワーク取得や `terraform init` は行っていない。
- `az bicep` CLI と Bicep CLI が利用できず build 未実施。Blocks の `node_modules` がなく、インストールを伴うテストは未実施。既存で変更中の `Azure/projects/otel-order-api/` はビルド・テスト対象にしなかった。
- 秘密情報ツールは環境にない。manifest 記載のローカルパターン検査とファイル許可リスト確認を使用。state、実値 tfvars、ローカル設定、生成物は採用していない。
- 移行開始時に未追跡だった `docs/Plans/implementation-plan.md` と `docs/logs/open-telemetry/implementation-plan.md`、および作業中の `Azure/projects/otel-order-api/` 変更はステージしない。

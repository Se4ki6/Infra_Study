# AWS・Azure 学習リポジトリのモノレポ移行計画

## 目的と前提

- 移行元: `C:\Users\sksrd\Programing\AWS`（`AWS_Study`）と `C:\Users\sksrd\Programing\Azure`（`Azure_practice`）。
- 移行先: この `Infra_Study` リポジトリ。既存の `AWS/`、`Azure/`、`Cross-Cloud/`、`docs/` と既存プロジェクトを保持する。
- ここではファイルの移行、Git 履歴の統合、クラウドへのデプロイを実行しない。以下は移行作業の順序と完了条件を定める。

## 現状調査（2026-11-08）

| 対象 | 確認した状態 | 移行への影響 |
| --- | --- | --- |
| `Infra_Study` | `AWS/` は空の配置先、`Azure/projects/` には 2 件、`Cross-Cloud/` には 1 件の既存実装がある。`docs/Plans/implementation-plan.md` は未追跡。 | 既存の内容と未追跡ファイルを上書きしない。 |
| `AWS_Study` | `main` に追跡ファイル 224 件。大量の未コミット差分は主に改行コード由来だが、実質的な変更と未追跡の `Basic/`、`my-janken/` などもある。`*.tfvars` の追跡実績がある。 | 取り込む作業状態を先に確定し、変数ファイルと全履歴の機密情報を点検する。 |
| `Azure_practice` | `main` に追跡ファイル 80 件。`resources/` から `resource-learn/` への移動途中と見られる未コミットの変更がある。`.claude/worktrees/`、`.codex/` などの未追跡ファイルがある。 | 移動の完了状態を確定し、作業用 worktree とツール設定を選別する。 |

## 推奨配置

| 移行元 | 移行先 | 方針 |
| --- | --- | --- |
| AWS の `S3/`、`CloudFront_*`、`Lambda/`、`Amplify/` | `AWS/resources/<元の名前>/` | 単一サービスの演習をまとめる。 |
| AWS の `Lambda_ApiGW_QR_Generator/`、`S3_APIGW_Lambda_SimpleApp/` | `AWS/projects/<元の名前>/` | 複数サービスからなる実装をまとめる。 |
| AWS の `AWS_Blocks/`、`my-janken/` | `AWS/projects/aws-blocks/` など | 重複する janken 実装を比較し、正本を決めてから配置する。 |
| AWS の `S3_STS_AzureFunction/` | `Cross-Cloud/S3_STS_AzureFunction/` | 既存の `S3_OIDC_AzureFunction/` とは別プロジェクトとして保持し、差分を評価した後で統合を検討する。 |
| AWS の `docs/` と `README.md` | `AWS/docs/` と `AWS/README.md` | 既存の `.gitkeep` を実ファイルで置き換える。 |
| Azure の `resource-learn/{blob,functions,vm}/` | `Azure/resources/{blob,functions,vm}/` | 現在の作業ツリーを正本候補にし、旧 `resources/` との差分を確認する。 |
| Azure の `resource-project/` | `Azure/projects/` | 既存の 2 件と名前の衝突がないことを再確認する。 |
| Azure の `plans/`、`zenn/`、`LICENSE` | `Azure/plans/`、`Azure/zenn/`、`Azure/LICENSE` | 計画やライセンスの由来を残す。ライセンスの適用範囲を README に明記する。 |
| 両移行元の `.github/`、`.claude/`、`.codex/`、`AGENTS.md` | 内容ごとに判断 | ルートへ丸ごとコピーせず、現行の `.agents/`、`.claude/`、ツール規約と照合する。移植する指示は新しいパスに合わせて更新する。 |

AWS の `Basic/` と `Project/` は既存演習の複製やローカル生成物を含む。固有のソースやノートだけを特定して上記の配置先へ入れ、重複と `terraform.tfstate`、ビルド成果物は取り込まない。

## 実施順序

### 1. 移行対象の確定

1. 移行元それぞれで、改行コードだけの差分と実際の編集を分けて確認する。Azure の `resources/` 削除と `resource-learn/` 追加が意図どおりか確認する。
2. 未追跡ファイルを一覧化し、ソース・ドキュメント・設定のうち必要なものを選ぶ。`.venv/`、`node_modules/`、`.terraform/`、`.hosting/`、`.claude/worktrees/`、ローカルキャッシュ、ネストした `.git` は除外する。
3. 元リポジトリの commit ID と採用対象ファイル一覧を記録し、移行元を残したまま作業する。移行先の `docs/Plans/implementation-plan.md` を含む未追跡ファイルも保持する。

### 2. 秘密情報と履歴の点検

1. 追跡済みの `*.tfvars`、`.claude/settings.local.json`、未追跡の `*.tfstate`、環境ファイル、設定 JSON などを確認する。実値が必要なファイルは移行対象から外し、サンプルファイルだけを追加する。
2. ルートと各ディレクトリの `.gitignore` を整理する。Terraform state、plan、認証情報、ビルド成果物を除外し、利用する Terraform ルートの `.terraform.lock.hcl` は原則として追跡する。画像や ZIP の一律除外は用途を確認してから決める。
3. 旧 Git 履歴を統合する場合は、現在のファイルだけでなく全コミットを機密情報検査する。過去の内容が安全と確認できない限り履歴を取り込まない。

### 3. 隔離した作業ブランチで取り込み

1. `Infra_Study` の新しい作業ブランチを作る。まず既存ファイルと移行対象のパス衝突を機械的に確認する。
2. 推奨は**選別した現在のスナップショットをコミット単位で移す方法**。旧リポジトリは履歴参照先として残し、移行コミットに元 URL と commit ID を記す。これなら未整理の旧履歴や Terraform 変数ファイルを一括で持ち込まない。
3. 履歴をモノレポにも残す必要がある場合だけ、移行元をクリーンな状態にして履歴全体を検査し、別クローン上でパスを付け替えて統合する。この方式は移行範囲と履歴の機密情報検査結果を見て決定する。
4. AWS と Azure を別コミットで取り込み、`Cross-Cloud/S3_STS_AzureFunction/` も独立したコミットにする。重複プロジェクトの整理は別コミットで行う。

### 4. パスと開発手順の更新

1. README、Markdown リンク、スクリプト、Terraform の相対パス、Bicep の参照、CI の作業ディレクトリを新配置に合わせる。プロジェクト内相対パスが維持される場合も実行して確認する。
2. ルート README にクラウド別・横断プロジェクト別の目次、前提ツール、各演習への入口を追加する。旧リポジトリの README からも新しい場所が分かるようにする。
3. 共通 CI を作る場合は変更されたプロジェクトだけを検証する構成にする。`.github/` の設定は重複や用途を確認してからルートへ統合する。

### 5. 検証と切り替え

1. 採用対象のファイル一覧と移行先の差分を比較し、欠落と意図しない重複がないことを確認する。`git status` と秘密情報検査で state や認証情報の混入を確認する。
2. 対象ごとに Terraform `fmt -check`・`validate`、Bicep `build`、アプリの既存テストやビルドを実行する。`terraform apply` や Azure デプロイは移行検証に含めない。
3. 既存の `Azure/projects/` と `Cross-Cloud/` の主要な手順が引き続き使えることを確認する。レビュー後に新しい `Infra_Study` を更新先とし、旧リポジトリは参照用として残す。

## 完了条件

- 採用した AWS・Azure のソースと資料が、対応表どおりに配置されている。
- 移行元の作業内容について、採用・保留・除外の判断が記録されている。
- Terraform state、実値入り変数ファイル、認証情報、生成物が新しい Git 履歴に入っていない。
- ルートと各プロジェクトの README から実行・検証手順にたどれる。
- 移動に伴うリンクとパスを修正し、対象の静的検証と既存テストが通る。

## GPT-6 Luna 用の実行手順

この節を実行時のチェックリストとする。**1 回の依頼で 1 タスクだけ実施**し、結果を確認してから次に進む。`(対象)` があるタスクは、`AWS/S3` や `Azure/resource-learn/blob` など、元の 1 プロジェクトまたは 1 資料群を指定して繰り返す。各タスクの報告には「変更ファイル、実行した確認、残る判断」を含める。前段の成果物がない場合は次に進まない。移行元の 2 リポジトリは読み取り専用で扱い、コミット・改名・削除・改行コードの一括修正をしない。移行先でも `terraform apply`、`destroy`、クラウドへのデプロイ、`git push` は実施しない。

| ID | 1 回の依頼で行う作業 | 作成・更新する成果物 | 完了判定 |
| --- | --- | --- | --- |
| L0 | 3 リポジトリのブランチ、HEAD、`git status --short` を記録する。 | `docs/Plans/monorepo-migration-inventory.md` | 既存の未追跡ファイルと未コミット変更を記録した。どのリポジトリも変更していない。 |
| L1 | AWS の現在の作業ツリーから、追跡済みで存在するファイルと未追跡ファイルを一覧化する。改行コードのみの変更と内容変更を分ける。 | 同上の AWS 節 | `Basic/`、`Project/`、`AWS_Blocks/`、`my-janken/` の採用候補と保留候補をパス単位で列挙した。 |
| L2 | Azure で L1 と同じ調査をし、旧 `resources/` と現 `resource-learn/` の対応を確認する。 | 同上の Azure 節 | `resource-learn/{blob,functions,vm}` の採用候補を列挙し、旧 `resources/` との対応と差異を記録した。 |
| L3(対象) | 1 プロジェクトの採用候補について、秘密情報と生成物を調べ、コピー対象ファイルの許可リストを作る。全対象で繰り返す。 | `docs/Plans/monorepo-migration-manifest.md` | 対象の各ファイルに「移行元、移行先、採用・保留・除外、理由」があり、機密情報の疑いがあるファイルを採用にしていない。 |
| L4 | 許可リストと既存ツリーの衝突を確認し、移行先に作業ブランチと共通 `.gitignore` を用意する。 | 作業ブランチ、`.gitignore`、衝突結果を manifest に追記 | 既存ファイルの上書き予定が 0 件。既存の未追跡ファイルを保持した。 |
| L5(対象) | 許可リストにある AWS の 1 演習、1 プロジェクト、または `docs/` と README の 1 資料群をコピーする。全対象で繰り返す。 | `AWS/resources/`、`AWS/projects/`、`AWS/docs/`、`AWS/README.md` | 対象パスが manifest と一致し、state・実値入り tfvars・生成物がない。対象分だけをコミットした。 |
| L6 | AWS の `S3_STS_AzureFunction/` を別名のまま取り込む。 | `Cross-Cloud/S3_STS_AzureFunction/` | 既存の `S3_OIDC_AzureFunction/` を変更せず、対象パスが manifest と一致する。単独コミットにした。 |
| L7(対象) | Azure の `resource-learn/` または `resource-project/` の 1 プロジェクト、あるいは `plans/`、`zenn/`、`LICENSE` の 1 資料群を取り込む。全対象で繰り返す。 | `Azure/resources/`、`Azure/projects/`、`Azure/plans/`、`Azure/zenn/`、`Azure/LICENSE` | 既存 Azure プロジェクトを変更せず、対象パスが manifest と一致する。対象分だけをコミットした。 |
| L8(対象) | `Basic/`、`Project/`、janken 実装、AI ツール設定の保留候補を 1 グループだけ比較する。 | manifest の判断欄と必要な追加ファイル | 重複の根拠と採用先を記録した。曖昧なものは保留のまま残し、別のプロジェクトを妨げない。 |
| L9(対象) | 取り込んだ 1 プロジェクトの README、Markdown リンク、スクリプト、IaC パスを更新する。全対象の後にルート README を更新する。 | ルート README、該当プロジェクトの文書・コード | 対象の旧パス検索結果を確認し、移動によって壊れた参照を修正した。 |
| L10(対象) | 取り込んだ 1 プロジェクトのコピー差分と静的検証を確認する。全対象の後にリポジトリ全体を点検する。 | manifest の検証結果 | 対象のコピー漏れ・上書き・秘密情報の混入がなく、実行できる既存テストと IaC 検証が通る。失敗は対象と原因を記録する。 |
| L11 | 移行先と旧リポジトリの案内を整理する。 | 最終報告と、必要なら旧 README の更新案 | レビュー可能な差分と未解決事項を提示した。旧リポジトリの変更、マージ、push は別途依頼された場合に行う。 |

### タスクごとの具体的な判断規則

- **L0–L2:** `git -C <移行元> status --short`、`git -C <移行元> ls-files`、`git -C <移行元> ls-files --others --exclude-standard` を使う。`git ls-files` に載っていても作業ツリーで削除済みのファイルはコピーしない。行末差分の確認には `git diff --ignore-space-at-eol --shortstat` を使い、内容の差分を勝手に破棄しない。
- **L3:** `*.tfstate*`、`*.tfplan*`、実値入り `*.tfvars`、実値入り `.env*`、`local.settings.json`、`.venv/`、`node_modules/`、`.terraform/`、`.hosting/`、`.claude/worktrees/`、`.git/` は採用候補から外す。`.env.example` などのサンプルや lock file は中身と用途を確認して判断する。ファイル名による除外だけで安全とみなさず、採用候補の内容を確認する。検出した値そのものを報告書やチャットに貼らない。
- **L3:** 旧 Git 履歴は今回のコピー対象に含めない。履歴統合が必要になった場合は別計画とし、全コミットの機密情報検査を先に行う。
- **L4–L7:** manifest の採用行だけをコピーする。移行先に同名ファイルがあれば上書きせず衝突として報告する。各グループのコミット前に `git status --short`、`git diff --cached --check`、`git diff --cached --name-only` を確認し、予定外のファイルをステージから外す。
- **L8:** `AWS_Blocks/janken`、`AWS_Blocks/my-janken`、ルートの `my-janken` は同一と決めつけない。`Basic/` と `Project/` も、固有のソースやノートだけを採用候補にする。どちらが正本か客観的に決まらなければ保留として報告する。
- **L9:** プロジェクト内部で完結する相対パスも、実行ディレクトリが変わる手順は確認する。Azure の `AGENTS.md` には旧 `resources/` の参照があるため、移植する場合は新配置と整合させる。
- **L10:** Terraform は各ルートで `fmt -check` と `validate`、Bicep は `build`、アプリは既存のビルド・テストを対象ごとに実行する。必要なツールや認証がない検証は「未実施」と理由を記録し、成功扱いにしない。クラウドに変更を加えるコマンドは使わない。

### 次の依頼に進むための報告形式

```text
タスク ID:
実施内容:
変更ファイル:
確認コマンドと結果:
採用・保留・除外の判断:
未解決事項:
次に実施できるタスク ID:
```

判断に迷う点が出たら、該当ファイルを**保留**にして同じタスク内でほかの確定部分を進める。機密情報の疑い、既存ファイルの衝突、移行元の書き換えが必要な場合は、その部分を止めて報告する。

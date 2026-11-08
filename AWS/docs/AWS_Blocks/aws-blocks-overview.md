---
title: "AWS Blocks 入門 ― ローカルで作り、コード無変更でAWSへ deploy する TypeScript フレームワーク"
emoji: "🧱"
type: "tech"
topics: ["aws", "typescript", "cdk", "serverless", "infrastructure"]
published: false
---

> この記事は 2026 年 6 月時点の情報に基づきます。AWS Blocks は **Preview(プレビュー)** であり、コマンド名・API・対応範囲は今後変わる可能性があります。最新情報は必ず[公式 Developer Guide](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html) を確認してください。

## AWS Blocks とは

[AWS Blocks](https://aws.amazon.com/jp/products/developer-tools/blocks/) は、AWS 上にフルスタックアプリのバックエンドを構築するための **オープンソースの TypeScript フレームワーク** です。2026 年 6 月 16 日にパブリックプレビューが発表されました。

一言でいうと「**インフラを学ばずに、業務ロジックに集中してバックエンドを書ける**」ことを狙ったツールです。CloudFormation のテンプレートや各 AWS サービスの細かい設定を自分で書く代わりに、**Block(ブロック)** と呼ばれる部品を組み合わせると、AWS のベストプラクティスに沿ったインフラが自動的に定義されます。

最大の特徴は次の 2 点です。

- **ローカルファースト**: `npm run dev` を実行するだけで、データベース・認証・リアルタイム通信などを含む完全に動くアプリがローカルで立ち上がる。**AWS アカウントは不要**。
- **コード無変更で deploy**: ローカルで動かしたのと同じコードを、一切変更せずに AWS アカウントへデプロイできる。

> 出典: [What is AWS Blocks?](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html) / [AWS Blocks (Preview) 発表](https://aws.amazon.com/about-aws/whats-new/2026/06/aws-blocks-preview)

## 何が嬉しいのか

公式が挙げているメリットを、開発者目線で整理します。

- **数時間ではなく数秒で始められる**: 1 コマンドでローカルに動くアプリが立ち上がり、デプロイの準備が整うまで AWS アカウントすら要りません。
- **エンドツーエンドの型安全**: データスキーマからフロントエンドまで、TypeScript の型が一気通貫で流れます。コード生成ステップがないため、型のズレが起きません。
- **AI コーディングエージェント前提の設計**: 各 Block の npm パッケージに **steering files** が同梱されており、AI コーディングエージェントが最初から正しいアーキテクチャでコードを生成できます。プラグインのインストールや独自設定は不要です。
- **抽象に閉じ込められない**: すべての Block は本番の AWS サービスで動きます。深いカスタマイズが必要になったら **AWS CDK に「1 段降りて」** リソースを直接設定できます。表現できない抽象に縛られることがありません。
- **既存資産と組み合わせられる**: 外部の Postgres、API、認証プロバイダなど、既存リソースと接続できます。Block を 1 つずつ段階的に採用できます。

> 出典: [AWS Blocks 製品ページ](https://aws.amazon.com/jp/products/developer-tools/blocks/) / [What is AWS Blocks?](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html)

## 仕組み ― なぜ「無変更で deploy」できるのか

AWS Blocks の核心は、**Node.js の Conditional Exports（条件付きエクスポート）** という仕組みにあります。同じ `import` 文が、実行コンテキストによって異なる実装に解決されます。

```ts
import { KVStore } from '@aws-blocks/blocks';
// この import が、文脈に応じて別の実装を読み込む
```

解決先は次の 3 つのコンテキストに分かれます。

| コンテキスト | Block が解決される先 | 何が起きるか |
| --- | --- | --- |
| ローカル開発 | ローカル実装 | インメモリ / ファイルシステムのストレージを使い、自分のマシン上で動く |
| CDK 合成（デプロイ時） | CDK construct | CloudFormation テンプレートが生成される |
| 本番ランタイム | AWS SDK 連携 | AWS Lambda 上で SDK を通じて各 AWS サービスを呼ぶ |

つまり、こう書いた 1 行が:

```ts
new KVStore(scope, 'todos')
```

- 開発時は **ローカルのストア**
- デプロイ時は **Amazon DynamoDB のテーブル**
- 本番では **SDK 呼び出し**

に変わります。**コードは一切変えません**。これが「ローカルで作り、無変更でデプロイ」を成立させている仕掛けです。

> 出典: [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html) / [What is AWS Blocks?](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html)

## 基本の用語と構造

ドキュメントで頻出する用語を押さえておきます。

- **Block**: 1 つの機能（capability）について、インフラ・ランタイム・ローカル開発コードをまとめた自己完結型の npm パッケージ。
- **Scope**: Block に識別子（アイデンティティ）を与える名前空間コンテナ。
- **IFC レイヤー**: バックエンドのエントリポイントとなる `aws-blocks/index.ts`。ここで Block をインスタンス化し、API を定義します。**インフラはこのコードから導出されます**（IFC = Infrastructure From Code）。
- **CDK レイヤー**: 任意の `aws-blocks/index.cdk.ts`。CDK に直接アクセスして独自インフラを足したいときに使います。作らなければ、AWS Blocks が IFC レイヤーからデフォルトの CDK アプリを自動生成します。
- **ApiNamespace**: フロントエンドから呼べる型安全な RPC メソッドを定義する Block。
- **BlocksContext**: API ハンドラに渡されるリクエスト/レスポンスのコンテキストオブジェクト。

重要なのは、**AWS Blocks アプリは本質的に CDK アプリである**という点です。任意の CDK construct を Block と並べて使えますし、既存の CDK スタックに AWS Blocks を組み込むこともできます。

```ts
// aws-blocks/index.cdk.ts
import * as cdk from 'aws-cdk-lib';
import { BlocksStack } from '@aws-blocks/blocks/cdk';

const app = new cdk.App();
const stack = await BlocksStack.create(app, 'my-stack', {
  backendHandlerPath: './index.handler.ts',
  backendCDKPath: './index.ts',
});

// Block と並べて任意の CDK リソースを追加できる
const queue = new sqs.Queue(stack, 'my-queue');
queue.grantSendMessages(stack.handler);
stack.handler.addEnvironment('QUEUE_URL', queue.queueUrl);
```

> 出典: [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html)

## どんな Block があるのか（カタログ）

プレビュー時点で **20 以上の Block** が用意されています。アンブレラパッケージ `@aws-blocks/blocks` がすべての Block とコアランタイムを再エクスポートします。代表的なものと、デプロイ時にマッピングされる AWS サービスは次のとおりです。

| カテゴリ | Block | 役割 | デプロイ先の AWS サービス |
| --- | --- | --- | --- |
| データ & ストレージ | `KVStore` | キーバリューストア | Amazon DynamoDB |
| | `DistributedTable` | インデックス付き構造化データ | Amazon DynamoDB |
| | `Database` | 型安全な Postgres（Kysely クエリビルダ） | Amazon Aurora Serverless v2 |
| | `DistributedDatabase` | アイドルコストゼロのサーバーレス SQL | Amazon Aurora DSQL |
| | `FileBucket` | presigned URL 付きファイルストレージ | Amazon S3 |
| 認証 | `AuthBasic` | ユーザー名/パスワード | Amazon DynamoDB + JWT |
| | `AuthCognito` | MFA・グループ・パスキー対応のマネージド認証 | Amazon Cognito |
| | `AuthOIDC` | OIDC サインイン（Google / GitHub / Okta など） | OAuth リダイレクトフロー |
| コンピュート & バックグラウンド | `AsyncJob` / `CronJob` | 非同期処理・定期実行 | マネージドコンピュート |
| AI | `Agent` / `KnowledgeBase` | AI エージェント・ナレッジベース | Amazon Bedrock |
| 通信 | `Realtime` | pub/sub（ローカルサーバー → 本番 WebSocket） | Amazon API Gateway (WebSocket) |
| | `EmailClient` | メール送信 | — |
| 設定 | `AppSetting` | アプリ設定 | — |
| 可観測性 | `Logger` / `Metrics` / `Tracer` / `Dashboard` | ログ・メトリクス・トレース・ダッシュボード | Amazon CloudWatch |
| ホスティング | `Hosting` | SSR 対応のフロントエンドデプロイ（CDK レイヤー） | Amazon CloudFront + Amazon S3 |

ローカルでは、たとえば `Database` は **PGlite** で動く Postgres、`FileBucket` はローカルファイルシステム、`Realtime` はローカル pub/sub サーバーとして振る舞い、デプロイ時にマネージドサービスへ切り替わります。バックエンド API は **Amazon API Gateway** で公開されます。

> 出典: [What is AWS Blocks?](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html) / [GitHub: aws-devtools-labs/aws-blocks](https://github.com/aws-devtools-labs/aws-blocks)

## Getting Started ― 動かすまでの流れ

### 前提条件

- **Node.js 22 以降** / **npm 10 以降**（`node --version` / `npm --version` で確認）
- TypeScript 対応のエディタ（Visual Studio Code や Kiro など）
- （任意のデプロイ手順用）AWS CLI の認証情報設定と、CDK の bootstrap 済みアカウント

### プロジェクト作成からローカル起動まで

```bash
# プロジェクトを作成
npm create @aws-blocks/blocks-app@latest my-todo-app
cd my-todo-app
npm install

# ローカル開発サーバーを起動（AWS アカウント不要）
npm run dev
```

生成されるプロジェクト構造はシンプルです。

```text
my-todo-app/
├── aws-blocks/
│   └── index.ts     # IFC レイヤー: バックエンド定義
├── src/
│   └── app.tsx      # フロントエンド
└── package.json
```

`npm run dev` を実行すると、認証・CRUD・ソート付きの Todo アプリがローカルで立ち上がります。このとき各 Block はローカル実装で動作します（例: `DistributedTable` はインメモリ、`AuthBasic` はローカル JWT）。バックエンドは `aws-blocks/index.ts`、フロントエンドは `src/` に書き、型は **コード生成なしで** 端から端まで流れます。

```ts
// 例: 2 つの Block を定義する（getting-started より）
new AuthBasic(scope, 'auth');          // ローカルは JWT、AWS では DynamoDB テーブル
new DistributedTable(scope, 'todos', { /* ... */ }); // ローカルはインメモリ、AWS では DynamoDB
```

準備ができたら、CDK が bootstrap 済みのアカウントへ同じコードをデプロイします。

> 出典: [Getting started with AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html) / [GitHub README](https://github.com/aws-devtools-labs/aws-blocks)

## 既存環境との統合（4 つのパターン）

「すでに AWS リソースや既存バックエンドがある」場合の統合方法として、公式が 4 パターンを提示しています。段階的な採用が可能です。

1. **生 CDK + SDK**: プレーンな CDK と SDK で任意の AWS リソースにフルアクセス。ただしローカル実装はなく、`npm run dev` は自分でスタブしない限り実 AWS を呼びます。型レベルの環境変数保証もありません。
2. **`fromExisting`**: 一部の Block は、デプロイ済みリソースをラップできます。プロビジョニングはスキップしつつ、型安全な API とローカル実装を提供。IAM 権限は AWS Blocks の Lambda に自動付与されます。Block の API 範囲に限られる点が制約。
3. **独自 Block（Custom Block）**: 同じリソースパターンを 2 回以上使うなら、独自 Block にまとめて型安全 API・ローカル実装・再利用性を得ます。
4. **Vendorize**: ファーストパーティ Block がほぼ要件を満たすが CDK 変更が必要なとき、ソースを自分のプロジェクトに取り込んで所有します。`npx @aws-blocks/vendorize bb-kv-store ./packages/bb-kv-store` のように展開でき、以後は自分で保守します。

> 出典: [Integrating with existing infrastructure](https://docs.aws.amazon.com/blocks/latest/devguide/existing-infrastructure.html)

## CDK・Amplify との関係

混同しやすいので関係を整理します。

- **AWS CDK**: AWS Blocks アプリは CDK アプリそのものです。CDK construct を併用でき、既存 CDK スタックへ組み込めます。「もっと制御したい」ときの逃げ道が常にあります。
- **AWS Amplify**: **補完関係** です。Amplify はホスティング・CI/CD・マネージドなバックエンド体験を提供します。一方 AWS Blocks は **型安全な infrastructure-from-code とローカルファースト開発** に焦点を当てています。プロジェクト作成時のテンプレートにも `amplify` 系が用意されています。
- **AWS Lambda / API Gateway / DynamoDB / Aurora / Bedrock**: バックエンドコードは Lambda にデプロイされ、API は API Gateway で公開、データ層は用途に応じて DynamoDB / Aurora、AI は Bedrock が使われます。

> 出典: [What is AWS Blocks?](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html)

## ベストプラクティスと注意点

公式のベストプラクティスから、特に効くものを抜粋します。

- **Block を作りすぎない**: 各 Block は AWS リソースに対応します。データ型ごとに `KVStore` を新規作成するのではなく、**1 つのストアをキープレフィックスで分割**します（テーブル乱立はコスト増）。
  ```ts
  // 良い例: 1 ストアをプレフィックスで分割
  const store = new KVStore(scope, 'data', {});
  await store.set(`users:${id}`, userData);
  await store.set(`orders:${id}`, orderData);
  ```
- **ユーザースコープでデータを分離**: キーにユーザー ID を含めて、認証済みユーザーが他人のデータへアクセスできないようにします。
  ```ts
  // 良い例: ユーザーにスコープ
  await store.set(`${user.userId}:${itemId}`, data);
  ```
- **認証 Block を用途で選ぶ**: プロトタイプ/内部ツールは `AuthBasic`、ソーシャルログインは `AuthOIDC`、本番品質（MFA・SAML・パスキー・OIDC）は `AuthCognito`。
- **テストは段階的に**: ロジックは Block をモックしてユニットテスト → `npm run dev` でローカル統合テスト → 重要パスのみ sandbox にデプロイして実 AWS で E2E。ローカル実装は決定的で高速ですが、**実 AWS との挙動差** は sandbox で確認します。
- **ローカルファーストで回す**: `npm run dev` を主要な開発ループにし、実 AWS 固有の挙動が必要なときだけ sandbox にデプロイします。

> 出典: [Best practices for AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/best-practices.html)

## 料金・対応範囲・Preview の注意

- **料金**: AWS Blocks 自体は **追加料金なし**。アプリが使う AWS サービスの分だけ支払います。
- **対応リージョン**: すべての商用 AWS リージョンにデプロイ可能。
- **対応プラットフォーム**: Web（Next.js, Nuxt, Astro, React, Vue, Svelte, Angular）、ネイティブモバイル（Swift, Kotlin, Dart/Flutter）、デスクトップ。型安全はクライアントまで届きます。プレビュー時点で SPA（Vite + React 等）と SSR（Next.js, Nuxt, Astro）がサポート対象として挙げられています。
- **ステータス**: **Preview**。コマンド名や API、対応範囲は変わり得ます。本番採用は変更追従の覚悟をもって。

> 出典: [AWS Blocks (Preview) 発表](https://aws.amazon.com/about-aws/whats-new/2026/06/aws-blocks-preview) / [製品ページ](https://aws.amazon.com/jp/products/developer-tools/blocks/)

## まとめ ― 向いているケース / 注意したいケース

**向いているケース**

- TypeScript で素早くフルスタックの MVP / プロトタイプを立ち上げたい
- AWS の各サービスを深く学ぶ前に、まず動くものをローカルで作りたい
- AI コーディングエージェント中心の開発フローを採りたい
- 将来的に CDK で細かく制御する余地を残しておきたい

**注意したいケース**

- まだ **Preview** であり、破壊的変更が入り得る
- 細かい AWS リソース制御が最初から必須なら、Block の抽象より素の CDK が素直なこともある
- ローカル実装と実 AWS の挙動差は存在するため、重要パスは必ず実環境で検証する

AWS Blocks は「**インフラを学ばなくてもよい。ただし学びたくなったら CDK に降りられる**」という、抽象と逃げ道のバランスが効いたフレームワークです。Preview のうちに小さく触り、Conditional Exports による「無変更デプロイ」の体験を確かめてみるのがおすすめです。

## 参考リンク

- [AWS Blocks 製品ページ](https://aws.amazon.com/jp/products/developer-tools/blocks/)
- [GitHub: aws-devtools-labs/aws-blocks](https://github.com/aws-devtools-labs/aws-blocks)
- [AWS Blocks (Preview) 発表（What's New）](https://aws.amazon.com/about-aws/whats-new/2026/06/aws-blocks-preview)
- [What is AWS Blocks?（Developer Guide）](https://docs.aws.amazon.com/blocks/latest/devguide/what-is-blocks.html)
- [Getting started with AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)
- [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html)
- [Integrating with existing infrastructure](https://docs.aws.amazon.com/blocks/latest/devguide/existing-infrastructure.html)
- [Best practices for AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/best-practices.html)

---
title: "ゼロから学ぶ AWS Blocks ハンズオン ― Todo アプリをローカルで作って AWS へデプロイする"
emoji: "🛠️"
type: "tech"
topics: ["aws", "typescript", "cdk", "serverless", "tutorial"]
published: false
---

> この記事は 2026 年 6 月時点の情報に基づくハンズオンです。AWS Blocks は **Preview** のため、コマンド名・テンプレート・API は変わる可能性があります。手順がうまくいかないときは[公式 Getting started](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html) を確認してください。
>
> 本記事のコードは、実際に `@aws-blocks/create-blocks-app`（プレビュー 0.1.x）の **`demo` テンプレートを生成して動作確認** したものに合わせています。公式ドキュメントのサンプルとは細部（メソッド名やキー指定）が一部異なりますが、ここでは **実際に手元で生成される実物** を優先しています。
>
> AWS Blocks の概要・思想・Block カタログから知りたい方は、先に姉妹記事「AWS Blocks 入門」を読むとスムーズです。この記事は **手を動かすこと** に振り切っています。

## このハンズオンでやること

[AWS Blocks](https://aws.amazon.com/jp/products/developer-tools/blocks/) を使って、認証付きの Todo アプリを **ローカルで動かし**、コードを 1 行も変えずに **AWS へデプロイ** するところまでを体験します。

ゴールは次の 5 つです。

1. `npm create` → `npm run dev` でローカルに Todo アプリを起動する
2. バックエンド定義(`aws-blocks/index.ts`)を読めるようになる
3. API メソッドを 1 つ自分で追加して、フロントから型安全に呼ぶ
4. （任意）AWS にデプロイして、後片付けまでやる
5. 「なぜコード無変更でデプロイできるのか」を仕組みから理解する

**7 章までは AWS アカウント不要** で進められます。まずはローカルだけでも最後まで触れます。

:::message
**バックエンドの言語について**
AWS Blocks の **バックエンドは TypeScript 専用** です。C#・Python・Java などでは記述できません。これは設定の問題ではなく設計上の制約で、AWS Blocks 自体が「open-source **TypeScript framework**」と位置づけられており、型安全も TypeScript の generics / 型推論でスキーマからフロントまで型を伝播させる仕組みに依存しています。また、同じ `import` が文脈ごとに実装を切り替える Conditional Exports は Node.js の機構です。

- 提供される **クライアント** ライブラリは Web(TypeScript)・Swift・Kotlin・Dart で、**C# クライアントはありません**。
- 「もっと制御したい」場合に降りられる **AWS CDK は C# を含む複数言語に対応** していますが、それは AWS Blocks の Block / IFC レイヤーを C# で書けるという意味ではありません(CDK レイヤーから先の話です)。
- C#/.NET でサーバーレスなバックエンドを作りたい場合は、AWS Blocks ではなく AWS CDK(C#)+ AWS Lambda + Amazon DynamoDB + Amazon API Gateway を直接組む、別のアプローチになります。

出典: [Supported platforms](https://docs.aws.amazon.com/blocks/latest/devguide/supported-platforms.html) / [製品ページ FAQ](https://aws.amazon.com/products/developer-tools/blocks) / [AWS CDK 対応言語](https://docs.aws.amazon.com/cdk/v2/guide/languages.html)
:::

---

## 0. 完成イメージと所要時間

- 作るもの: 認証 + CRUD + 優先度ソート付きの Todo アプリ
- 使う Block: `AuthBasic`(認証）、`DistributedTable`(構造化データ）、`KVStore`(キーバリュー）、`ApiNamespace`(型安全 API)
- 所要時間の目安: ローカルまでで 15〜20 分、デプロイまで含めて +20〜30 分

> 出典: [Getting started with AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)

---

## 1. 環境を準備する

ローカル開発に必要なのは次の 3 つだけです。

- **Node.js 22 以降**
- **npm 10 以降**(Node.js に同梱)
- TypeScript 対応エディタ（Visual Studio Code や Kiro など）

バージョンを確認します。

```bash
node --version   # v22.x.x 以上
npm --version    # 10.x.x 以上
```

> ✅ チェックポイント: 両方のバージョンが基準を満たしていれば OK。古い場合は Node.js を更新してください。

（AWS へのデプロイを試す人は、後の 7 章で **AWS CLI** と **CDK の bootstrap** も使います。ローカルだけなら不要です。）

> 出典: [Getting started](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)

---

## 2. プロジェクトを作成する

Todo アプリ題材なので、`demo` テンプレートを指定してプロジェクトを作成します。依存インストールまで自動で行われます。

```bash
npm create @aws-blocks/blocks-app@latest my-todo-app -- --template demo -y
cd my-todo-app
```

> `npm create @aws-blocks/blocks-app` は、内部的に `@aws-blocks/create-blocks-app` を実行します。`-y` は確認プロンプトの省略、`--template` の後ろに渡す名前でテンプレートを選びます。

生成されるディレクトリ構造は次のとおりです（`demo` テンプレート）。

```text
my-todo-app/
├── aws-blocks/
│   ├── index.ts          # ① バックエンド本体: Block 定義と API 定義(IFC レイヤー)
│   ├── index.cdk.ts      #    CDK レイヤー(任意のカスタムインフラ)
│   ├── index.handler.ts  #    Lambda ハンドラのエントリ
│   ├── client.js / scripts/   # ローカルサーバー・デプロイ等のスクリプト
│   └── package.json
├── src/
│   └── index.ts          # ② フロントエンド: バックエンド API を直接呼ぶ
├── test/                 #    E2E テスト
├── cdk.json
├── index.html
├── package.json
└── tsconfig.json
```

ポイントは、**インフラ用に手書きする IaC ファイルが無い** ことです。`aws-blocks/index.ts` に書いた Block の定義から、インフラが自動的に導出されます（`index.cdk.ts` は独自リソースを足したいときだけ触ります）。

### テンプレートについて

`--template` で選べる代表的なものは次のとおりです（他に `bare` / `react` / `backend` / `nextjs` / `auth-cognito` / `amplify` もあります）。

| テンプレート | 内容 |
| --- | --- |
| `default` | API エンドポイントが 1 つだけの最小スターター(既定) |
| `demo` | 認証・`KVStore`・`DistributedTable`・CRUD を含む Todo アプリ ← 本記事 |

> ✅ チェックポイント: `my-todo-app` フォルダに `aws-blocks/index.ts` と `src/index.ts` があれば成功です。

> 出典: [Getting started](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html) / [AWS Blocks Developer Guide (PDF)](https://docs.aws.amazon.com/pdfs/blocks/latest/devguide/blocks-dg.pdf)

---

## 3. ローカルで動かす

開発サーバーを起動します。

```bash
npm run dev
```

ターミナルに `Deploying local resources...` と表示され、`http://localhost:3000` でローカルサーバーが起動します。ブラウザで開くと、**認証・CRUD・優先度ソート** が動く Todo アプリが表示されます。

このとき、各 Block は **ローカル実装** で動いています。

- `DistributedTable` / `KVStore` … データを **ローカル（インメモリ/ファイル）** で保持
- `AuthBasic` … **ローカル JWT トークン** で認証
- `ApiNamespace` … ローカル HTTP サーバー経由で呼び出しをルーティング

**AWS アカウントは不要**。コードを保存すると **ホットリロード**（`tsx watch`）で即座に反映されます。

> ✅ チェックポイント: 画面の認証 UI でサインアップ／サインインし、Todo を追加・完了・削除できれば、ローカル環境は完成です（demo は認証必須の API なので、まずサインインが必要です）。

> 出典: [Getting started](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)

---

## 4. バックエンドを読む（`aws-blocks/index.ts`）

このファイルが **IFC レイヤー(Infrastructure from Code)** です。Block を生成し、API を定義する場所で、ここからインフラが導出されます。

まず Block の定義部分です（`demo` テンプレートの実物）。`DistributedTable` のスキーマは **Zod** で型安全に書きます。

```ts
// aws-blocks/index.ts
import { ApiNamespace, Scope, KVStore, AuthBasic, DistributedTable } from '@aws-blocks/blocks';
import crypto from 'node:crypto';
import { z } from 'zod';

const scope = new Scope('my-app');

// キーバリューストア（AWS では DynamoDB）
const store = new KVStore(scope, 'app-store', {});

// 認証（AWS では DynamoDB + JWT）
const auth = new AuthBasic(scope, 'auth', {
  crossDomain: process.env.BLOCKS_SANDBOX === 'true',
});

// 構造化データ。Zod スキーマ + パーティション/ソートキー + GSI(インデックス)
const todoSchema = z.object({
  userId: z.string(),
  todoId: z.string(),
  title: z.string(),
  completed: z.boolean(),
  priority: z.number(), // 1=高, 2=中, 3=低
  createdAt: z.number(),
});

const todos = new DistributedTable(scope, 'todos', {
  schema: todoSchema,
  key: { partitionKey: 'userId', sortKey: 'todoId' },
  indexes: {
    byPriority: { partitionKey: 'userId', sortKey: 'priority' },
    byTitle: { partitionKey: 'userId', sortKey: 'title' },
    byCreatedAt: { partitionKey: 'userId', sortKey: 'createdAt' },
  },
});
```

ここで作っている主な Block は次のとおりです。

- `new AuthBasic(scope, 'auth', …)` … 認証システム。**ローカルでは JWT**、**AWS では DynamoDB + JWT** になります。
- `new DistributedTable(scope, 'todos', {…})` … 構造化データ。**ローカルではローカル実装**、**AWS ではインデックス(GSI)付き DynamoDB テーブル** になります。
- `new KVStore(scope, 'app-store', {})` … キーバリュー。**AWS では DynamoDB** になります。

`Scope`（ここでは `'my-app'`)は Block に一意な識別子を与える名前空間です。

### API を定義する `ApiNamespace`

フロントから呼べる型安全な RPC メソッドは `ApiNamespace` で定義します。`demo` の Todo API（抜粋）はこうです。

```ts
export const authApi = auth.createApi();

export const api = new ApiNamespace(scope, 'api', (context) => ({
  // 認証必須。ログイン中ユーザーのデータだけを扱う
  async createTodo(title: string, priority: number = 2) {
    const user = await auth.requireAuth(context);
    const todoId = Date.now().toString(36) + crypto.randomBytes(8).toString('hex');
    const todo = {
      userId: user.username,
      todoId,
      title,
      completed: false,
      priority,
      createdAt: Date.now(),
    };
    await todos.put(todo);
    return todo;
  },

  async listTodos(sortBy?: 'priority' | 'title' | 'createdAt') {
    const user = await auth.requireAuth(context);
    const indexMap = { priority: 'byPriority', title: 'byTitle', createdAt: 'byCreatedAt' } as const;
    const iterator = sortBy
      ? todos.query({ index: indexMap[sortBy], where: { userId: { equals: user.username } } })
      : todos.scan();
    return await Array.fromAsync(iterator);
  },

  async deleteTodo(todoId: string) {
    const user = await auth.requireAuth(context);
    await todos.delete({ userId: user.username, todoId });
    return { success: true };
  },
}));
```

注目したいのは `context`(= `BlocksContext`)です。API ハンドラに渡されるリクエスト/レスポンスのコンテキストで、`auth.requireAuth(context)` のように **認証チェック＋現在のユーザー取得** に使います（未ログインなら例外）。

> 💡 ポイント: ここで定義した `api` を、フロントエンドは **そのまま import して呼びます**。クライアント生成も API URL の設定も SDK 初期化も要りません。

:::message alert
**生成テンプレートのバグに注意（プレビュー 0.1.x）**
`listTodos` の `todos.query(...)` が、生成直後は旧シグネチャ `todos.query(indexMap[sortBy], { userId: { equals: ... } })`(引数 2 個)になっており、`npm run typecheck` で型エラーになります。実際の API は **オプションオブジェクト 1 個**なので、上記のように `todos.query({ index, where })` へ直してください。
:::

> 出典: [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html) / `@aws-blocks/create-blocks-app` demo テンプレート（実物）

---

## 5. フロントを読む（`src/index.ts`）

`demo` テンプレートのフロントは、フレームワーク無しの **バニラ TypeScript**（DOM 操作）です。バックエンドの API を **直接 import** します。

```ts
// src/index.ts
import { api, authApi } from 'aws-blocks';
import { Authenticator, onAuthChange } from '@aws-blocks/blocks/ui';
```

ポイントは 2 つです。

- `import { api } from 'aws-blocks'`: バックエンドの `api` をそのまま import。**クライアント生成・API URL 設定・SDK 初期化は一切なし**。`await api.createTodo('買い物', 1)` のように呼べて、引数・戻り値まで型が効きます。
- `Authenticator(authApi)` / `onAuthChange(...)`: AWS Blocks 同梱の認証 UI 部品。サインイン状態の変化に応じて Todo を再取得します。

その効果が分かりやすいのが次の挙動です。

> バックエンドでメソッドのシグネチャを変えると、フロントエンドは **その場でコンパイルエラー** になります。

型のズレが「実行してから」ではなく「書いた瞬間」に分かる、というのが AWS Blocks のうれしさです。

> 出典: `@aws-blocks/create-blocks-app` demo テンプレート（実物）/ [Getting started](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)

---

## 6. ハンズオン: API メソッドを 1 つ自分で追加する

`demo` には作成・一覧・更新・削除がすでに揃っています。そこで **「完了済み Todo をまとめて削除する」** メソッドを自分で追加してみましょう。`aws-blocks/index.ts` の `ApiNamespace` 定義の中に追記します。

```ts
// aws-blocks/index.ts の ApiNamespace の中に追加
async deleteCompleted() {
  const user = await auth.requireAuth(context);
  let deleted = 0;
  // 自分の Todo を走査し、完了済みだけ削除
  for await (const todo of todos.query({ where: { userId: { equals: user.username } } })) {
    if (todo.completed) {
      await todos.delete({ userId: user.username, todoId: todo.todoId });
      deleted++;
    }
  }
  return { deleted };
},
```

- `auth.requireAuth(context)` で **ログイン中ユーザー** を取得（未ログインは例外）
- `todos.query({ where: { userId: { equals: ... } } })` で **自分の Todo だけ** を走査
- `todos.delete({ userId, todoId })` で **完了済みのものだけ** を削除

保存すると開発サーバーがホットリロード（`tsx watch`）され、フロントから **型安全に** 呼べるようになります。

```ts
// フロントエンド側(src/index.ts など)
const { deleted } = await api.deleteCompleted();  // 戻り値 { deleted: number } も型が効く
```

> ✅ チェックポイント: `api.deleteCompleted(` の戻り値が `{ deleted: number }` として補完されれば、型がフロントまで通っている証拠です。メソッド名を打ち間違えると、フロント側が即コンパイルエラーになることも確認してみてください。`npm run typecheck` でも検証できます。

> 出典: `@aws-blocks/create-blocks-app` demo テンプレート（実物）/ [Getting started](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)

---

## 7. （任意）AWS へデプロイする

ここからは AWS アカウントが必要です。**ローカルだけで満足な人は飛ばして 9 章へ** 進んでも構いません。

### 7.1 事前準備

- **AWS CLI v2** をインストールし、認証情報を設定する
- 設定を確認する:

```bash
aws sts get-caller-identity   # アカウントID・ユーザーID・ARN が返れば OK
```

- **CDK の bootstrap**(アカウント × リージョンごとに 1 回だけ):

```bash
npx cdk bootstrap aws://ACCOUNT_ID/REGION
# 例:
npx cdk bootstrap aws://123456789012/us-east-1
```

AWS Blocks は内部で **AWS CDK** を使ってインフラをデプロイするため、最初の 1 回だけ bootstrap が要ります。

### 7.2 サンドボックスへデプロイ（おすすめ）

まずは使い捨ての **サンドボックス** で試します。開発者ごとに分離された環境に、Lambda のホットスワップで素早くデプロイされます。

```bash
npm run sandbox            # 高速・一時的なバックエンドを AWS に作成
```

実 AWS サービスを使った挙動を確認できます。終わったら必ず後片付けします。

```bash
npm run sandbox:destroy    # サンドボックスのリソースを全削除
```

### 7.3 本番（ステージング/プロダクション）へデプロイ

```bash
npm run deploy             # CDK(CloudFormation)経由でアプリ全体をデプロイ
```

ここで初めて、`DistributedTable` が実際の **DynamoDB テーブル** に、`AuthBasic` が **DynamoDB のユーザーテーブル** に、バックエンドコードが **Lambda** になります。**コードは 6 章までで書いたものから一切変えていません。**

> ⚠️ コスト注意: デプロイ後は使った AWS サービス分の料金が発生します。検証が終わったらサンドボックスは `sandbox:destroy` で、本番スタックは不要なら削除しておきましょう。

> 出典: [AWS Blocks Developer Guide (PDF)](https://docs.aws.amazon.com/pdfs/blocks/latest/devguide/blocks-dg.pdf)

---

## 8. なぜコード無変更でデプロイできるのか（おさらい）

ここまでで、**同じコードがローカルでも AWS でも動いた** はずです。これを支えているのが **Node.js の Conditional Exports** です。同じ `import` が、実行コンテキストによって違う実装に解決されます。

| コンテキスト | 解決先 | 例: `new DistributedTable(...)` |
| --- | --- | --- |
| ローカル開発(`npm run dev`) | ローカル実装 | インメモリのストア |
| デプロイ(CDK 合成) | CDK construct | DynamoDB テーブルの CloudFormation 定義 |
| 本番ランタイム(Lambda) | AWS SDK 連携 | DynamoDB への SDK 呼び出し |

だから「ローカルで動いたものを、無変更でそのまま AWS へ」が成立します。

> 出典: [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html)

---

## 9. つまずきポイントと注意

ハンズオン中・この先でハマりやすい点をまとめます。

- **Block ID は「不変」だと思って扱う**: コンストラクタ第 2 引数(例: `'todos'`)を **リネームすると、次回デプロイで対応する AWS リソースが削除→再作成** されます。`KVStore` / `DistributedTable` / `Database` / `FileBucket` のような **状態を持つ Block ではデータが永久に失われます**。一度デプロイした ID は変えないこと。
- **Block を増やしすぎない**: 各 Block は AWS リソースに対応します。データ型ごとにストアを乱立させず、**1 つのストアをキープレフィックスで分割** します（テーブル乱立はコスト増）。
- **データはユーザースコープで分離**: パーティションキーにユーザー ID を使い、認証済みユーザーが他人のデータにアクセスできないようにします（6 章の `deleteCompleted` が `userId`/`username` で絞っていたのもこのため）。
- **ローカルと実 AWS の挙動差**: ローカル実装は高速・決定的ですが、実 AWS と完全一致ではありません。重要なパスはサンドボックスで実環境検証しましょう。

> 出典: [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html) / [Best practices](https://docs.aws.amazon.com/blocks/latest/devguide/best-practices.html)

---

## 10. 次のステップ

- **他の Block を足す**: ファイルアップロード(`FileBucket` → S3）、リアルタイム(`Realtime` → WebSocket）、AI（`Agent` / `KnowledgeBase` → Bedrock）など。すべて同じ「import して `new` する」パターンです。
- **既存リソースとつなぐ**: `fromExisting`、独自 Block、`vendorize`、素の CDK の 4 パターンで段階的に統合できます。
- **CDK に降りる**: 細かい制御が必要になったら `aws-blocks/index.cdk.ts`(CDK レイヤー)で任意の CDK construct を足せます。

## まとめ

このハンズオンでは、

1. `npm create ... --template demo` → `npm run dev` でローカル起動し、
2. IFC レイヤーの Block 定義（Zod スキーマ）と `ApiNamespace` を読み、
3. `deleteCompleted` を追加してフロントから型安全に呼び、
4. （任意で）サンドボックス/本番へ無変更デプロイし、
5. Conditional Exports の仕組みを確認しました。

「インフラを学ばずにまず動かす。必要になったら CDK に降りる」という AWS Blocks の体験を、最短ルートでなぞれたはずです。Preview のうちに小さく触って、感触を確かめてみてください。

## 参考リンク

- [Getting started with AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/getting-started.html)
- [AWS Blocks concepts](https://docs.aws.amazon.com/blocks/latest/devguide/concepts.html)
- [Best practices for AWS Blocks](https://docs.aws.amazon.com/blocks/latest/devguide/best-practices.html)
- [AWS Blocks Developer Guide (PDF)](https://docs.aws.amazon.com/pdfs/blocks/latest/devguide/blocks-dg.pdf)
- [AWS Blocks 製品ページ](https://aws.amazon.com/jp/products/developer-tools/blocks/)
- [GitHub: aws-devtools-labs/aws-blocks](https://github.com/aws-devtools-labs/aws-blocks)

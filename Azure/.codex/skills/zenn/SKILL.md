---
name: zenn
description: Zenn 記事を概要提案、構成案、本文作成の順で作るスキル。Azure や開発技術の記事を、Tavily や Microsoft Learn で根拠を確認しながら `zenn/plan/` と `zenn/publish/` に Markdown として作成・更新するときに使う。
---

# Zenn

## 基本方針

- 既存知識だけで技術記事を書かない。
- 外部情報が必要なら `microsoft-learn` または `use-tavily` で根拠を集める。
- 記事は 概要提案 -> `zenn/plan/*.md` -> `zenn/publish/*.md` の順で作る。
- ユーザーが明示しない限り `published: true` にしない。

## 配置

- 構成案: `zenn/plan/*.md`
- 本文: `zenn/publish/*.md`
- 調査結果: `temp/web/*.json` または `temp/mslearn_mcp/*.md`

## Frontmatter

`zenn/publish` の Markdown には最低限これを付ける。

```yaml
---
title: "<記事タイトル>"
emoji: "📝"
type: "tech"
topics: ["azure", "bicep", "terraform"]
published: false
---
```

`zenn/plan` は簡易 frontmatter にする。

```yaml
---
title: "<記事タイトル>"
status: plan
---
```

## 概要提案

提案には以下を含める。

- タイトル案 2 から 4 個
- 想定読者
- 記事で答える問い
- 扱う範囲と扱わない範囲
- 根拠にした URL または調査ファイル

## 構成案

`zenn/plan/{topic_slug}.md` に以下を書く。

- 仮タイトル
- 導入で解決する問題
- セクション一覧
- 各セクションで述べる主張
- 各セクションの根拠 URL
- 不足情報と追加調査ポイント

## 本文作成

- 構成案に沿って `zenn/publish/{topic_slug}.md` を作る。
- セクションごとに根拠 URL を持たせる。
- 「向いていないケース」「制約」「設計上の注意点」を落とさない。
- SKU、preview、リージョン、日付依存など変動要素があれば明記する。

## 更新ルール

- セクション追加、削除、並べ替え、主張変更は先に `zenn/plan` を更新し、その後 `zenn/publish` に反映する。
- 語尾や表現など軽微な修正は `zenn/publish` を直接更新してよい。
- publish の編集で見出し構成や主張が変わった場合は、同じターンで plan も同期する。

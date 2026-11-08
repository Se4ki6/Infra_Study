---
name: use-tavily
description: Tavily の検索、抽出、サイトマップ、クロール、Research API を、このリポジトリの固定プリセット付き Python ラッパーで使うためのスキル。一般 Web 調査、Zenn 記事の根拠収集、公式以外も含む複数サイト横断調査が必要なときに使う。
---

# Use Tavily

## 前提

- `TAVILY_API_KEY` を環境変数、または `.codex/skills/use-tavily/.env` に設定する。
- 依存関係は `pip install tavily-python python-dotenv` を基本にする。既存環境で `tavily` パッケージ名を使っている場合は、その環境に合わせる。
- スクリプトは `.codex/skills/use-tavily/scripts/` 配下にある。

## 判断フロー

```text
1. 対象 URL が分かっている -> extract_url_content.py
2. 対象サイトのルート URL が分かっている
   - URL 一覧とタイトルを見る -> map_site_titles.py
   - サイト本文をまとめて回収 -> crawl_site_content.py
   - map 後に候補 URL を抽出 -> map_extract_site_content.py
3. topic / question / keyword だけがある
   - 関連 URL と要約を見る -> search_topic.py
   - 関連 URL の本文まで取る -> search_extract_topic.py
   - AI 調査レポートを作る -> research_topic.py
```

## 実行例

```powershell
python .\.codex\skills\use-tavily\scripts\search_topic.py "Azure API Management policy expressions" --detail balanced --include-domain learn.microsoft.com --output temp\web\search_apim_policy_expressions.json
```

```powershell
python .\.codex\skills\use-tavily\scripts\extract_url_content.py https://learn.microsoft.com/azure/api-management/api-management-policies --query "policy capabilities and limitations" --detail balanced --output temp\web\extract_apim_policies.json
```

## 運用ルール

- 何を確認するための調査かを 1 文で明確にしてから実行する。
- Microsoft / Azure 公式 Docs だけで足りる場合は `microsoft-learn` スキルを優先する。
- 出力ファイルは基本的に `temp/web/` に置く。
- `topic_slug` は英数字と `_` の短い名前にする。
- 追加検索は、不足している論点を明確に言える場合だけ行う。
- 公式ソースがある場合は非公式ブログだけで断定しない。

## 出力ファイル名

- `temp/web/search_{topic_slug}.json`
- `temp/web/search_extract_{topic_slug}.json`
- `temp/web/research_{topic_slug}.json`
- `temp/web/extract_{topic_slug}.json`
- `temp/web/site_map_{topic_slug}.json`
- `temp/web/site_extract_{topic_slug}.json`
- `temp/web/site_crawl_{topic_slug}.json`

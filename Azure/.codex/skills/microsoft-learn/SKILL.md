---
name: microsoft-learn
description: Microsoft Learn MCP サーバーを CLI ラッパー経由で使い、Azure、Microsoft、.NET、M365 の公式ドキュメントや公式コードサンプルを検索・取得するスキル。Azure リソース種別、Bicep apiVersion、公式手順、制約、コード例を一次情報で確認したいときに使う。
---

# Microsoft Learn

## エントリポイント

インストール済みなら:

```powershell
mslmcp --help
```

未インストールなら:

```powershell
python .\.codex\skills\microsoft-learn\scripts\mslmcp_cli.py --help
```

## 判断フロー

```text
1. 対象ページ URL が分かっている -> mslmcp fetch <url>
2. コードサンプルが欲しい -> mslmcp code-search "<query>" --language <lang>
3. 公式説明、手順、制約が欲しい -> mslmcp search "<query>"
4. search の抜粋で足りない -> 結果の contentUrl を fetch する
5. サーバー側ツールの変更を確認したい -> mslmcp tools
```

## 実行例

```powershell
python .\.codex\skills\microsoft-learn\scripts\mslmcp_cli.py search "Microsoft.Storage storageAccounts Bicep apiVersion"
```

```powershell
python .\.codex\skills\microsoft-learn\scripts\mslmcp_cli.py fetch https://learn.microsoft.com/azure/templates/microsoft.storage/storageaccounts
```

## 使い分け

- Microsoft / Azure / .NET / M365 の公式情報は、このスキルを優先する。
- 複数サイト横断、非 Microsoft 情報、AI 要約付きの広い調査は `use-tavily` を使う。
- Bicep の apiVersion やリソース種別は、記憶で断定せず公式 Docs を確認する。

## 出力

- `search` / `code-search` は標準出力に結果を出す。
- `fetch` は既定で `temp/mslearn_mcp/` に Markdown を書き、標準出力にはファイルパスだけを出す。
- `--json` を付けると JSON を標準出力に出し、ファイルには書かない。

# .gitignore Tips - フォルダを残しつつ中身を無視する方法

## 概要

Git では空のフォルダは追跡されません。そのため、フォルダ構造を維持したい場合は`.gitkeep`などのダミーファイルを配置します。しかし、そのフォルダ内に追加されるファイル（画像など）は無視したいケースがあります。

## ユースケース

- `images/`フォルダの構造は残したい
- `.gitkeep`でフォルダを追跡する
- 実際の画像ファイルは Git で管理しない（サイズが大きい、機密性があるなど）

## 解決方法

`.gitignore`に以下のパターンを追加します：

```gitignore
# フォルダ内のすべてのファイルを無視
upload_file/images/*

# .gitkeepだけは例外として追跡
!upload_file/images/.gitkeep
```

## パターンの解説

| パターン           | 意味                                             |
| ------------------ | ------------------------------------------------ |
| `folder/*`         | フォルダ内のすべてのファイル・サブフォルダを無視 |
| `!folder/.gitkeep` | `.gitkeep`は例外として追跡する（`!`は否定）      |

## 重要なポイント

### 1. 順番が重要

```gitignore
# ✅ 正しい順番
upload_file/images/*
!upload_file/images/.gitkeep

# ❌ 間違った順番（例外が先だと機能しない）
!upload_file/images/.gitkeep
upload_file/images/*
```

### 2. `*` vs `**` の違い

| パターン    | 対象                                      |
| ----------- | ----------------------------------------- |
| `images/*`  | `images/`直下のファイルのみ               |
| `images/**` | `images/`以下のすべて（サブフォルダ含む） |

### 3. フォルダ全体を無視する場合との違い

```gitignore
# フォルダ全体を無視（.gitkeepも含めて全部無視される）
upload_file/images/

# フォルダ内のファイルを無視（フォルダ自体は残る）
upload_file/images/*
```

## 応用例

### 複数の拡張子のみを無視

```gitignore
# 画像ファイルのみ無視
upload_file/images/*.png
upload_file/images/*.jpg
upload_file/images/*.gif
upload_file/images/*.webp
```

### 特定の拡張子以外を無視

```gitignore
# すべて無視
upload_file/images/*

# .gitkeepと.mdファイルは追跡
!upload_file/images/.gitkeep
!upload_file/images/*.md
```

### ネストしたフォルダでも.gitkeep を追跡

```gitignore
# images以下のすべてを無視
upload_file/images/**

# すべての.gitkeepは追跡
!upload_file/images/**/.gitkeep
```

## 確認方法

設定が正しく機能しているか確認するには：

```bash
# 無視されているファイルを確認
git status --ignored

# 特定のファイルが無視されるか確認
git check-ignore -v upload_file/images/sample.png
```

## 参考リンク

- [Git 公式ドキュメント - gitignore](https://git-scm.com/docs/gitignore)

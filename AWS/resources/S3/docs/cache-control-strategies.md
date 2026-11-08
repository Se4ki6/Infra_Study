# HTTP キャッシュ制御戦略: must-revalidate と immutable

最終更新: 2025-11-29

## 概要

HTTP の Cache-Control ヘッダーは、ブラウザや CDN がコンテンツをどのようにキャッシュするかを制御します。`must-revalidate`と`immutable`は、それぞれ異なるユースケースに最適化されたディレクティブです。

## Cache-Control の基本

```
Cache-Control: max-age=3600, must-revalidate
Cache-Control: max-age=31536000, immutable
```

### 主要なディレクティブ

| ディレクティブ    | 説明                           | 値                     |
| ----------------- | ------------------------------ | ---------------------- |
| `max-age`         | キャッシュの有効期限（秒）     | 数値（例: 300 = 5 分） |
| `must-revalidate` | 期限切れ後は必ずサーバーに確認 | フラグ                 |
| `immutable`       | コンテンツは絶対に変更されない | フラグ                 |
| `no-cache`        | 毎回サーバーに確認が必要       | フラグ                 |
| `no-store`        | キャッシュしない               | フラグ                 |

## must-revalidate

### 特徴

- キャッシュが**期限切れになった後**、必ずオリジンサーバーに確認してから使用
- 新鮮な間はサーバーに問い合わせない（効率的）
- 期限後は必ず検証する（正確性）

### 動作フロー

```
[ユーザー] → [ブラウザキャッシュ] → [サーバー]

1. 初回アクセス:
   サーバーからダウンロード
   Cache-Control: max-age=300, must-revalidate

2. 5分以内の再アクセス:
   キャッシュから直接表示（サーバーアクセスなし）
   ⚡ 高速

3. 5分経過後の再アクセス:
   サーバーに確認リクエスト（If-None-Match/If-Modified-Since）

   a) 変更なし → 304 Not Modified
      既存キャッシュを再利用

   b) 変更あり → 200 OK
      新しいコンテンツをダウンロード
```

### 使用例

```terraform
cache_control = "max-age=300, must-revalidate"
```

**適用場面:**

- HTML ファイル（コンテンツが更新される可能性がある）
- API レスポンス（データが変わる可能性がある）
- 動的に生成されるコンテンツ

**メリット:**

- ある程度キャッシュして効率化
- でも古いコンテンツを表示し続けない
- 304 応答でネットワーク転送量を削減

## immutable

### 特徴

- コンテンツが**絶対に変更されない**ことを保証
- ブラウザは期限内に**一切の確認をしない**
- 最も攻撃的なキャッシュ戦略

### 動作フロー

```
[ユーザー] → [ブラウザキャッシュ]

1. 初回アクセス:
   サーバーからダウンロード
   Cache-Control: max-age=31536000, immutable

2. 1年以内の再アクセス:
   キャッシュから直接表示
   ⚡⚡⚡ 超高速（ネットワークアクセスゼロ）

   - リロード時もサーバーに問い合わせない
   - If-Modified-Sinceヘッダーも送信しない
```

### 使用例

```terraform
cache_control = "max-age=31536000, immutable"
```

**適用場面:**

- バージョンハッシュ付きファイル
  - `app.a1b2c3d4.js`
  - `style.xyz123.css`
  - `logo.abc789.png`
- フォントファイル（通常変更されない）
- 静的アセット（ビルド時にハッシュ生成）

**前提条件:**

- ファイル名にハッシュやバージョンを含める
- 内容が変わったら必ずファイル名も変わる
- 古いファイルは参照されなくなる

**メリット:**

- 最高のパフォーマンス
- ネットワークリクエストゼロ
- ユーザー体験の向上

## 比較表

| 項目             | must-revalidate          | immutable                        |
| ---------------- | ------------------------ | -------------------------------- |
| **期限内の動作** | キャッシュ使用           | キャッシュ使用                   |
| **期限後の動作** | サーバーに確認必須       | （通常は期限が長いため該当せず） |
| **リロード時**   | 確認リクエスト送信       | 確認しない（immutable を尊重）   |
| **推奨 max-age** | 短〜中期（300〜3600 秒） | 長期（31536000 秒 = 1 年）       |
| **更新頻度**     | 変更される可能性あり     | 絶対に変更されない               |
| **用途**         | HTML, API                | バージョン付きアセット           |
| **ネットワーク** | 期限後に 304 応答        | ほぼゼロ                         |

## 実践的な設定例

### Terraform（S3 + CloudFront）

```terraform
resource "aws_s3_object" "upload_file" {
  for_each = fileset(var.upload_folder, "**")

  bucket = aws_s3_bucket.example.id
  key    = each.value
  source = "${var.upload_folder}/${each.value}"

  # Content-Type自動判定
  content_type = lookup(local.content_types,
    lower(split(".", each.value)[length(split(".", each.value)) - 1]),
    "application/octet-stream")

  # Cache-Control自動設定
  cache_control = lookup({
    # 動的コンテンツ: 短いキャッシュ + 再検証
    "html" = "max-age=300, must-revalidate",
    "htm"  = "max-age=300, must-revalidate",

    # 静的アセット: 長いキャッシュ + immutable
    "css"   = "max-age=31536000, immutable",
    "js"    = "max-age=31536000, immutable",
    "png"   = "max-age=31536000, immutable",
    "jpg"   = "max-age=31536000, immutable",
    "woff2" = "max-age=31536000, immutable",

    # データファイル: 中程度のキャッシュ
    "json" = "max-age=3600, must-revalidate",
    "xml"  = "max-age=3600, must-revalidate"
  }, lower(split(".", each.value)[length(split(".", each.value)) - 1]),
     "max-age=86400") # デフォルト: 1日
}
```

### Nginx での設定例

```nginx
# HTML: 短いキャッシュ
location ~* \.html?$ {
    add_header Cache-Control "max-age=300, must-revalidate";
}

# CSS/JS: 長いキャッシュ（ハッシュ付き想定）
location ~* \.(css|js)$ {
    add_header Cache-Control "max-age=31536000, immutable";
}

# 画像: 長いキャッシュ
location ~* \.(png|jpg|jpeg|gif|svg|webp)$ {
    add_header Cache-Control "max-age=31536000, immutable";
}
```

### Apache (.htaccess)

```apache
# HTML
<FilesMatch "\.(html|htm)$">
    Header set Cache-Control "max-age=300, must-revalidate"
</FilesMatch>

# CSS/JS
<FilesMatch "\.(css|js)$">
    Header set Cache-Control "max-age=31536000, immutable"
</FilesMatch>

# 画像
<FilesMatch "\.(png|jpg|jpeg|gif|svg|webp)$">
    Header set Cache-Control "max-age=31536000, immutable"
</FilesMatch>
```

## ベストプラクティス

### 1. コンテンツタイプ別の戦略

```
HTML/PHP/動的コンテンツ:
  → max-age=300, must-revalidate（5分）

CSS/JS（ビルドツール使用）:
  → max-age=31536000, immutable（1年）
  → ファイル名: app.[hash].js

画像（変更されない）:
  → max-age=31536000, immutable（1年）

API/データ:
  → max-age=60, must-revalidate（1分）
  または no-cache（常に確認）

ユーザー固有データ:
  → no-store（キャッシュしない）
```

### 2. ビルドプロセスとの統合

```javascript
// Webpack設定例
module.exports = {
  output: {
    filename: "[name].[contenthash].js",
    // contenthash: ファイル内容からハッシュ生成
  },
};
```

これにより：

- `app.js` → `app.a1b2c3d4.js`
- 内容が変わると → `app.x9y8z7w6.js`（新しいファイル）
- `immutable`で安全に長期キャッシュ可能

### 3. CloudFront との組み合わせ

```terraform
resource "aws_cloudfront_distribution" "s3_distribution" {
  # S3オリジンの設定
  origin {
    domain_name = aws_s3_bucket.example.bucket_regional_domain_name
    origin_id   = "S3-origin"
  }

  # オリジンのCache-Controlを尊重
  default_cache_behavior {
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # Managed-CachingOptimized
    # S3のCache-Controlヘッダーを尊重
  }
}
```

### 4. 開発環境での注意点

開発中は強いキャッシュが邪魔になるため：

```terraform
cache_control = var.environment == "production" ?
  "max-age=31536000, immutable" :
  "max-age=0, no-cache"
```

## トラブルシューティング

### 問題: 更新しても古いコンテンツが表示される

**原因:** `immutable`を動的コンテンツに使用している

**解決策:**

```terraform
# 悪い例
cache_control = "max-age=31536000, immutable" # HTMLに使うのはNG

# 良い例
cache_control = "max-age=300, must-revalidate" # HTMLは短く
```

### 問題: 毎回サーバーにアクセスして遅い

**原因:** キャッシュ期間が短すぎる

**解決策:**

```terraform
# 悪い例
cache_control = "no-cache" # 毎回確認

# 良い例（ハッシュ付きファイルの場合）
cache_control = "max-age=31536000, immutable"
```

### 問題: immutable が効かない

**原因:** 古いブラウザは`immutable`を認識しない

**解決策:**

- `immutable`は比較的新しいディレクティブ（2017 年）
- 認識しないブラウザは無視して`max-age`のみ使用
- 問題なし（graceful degradation）

## 検証方法

### ブラウザ DevTools で確認

```
1. F12でDevToolsを開く
2. Networkタブ
3. ファイルをクリック
4. Response Headersを確認

Cache-Control: max-age=31536000, immutable
```

### curl コマンドで確認

```bash
# ヘッダーのみ確認
curl -I https://example.com/app.js

# 詳細表示
curl -v https://example.com/app.js
```

### キャッシュ動作のテスト

```bash
# 1回目（キャッシュなし）
curl -w "\nTime: %{time_total}s\n" https://example.com/app.js

# 2回目（キャッシュあり）
curl -w "\nTime: %{time_total}s\n" https://example.com/app.js

# 期限後のリクエスト（If-Modified-Since付き）
curl -H "If-Modified-Since: Wed, 29 Nov 2025 12:00:00 GMT" \
     https://example.com/index.html
```

## 関連リソース

- [MDN - Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [RFC 7234 - HTTP Caching](https://tools.ietf.org/html/rfc7234)
- [immutable ディレクティブの提案](https://datatracker.ietf.org/doc/html/rfc8246)
- [AWS CloudFront キャッシュポリシー](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-the-cache-key.html)
- [Terraform aws_s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)

## よくある質問 (FAQ)

### Q1: immutable で変更されないなら、なぜ max-age=1 年も必要なの？キャッシュ不要では？

**A: 逆です。変更されないからこそ、長期間キャッシュする意味があります。**

#### 誤解しやすいポイント

❌ 「変更されない」= キャッシュ不要<br>
⭕ 「変更されない」= 長期間キャッシュできる（最高のパフォーマンス）

#### キャッシュの本質

キャッシュとは**ブラウザのローカルストレージにファイルを保存する**こと：

```
キャッシュなし:
  訪問のたびにサーバーからダウンロード (500KB × 100回 = 50MB転送)

max-age=31536000 (1年):
  最初の1回だけダウンロード (500KB × 1回 = 500KB転送)
  → 49.5MB削減！⚡
```

#### なぜ 1 年なのか

1. **ブラウザに「重要なファイル、長く保持して」と指示**

   - キャッシュ容量は有限
   - 期限が短いと、すぐ削除される可能性

2. **ネットワークアクセスをゼロにする**

   - 期限内は確認もダウンロードもしない
   - 完全にローカルから読み込み = 超高速

3. **immutable の真の意味**
   - 「このファイルは絶対に変わらない」
   - 「だから期限まで一切サーバーに問い合わせるな」
   - 期限が長い = より多くのアクセスを高速化

#### ファイルが更新されたら？

ファイル名にハッシュを付けることで解決：

```
旧バージョン: app.abc123.js  ← 1年キャッシュされたまま（OK）
新バージョン: app.xyz789.js  ← 別ファイルとして新規ダウンロード

HTML更新:
  <script src="app.abc123.js"></script>  // 旧
  ↓
  <script src="app.xyz789.js"></script>  // 新（別ファイル扱い）
```

### Q2: 1 年後（キャッシュ期限切れ）になったらどうなるの？

**A: 通常は問題なし。すでに新バージョンに移行しているか、効率的に再検証されます。**

#### シナリオ 1: 通常のケース（新バージョンに移行済み）⭐

```
2025年11月29日: app.abc123.js をキャッシュ（1年間有効）

2025年12月1日:  新バージョンリリース
                HTML更新 → <script src="app.xyz789.js"></script>
                ユーザー訪問時:
                - HTMLを再取得（5分キャッシュなので更新される）
                - app.xyz789.js を新規ダウンロード
                - app.abc123.js はもう参照されない

2026年11月29日: app.abc123.js のキャッシュ期限切れ
                でも誰も使ってない！
                ブラウザが自動削除（問題なし）
```

**ポイント:** 静的アセットは通常、数週間〜数ヶ月で更新されるため、1 年も同じファイルを使い続けることは稀。

#### シナリオ 2: まだ同じファイルを使っている場合（レアケース）

```
2026年11月29日: キャッシュ期限切れ
                ユーザーがページ訪問
                ↓
ブラウザ:「期限切れだ、サーバーに確認しよう」
                ↓
サーバーに条件付きリクエスト:
  GET /app.abc123.js HTTP/1.1
  If-None-Match: "etag-abc123"
  If-Modified-Since: Fri, 29 Nov 2025 00:00:00 GMT
                ↓
サーバーの応答:

  a) ファイル変更なし（通常）:
     304 Not Modified
     → ブラウザは既存キャッシュを再利用
     → max-ageがリセット（また1年有効）
     → 転送量: ヘッダーのみ（数百バイト）

  b) ファイル変更あり（稀）:
     200 OK + 新しいファイル
     → ダウンロード
```

#### データ転送の比較

```
1年間の運用（365回アクセス）:

キャッシュなし:
  500KB × 365回 = 182.5MB転送

max-age=3600（1時間）:
  500KB × 8,760回 = 4.2GB転送

max-age=31536000（1年） + immutable:
  初回: 500KB
  1年後: 304応答（数百バイト）
  合計: 約500KB ⚡⚡⚡
```

#### ブラウザのキャッシュ管理

ブラウザは賢く動作：

```
✓ キャッシュ容量がいっぱい
  → 古いファイルや使われてないファイルを自動削除

✓ 期限切れ + 最近使われてない
  → 次回クリーンアップで削除

✓ 期限切れ + まだ使われている
  → サーバーに確認 → 304なら再利用
```

#### 実運用のタイムライン例

```
Day 0:   v1リリース → ユーザーAがキャッシュ（1年）
Day 30:  v2リリース → 新規ユーザーBはv2をキャッシュ
         ユーザーAが再訪問:
         - HTML再取得（5分経過済）→ v2を参照
         - v2をダウンロード & キャッシュ
         - v1はもう使われない

Day 60:  v3リリース...

Day 365: v1のキャッシュ期限切れ
         → でも誰も使ってないので問題なし
         → ブラウザが勝手に削除
```

### Q3: 本当に 1 年も同じファイルを使い続けることはあるの？

**A: 実際にはほぼありません。これがベストプラクティスが成立する理由です。**

#### 現実的な更新サイクル

```
Webアプリケーション:
  → 週〜月単位でデプロイ
  → 1年間同じJSファイルはあり得ない

企業サイト:
  → 月〜四半期単位で更新
  → ロゴやフォントも時々変わる

ランディングページ:
  → キャンペーンごとに更新（数週間〜数ヶ月）
```

#### max-age=1 年の真の意味

「本当に 1 年キャッシュする」ではなく：

```
「このファイルは変更されないから、
 ブラウザさん、あなたの判断で好きなだけキャッシュしてOK。
 ただし、もし期限切れになったら確認してね。」
```

#### ベストプラクティスが機能する理由

1. **ファイル名にハッシュ** → 内容が変われば別ファイル
2. **HTML は短いキャッシュ** → すぐに最新の参照に更新
3. **実際の更新は頻繁** → 1 年持つことは稀
4. **期限切れ後も安全** → 304 応答で効率的

結論: `max-age=31536000, immutable`は理論上も実運用上も最適な戦略！

## まとめ

- **must-revalidate**: 期限後は必ず確認 → **動的コンテンツ**に最適
- **immutable**: 絶対に変更されない → **バージョン付きアセット**に最適
- **max-age=1 年**: ネットワーク転送を最小化、最高のパフォーマンス
- **期限切れ後**: 通常は新バージョンに移行済み、問題なし
- 適切な使い分けで**パフォーマンスとフレッシュさ**を両立
- ビルドツールと組み合わせることで真価を発揮

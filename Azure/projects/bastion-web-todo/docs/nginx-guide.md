# NGINX 入門メモ

このドキュメントは、今回の `bastion-web-todo` 構成で使っている NGINX を理解するための初心者向けメモです。

NGINX 公式ドキュメントを Tavily で調査し、今回の TODO アプリ構成に必要な範囲へ絞って整理しています。

## NGINX とは

NGINX は Web サーバーです。ブラウザや curl などのクライアントから HTTP リクエストを受け取り、HTML、CSS、JavaScript、画像などのファイルを返します。

今回の構成では、Web VM 上で NGINX を動かし、TODO アプリの `index.html` を配信しています。

```text
Browser
  |
  | HTTP request
  v
NGINX
  |
  | reads file
  v
/var/www/html/index.html
```

今回の TODO アプリは、サーバー側で Node.js や Python のアプリケーションプロセスを起動しているわけではありません。HTML の中に CSS と JavaScript を含めた静的ファイルを NGINX が返しているだけです。

## 今回 NGINX が担当していること

今回の Web VM で NGINX が担当しているのは、主に次の 3 つです。

- HTTP の 80 番ポートでリクエストを受ける
- `/var/www/html/index.html` を返す
- VM 起動後に自動でサービスとして動き続ける

逆に、今回 NGINX が担当していないこともあります。

- TODO データをサーバーに保存すること
- ログイン機能
- API 処理
- データベース接続
- HTTPS 終端
- 複数サーバーへのロードバランシング

TODO のデータはブラウザの `localStorage` に保存されます。つまり、別のブラウザや別の PC で開くと TODO データは共有されません。

## なぜ NGINX を使うのか

今回の用途では、NGINX を使う理由はシンプルです。

- 静的ファイルを配信する用途に向いている
- Ubuntu で簡単にインストールできる
- `systemctl` でサービス管理できる
- 将来、リバースプロキシや HTTPS に拡張しやすい

学習用の TODO アプリなら Python の簡易 HTTP サーバーでも表示できます。ただし、VM 上に常設する Web サーバーとしては NGINX のほうが一般的です。

## NGINX の基本構成

NGINX は、設定ファイルを読んで動きます。公式の Beginner's Guide では、NGINX は設定を読む master process と、実際にリクエストを処理する worker process で動くと説明されています。

Ubuntu に `apt` で NGINX を入れた場合、よく見るファイルやディレクトリは次のあたりです。

```text
/etc/nginx/nginx.conf
/etc/nginx/sites-available/default
/etc/nginx/sites-enabled/default
/var/www/html/index.html
/var/log/nginx/access.log
/var/log/nginx/error.log
```

今回の cloud-init では、NGINX の設定ファイルは直接変更していません。Ubuntu の NGINX パッケージが持つデフォルト設定を使い、デフォルトの公開ディレクトリに `index.html` を置いています。

```text
/var/www/html/index.html
```

これだけで、既定の NGINX 設定から `http://<server>/` へのアクセスに対して `index.html` が返されます。

## cloud-init でやっていること

今回の Bicep では、Web VM に `cloud-init/web-todo.yaml` を渡しています。

```bicep
customData: base64(loadTextContent('cloud-init/web-todo.yaml'))
```

この cloud-init で、Web VM 初回起動時に NGINX をインストールして、TODO アプリを配置しています。

```yaml
package_update: true
packages:
  - nginx
```

これはパッケージ一覧を更新し、`nginx` パッケージをインストールする指定です。

次に、TODO アプリの HTML を配置しています。

```yaml
write_files:
  - path: /var/www/html/index.html
```

最後に、NGINX をサービスとして有効化し、起動しています。

```yaml
runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
```

`systemctl enable nginx` は、VM 再起動後も NGINX が自動起動するようにするコマンドです。

`systemctl restart nginx` は、NGINX を起動または再起動するコマンドです。

## NGINX の設定ファイルの考え方

NGINX の設定は、ディレクティブとブロックで書きます。

代表的な形は次です。

```nginx
server {
    listen 80;

    location / {
        root /var/www/html;
        index index.html;
    }
}
```

`server` は仮想サーバーの単位です。どのポートで待ち受けるか、どのドメイン名に反応するか、といった設定を書きます。

`listen 80;` は HTTP の 80 番ポートで待ち受けるという意味です。

`location /` は、リクエストされた URL パスに対して、どの処理をするかを決めるブロックです。`/` は基本的に全てのパスにマッチします。

`root /var/www/html;` は、ファイルを探す起点ディレクトリです。たとえば `/about.html` へアクセスされた場合、NGINX は `/var/www/html/about.html` を探します。

`index index.html;` は、ディレクトリにアクセスされたときに返す既定ファイルです。`/` へアクセスされたとき、NGINX は `/var/www/html/index.html` を返そうとします。

## root と index のイメージ

NGINX の静的配信で最初に理解するべきなのは、`root` と `index` です。

```nginx
location / {
    root /var/www/html;
    index index.html;
}
```

この場合、リクエストとファイルの対応は次のようになります。

```text
Request URI        File path
/                  /var/www/html/index.html
/index.html        /var/www/html/index.html
/app.js            /var/www/html/app.js
/css/style.css     /var/www/html/css/style.css
```

公式ドキュメントでは、NGINX は `root` に指定したパスへリクエスト URI を足して、実際のファイルパスを作る、という考え方で説明されています。

今回の TODO アプリは `/var/www/html/index.html` だけを置いているため、基本的には `/` でそのファイルが返ります。

## 今回のネットワーク制限との関係

今回の Bicep では、Web VM の NGINX は 80 番ポートで待ち受けます。Web VM には Public IP があり、TODO アプリの HTTP アクセスに使います。

さらに、Web VM 側の NSG では HTTP 80 番ポートをインターネットから許可しています。SSH 22 番ポートは踏み台サブネットからだけ許可しています。

```text
Allowed:
Internet -> Web VM:80
Bastion subnet -> Web VM:22

Blocked:
Internet -> Web VM:22
```

そのため、手元のブラウザからは `http://<web-public-ip>` で TODO アプリを開けます。一方で、Web VM の Private IP である `10.10.2.10` は Azure VNet 内のアドレスなので、手元のブラウザから直接開いても通常は到達できません。

`http://<web-public-ip>` を開くと、通信は次のように流れます。

```text
Browser on local PC
  -> Web VM Public IP:80
  -> Web VM:80
  -> NGINX
  -> /var/www/html/index.html
```

つまり、NGINX は Web VM 内で普通に HTTP サーバーとして動いています。インターネット公開・非公開を決めているのは NGINX ではなく、Azure の Public IP と NSG です。

## よく使う確認コマンド

Web VM に SSH した後、NGINX の状態は次のコマンドで確認できます。

```bash
systemctl status nginx
```

起動する場合:

```bash
sudo systemctl start nginx
```

停止する場合:

```bash
sudo systemctl stop nginx
```

再起動する場合:

```bash
sudo systemctl restart nginx
```

設定ファイルを読み直す場合:

```bash
sudo systemctl reload nginx
```

NGINX の設定に文法エラーがないか確認する場合:

```bash
sudo nginx -t
```

`nginx -t` が成功してから `reload` するのが基本です。設定ミスがある状態で reload すると、意図した変更が反映されません。

## ログの見方

アクセスログ:

```bash
sudo tail -f /var/log/nginx/access.log
```

エラーログ:

```bash
sudo tail -f /var/log/nginx/error.log
```

`access.log` には、どの URL にアクセスされたか、HTTP ステータスコードが何だったかが記録されます。

`error.log` には、ファイルが見つからない、権限がない、設定に問題がある、といったエラーの手がかりが出ます。

## よくあるトラブル

### ブラウザで表示できない

まず、デプロイ output の `webPublicIpAddress` または `todoAppUrl` を使っているか確認します。Web VM の Private IP である `10.10.2.10` は、手元のブラウザから直接開くためのアドレスではありません。

次に、Web VM 側で NGINX が動いているか確認します。

```bash
systemctl status nginx
```

Web VM からローカルに curl して確認するのも有効です。

```bash
curl -I http://localhost/
```

HTTP `200 OK` が返れば、少なくとも NGINX 自体は応答しています。

### 404 Not Found になる

`/var/www/html/index.html` が存在するか確認します。

```bash
ls -l /var/www/html/index.html
```

存在しない場合は、cloud-init が途中で失敗した可能性があります。

cloud-init のログを確認します。

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

### 403 Forbidden になる

ファイルやディレクトリの権限が原因のことがあります。

```bash
ls -ld /var/www/html
ls -l /var/www/html
```

今回の cloud-init では `index.html` を `root:root`、権限 `0644` で作成しています。通常、この設定なら NGINX から読み取れます。

### 設定変更が反映されない

設定ファイルを変更しただけでは反映されません。文法確認してから reload します。

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## リバースプロキシとは

今回の TODO アプリでは使っていませんが、NGINX はリバースプロキシとしてもよく使われます。

リバースプロキシとは、クライアントからのリクエストを受け取り、別のアプリケーションサーバーへ転送し、その応答をクライアントに返す仕組みです。

```text
Browser
  -> NGINX
  -> App server
  -> NGINX
  -> Browser
```

設定例は次のような形です。

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

この場合、ブラウザは NGINX にアクセスしますが、実際のアプリケーション処理は `127.0.0.1:3000` で動いている別プロセスが担当します。

Node.js、Python、Ruby、Java などで作った Web アプリを NGINX の後ろに置くときによく使います。

## 今回の構成をリバースプロキシに変えるなら

今は静的 HTML を直接配信しています。

```text
NGINX -> /var/www/html/index.html
```

将来、Web VM 上で Node.js などの TODO API を動かすなら、次のような構成になります。

```text
Browser
  -> SSH tunnel
  -> Bastion VM
  -> Web VM:80
  -> NGINX
  -> Node.js app:3000
```

NGINX 設定は概念的には次のようになります。

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
```

この場合、NGINX は「静的ファイルを返すサーバー」ではなく「アプリケーションサーバーへの入口」として働きます。

## 初心者が最初に覚えるべき用語

| 用語 | 意味 |
| --- | --- |
| Web サーバー | HTTP リクエストを受けてレスポンスを返すサーバー |
| 静的ファイル | HTML、CSS、JavaScript、画像など、そのまま返せるファイル |
| root | NGINX がファイルを探す起点ディレクトリ |
| index | `/` のようなディレクトリアクセス時に返す既定ファイル |
| server block | 待ち受けポートやサーバー単位の設定 |
| location block | URL パスごとの処理設定 |
| reverse proxy | リクエストを別のサーバーやプロセスへ中継する仕組み |
| reload | NGINX を止めずに設定を読み直す操作 |

## 今回の理解ポイント

今回の構成で理解すべきポイントは次です。

1. NGINX は Web VM の中で動く HTTP サーバー
2. TODO アプリは `/var/www/html/index.html` として置かれている
3. NGINX はその HTML ファイルを 80 番ポートで返している
4. Web VM は HTTP 公開用の Public IP を持つ
5. NSG により、HTTP はインターネットから許可されている
6. SSH は踏み台サブネットからだけ許可されている

NGINX 自体はインターネット公開・非公開を決めているわけではありません。公開範囲は Azure の Public IP、Subnet、NSG が決めています。NGINX は Web VM 内で「HTTP を受けてファイルを返す」役割です。

## 参考にした公式ドキュメント

- [NGINX Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [Serve Static Content | NGINX Documentation](https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content)
- [NGINX Reverse Proxy | NGINX Documentation](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy)

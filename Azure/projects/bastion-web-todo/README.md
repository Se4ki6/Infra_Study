# Bastion + Public Web TODO App

Bicep で以下の構成を作成します。

- 踏み台 VM: Public IP あり。SSH は指定した送信元 IP/CIDR からのみ許可。
- Web VM: Public IP あり。HTTP はインターネットから許可、SSH は踏み台サブネットからのみ許可。
- TODO アプリ: Web VM の cloud-init で Nginx に静的 TODO アプリを配置。
- Auto-shutdown: 既定で 22:00 JST に両 VM を停止。

Bicep 初心者向けの実装解説は [docs/implementation-guide.md](docs/implementation-guide.md) を参照してください。
NGINX の役割を先に確認したい場合は [docs/nginx-guide.md](docs/nginx-guide.md) を参照してください。
デプロイ手順は [docs/deployment-guide.md](docs/deployment-guide.md) を参照してください。
動作確認観点は [docs/operation-check-guide.md](docs/operation-check-guide.md) を参照してください。

## 構成

```text
Internet
  |
  | SSH 22/tcp from allowedSshSourceAddressPrefix only
  v
Bastion VM (10.10.1.10, Public IP)
  |
  | SSH 22/tcp
  v
Web VM (10.10.2.10, Public IP)
  ^
  | HTTP 80/tcp from Internet
  |
Internet
```

Web VM は HTTP のみ外部公開します。SSH は Web VM に直接開けず、踏み台経由の SSH ProxyJump を使います。

## セキュリティリスク

この構成は学習用です。SSH の入口は絞っていますが、Web VM の HTTP 80 番はインターネットへ公開しています。

- HTTP は暗号化されません。入力内容やレスポンスは平文で流れるため、実運用では HTTPS 化が必要です。
- Web VM は Public IP を持つため、インターネット上のスキャンや攻撃対象になります。
- NSG は主に L3/L4、つまり IP アドレス、TCP/UDP、ポート番号で通信を制御します。HTTP の URL、ヘッダー、リクエスト本文など L7 の中身は検査しません。
- NGINX、OS、アプリに脆弱性がある場合、HTTP 経由で侵入される可能性があります。
- WAF、DDoS 対策、レート制限、監視、アラートはこの構成には含めていません。
- 既定の outbound 通信は広めです。Web VM が侵害された場合、外部通信に使われる余地があります。

実運用に近づける場合は、Web VM を直接公開せず、Application Gateway や Azure Front Door などを公開入口にして HTTPS と WAF を有効化する構成を検討します。

## デプロイ

詳細な手順は [docs/deployment-guide.md](docs/deployment-guide.md) を参照してください。以下は最短手順です。

```powershell
cd resource-project\bastion-web-todo\infra-bicep

$myIp = (Invoke-RestMethod 'https://api.ipify.org')
$allowedSsh = "$myIp/32"
$sshKey = Get-Content $HOME\.ssh\id_ed25519.pub -Raw

az deployment sub create `
  --location japaneast `
  --parameters .\main.bicepparam `
  --parameters sshPublicKey="$sshKey" allowedSshSourceAddressPrefix="$allowedSsh"
```

## 接続

詳しい動作確認観点は [docs/operation-check-guide.md](docs/operation-check-guide.md) を参照してください。

デプロイ後の output に接続コマンドが出ます。

踏み台へ SSH:

```powershell
ssh azureuser@<bastion-public-ip>
```

Web VM へ SSH:

```powershell
ssh -J azureuser@<bastion-public-ip> azureuser@10.10.2.10
```

手元のブラウザで TODO アプリを確認:

```text
http://<web-public-ip>
```

## 削除

```powershell
az group delete --name rg-todo-dev --yes
```

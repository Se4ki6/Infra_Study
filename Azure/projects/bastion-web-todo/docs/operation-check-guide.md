# 動作確認観点

このドキュメントは、`resource-project/bastion-web-todo` をデプロイした後に確認する観点をまとめたものです。

今回の構成で確認したいことは、単に VM が起動していることではありません。HTTP はインターネットから Web VM に届き、SSH は踏み台経由に絞られていることを確認します。

## 確認する構成

```text
Internet
  -> Web VM Public IP:80
  -> TODO app

Your PC
  -> Bastion VM Public IP:22
  -> Web VM Private IP:22

Internet
  -> Web VM Public IP:22
  -> Blocked
```

## 1. デプロイ結果を確認する

デプロイ結果の output で次の値を確認します。

- `resourceGroupName`: `rg-todo-dev`
- `bastionPublicIpAddress`: 踏み台 VM の Public IP
- `webPublicIpAddress`: Web VM の Public IP
- `todoAppUrl`: TODO アプリの URL
- `webPrivateIpAddress`: `10.10.2.10`
- `bastionSshCommand`: 踏み台 VM への SSH コマンド
- `webSshCommand`: 踏み台経由で Web VM に入る SSH コマンド

Azure CLI で後から確認する場合:

```powershell
az deployment sub show `
  --name main `
  --query properties.outputs
```

## 2. リソースが作成されていることを確認する

```powershell
az resource list `
  --resource-group rg-todo-dev `
  --output table
```

最低限、次のリソースがあることを確認します。

- `vm-todo-bas-dev`
- `vm-todo-web-dev`
- `pip-todo-bas-dev`
- `pip-todo-web-dev`
- `nsg-todo-bas-dev`
- `nsg-todo-web-dev`
- `vnet-todo-dev`

VM の状態を確認します。

```powershell
az vm list `
  --resource-group rg-todo-dev `
  --show-details `
  --output table
```

`PowerState/running` になっていれば起動中です。Auto-shutdown 後は `PowerState/deallocated` になることがあります。

## 3. TODO アプリへ HTTP 接続できることを確認する

ブラウザで `todoAppUrl` を開きます。

```text
http://<web-public-ip>
```

PowerShell で確認する場合:

```powershell
Invoke-WebRequest "http://<web-public-ip>" -UseBasicParsing
```

期待する結果:

- HTTP ステータスが `200`
- TODO アプリの HTML が返る
- ブラウザで TODO アプリ画面が表示される

この確認で分かること:

- Web VM の Public IP が割り当てられている
- Web NSG が Internet から TCP/80 を許可している
- NGINX が 80 番で応答している
- cloud-init による TODO アプリ配置が動いている

## 4. 踏み台 VM へ SSH できることを確認する

ローカル PC から踏み台 VM に SSH します。

```powershell
ssh azureuser@<bastion-public-ip>
```

期待する結果:

- SSH 接続できる
- ログイン後のプロンプトに `azureuser@vm-todo-bas-dev` が表示される

接続できない場合は、現在の Public IP と NSG の許可元が一致しているか確認します。

```powershell
$myIp = Invoke-RestMethod "https://api.ipify.org"
$myIp
```

NSG ルールを確認します。

```powershell
az network nsg rule list `
  --resource-group rg-todo-dev `
  --nsg-name nsg-todo-bas-dev `
  --output table
```

`Allow-SSH-From-Allowed-Source` の送信元が `<your-public-ip>/32` になっていることを確認します。

## 5. Web VM へ踏み台経由で SSH できることを確認する

ローカル PC から ProxyJump で Web VM に SSH します。

```powershell
ssh -J azureuser@<bastion-public-ip> azureuser@10.10.2.10
```

期待する結果:

- Web VM に SSH 接続できる
- ログイン後のプロンプトに `azureuser@vm-todo-web-dev` が表示される

この確認で分かること:

- 踏み台 VM へ SSH できる
- 踏み台 VM から Web VM の Private IP へ到達できる
- Web NSG が Bastion subnet から TCP/22 を許可している

## 6. Web VM への直接 SSH が失敗することを確認する

ローカル PC から Web VM の Public IP に直接 SSH します。

```powershell
ssh azureuser@<web-public-ip>
```

期待する結果:

- 接続できない
- タイムアウトまたは接続失敗になる

この確認は「失敗すること」が正しいです。Web VM の SSH はインターネットに公開せず、踏み台サブネットからだけ許可しています。

## 7. Web VM 内で NGINX を確認する

Web VM に SSH した状態で実行します。

```bash
systemctl status nginx
```

期待する結果:

- `active (running)` と表示される

Web VM 内から HTTP 応答を確認します。

```bash
curl -I http://localhost/
```

期待する結果:

```text
HTTP/1.1 200 OK
```

TODO アプリのファイルを確認します。

```bash
ls -l /var/www/html/index.html
```

## 8. 踏み台 VM から Web VM の HTTP 到達性を確認する

踏み台 VM に SSH した状態で実行します。

```bash
curl -I http://10.10.2.10/
```

期待する結果:

```text
HTTP/1.1 200 OK
```

この確認で、VNet 内から Web VM の HTTP に到達できることが分かります。

## 9. NSG のルールを確認する

踏み台 VM 側 NSG:

```powershell
az network nsg rule list `
  --resource-group rg-todo-dev `
  --nsg-name nsg-todo-bas-dev `
  --output table
```

期待するルール:

- `Allow-SSH-From-Allowed-Source`
- 送信元: `<your-public-ip>/32`
- 宛先ポート: `22`

Web VM 側 NSG:

```powershell
az network nsg rule list `
  --resource-group rg-todo-dev `
  --nsg-name nsg-todo-web-dev `
  --output table
```

期待するルール:

- `Allow-SSH-From-Bastion-Subnet`: Bastion subnet から TCP/22 を許可
- `Allow-HTTP-From-Internet`: Internet から TCP/80 を許可

## 10. うまくいかないときの切り分け

TODO アプリが表示されない場合:

- `todoAppUrl` の IP が `webPublicIpAddress` と一致しているか確認する
- Web VM が起動中か確認する
- Web NSG に `Allow-HTTP-From-Internet` があるか確認する
- Web VM 内で `systemctl status nginx` を確認する
- Web VM 内で `curl -I http://localhost/` を確認する

踏み台 VM に SSH できない場合:

- `allowedSshSourceAddressPrefix` が現在の Public IP と一致しているか確認する
- `sshKey` に対応する秘密鍵をローカル PC が使っているか確認する
- Bastion VM が起動中か確認する
- Bastion NSG に `Allow-SSH-From-Allowed-Source` があるか確認する

Web VM に踏み台経由で SSH できない場合:

- 先に踏み台 VM へ SSH できるか確認する
- Web VM が起動中か確認する
- Web NSG に `Allow-SSH-From-Bastion-Subnet` があるか確認する
- Web VM の Private IP が `10.10.2.10` か確認する

## 確認後

学習後に不要になったら Resource Group ごと削除します。

```powershell
az group delete --name rg-todo-dev --yes
```

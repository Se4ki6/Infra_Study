# デプロイ手順

このドキュメントは、`resource-project/bastion-web-todo` を Azure にデプロイする手順をまとめたものです。

この手順では実際に Azure リソースを作成します。VM、Public IP、ディスクなどにより課金が発生する可能性があります。学習後は不要なリソースを削除してください。

## 前提

- Azure CLI がインストールされている
- Azure CLI でログインできる
- デプロイ先サブスクリプションを選べる
- SSH 公開鍵を用意できる
- PowerShell で実行する

## 1. Azure にログインする

```powershell
az login
```

現在選択されているサブスクリプションを確認します。

```powershell
az account show
```

別のサブスクリプションを使う場合は切り替えます。

```powershell
az account set --subscription "<subscription-id-or-name>"
```

## 2. Bicep ディレクトリへ移動する

リポジトリルートから次のディレクトリへ移動します。

```powershell
cd resource-project\bastion-web-todo\infra-bicep
```

## 3. SSH 公開鍵を用意する

既に `id_ed25519.pub` がある場合は、そのまま使えます。

```powershell
Get-Content $HOME\.ssh\id_ed25519.pub
```

存在しない場合は作成します。

```powershell
ssh-keygen -t ed25519 -f $HOME\.ssh\id_ed25519
```

Bicep に渡すため、公開鍵を変数に入れます。

```powershell
$sshKey = Get-Content $HOME\.ssh\id_ed25519.pub -Raw
```

Azure に渡すのは公開鍵です。秘密鍵である `id_ed25519` は渡しません。

## 4. SSH を許可する送信元 IP を取得する

踏み台 VM への SSH は、自分の Public IP からだけ許可します。

```powershell
$myIp = (Invoke-RestMethod 'https://api.ipify.org')
```

確認します。

```powershell
$myIp
```

デプロイ時には `allowedSshSourceAddressPrefix` として渡します。`/32` は、その 1 つの IP アドレスだけを許可する指定です。

```powershell
$allowedSsh = "$myIp/32"
```

## 5. Bicep をビルドして確認する

構文エラーがないか確認します。

```powershell
az bicep build --file .\main.bicep
```

成功すると `main.json` が生成または更新されます。

## 6. デプロイする

この Bicep は Resource Group 自体も作るため、subscription scope でデプロイします。

```powershell
az deployment sub create `
  --location japaneast `
  --parameters .\main.bicepparam `
  --parameters sshPublicKey="$sshKey" allowedSshSourceAddressPrefix="$allowedSsh"
```

`main.bicepparam` には安全側のサンプル値を入れています。実際の SSH 公開鍵と許可元 IP は、上のコマンドの `--parameters` で上書きします。

## 7. デプロイ結果を確認する

デプロイが成功すると、output に主な接続情報が表示されます。

- `bastionPublicIpAddress`: 踏み台 VM の Public IP
- `webPublicIpAddress`: Web VM の Public IP
- `todoAppUrl`: TODO アプリの URL
- `bastionSshCommand`: 踏み台 VM への SSH コマンド
- `webSshCommand`: 踏み台経由で Web VM に入る SSH コマンド

TODO アプリはブラウザで確認します。

```text
http://<web-public-ip>
```

または output の `todoAppUrl` を使います。

デプロイ後の詳しい動作確認観点は [operation-check-guide.md](operation-check-guide.md) を参照してください。

## 8. SSH 接続を確認する

踏み台 VM へ SSH します。

```powershell
ssh azureuser@<bastion-public-ip>
```

Web VM へは踏み台経由で SSH します。

```powershell
ssh -J azureuser@<bastion-public-ip> azureuser@10.10.2.10
```

Web VM への直接 SSH は NSG で許可していないため、インターネットから直接 `ssh azureuser@<web-public-ip>` しても接続できない想定です。

## 9. 削除する

学習後に不要になったら Resource Group ごと削除します。

```powershell
az group delete --name rg-todo-dev --yes
```

確認プロンプトを出したい場合は `--yes` を外します。

```powershell
az group delete --name rg-todo-dev
```

## よくある確認ポイント

デプロイ先リージョンを変えたい場合は、`main.bicepparam` の `location` と、`az deployment sub create --location` の値を確認します。

```bicep
param location = 'japaneast'
```

VM サイズを変えたい場合は、`main.bicepparam` を変更します。

```bicep
param bastionVmSize = 'Standard_D2as_v4'
param webVmSize = 'Standard_D2as_v4'
```

SSH 接続できない場合は、`allowedSshSourceAddressPrefix` に現在の Public IP が入っているか確認します。Public IP はネットワーク環境が変わると変わることがあります。

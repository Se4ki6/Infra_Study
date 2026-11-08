<#
.SYNOPSIS
    Function App のコードを zip デプロイする。

.DESCRIPTION
    Azure Functions Core Tools (func) を使わず、dotnet publish + az CLI の zip デプロイで完結する。
    デプロイ先は terraform/azure の出力から自動で取得する。

.EXAMPLE
    ./deploy.ps1

.EXAMPLE
    ./deploy.ps1 -ResourceGroup rg-s3sts-dev -FunctionAppName func-s3sts-ab12cd
#>
[CmdletBinding()]
param(
    [string]$ResourceGroup,
    [string]$FunctionAppName,
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$repoRoot    = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "src/S3StsDownload"
$terraformDir = Join-Path $repoRoot "terraform/azure"
$publishDir  = Join-Path $repoRoot "artifacts/publish"
$zipPath     = Join-Path $repoRoot "artifacts/S3StsDownload.zip"

# --- デプロイ先の解決 -----------------------------------------------------------
if (-not $ResourceGroup -or -not $FunctionAppName) {
    Write-Host "terraform/azure の出力からデプロイ先を取得します..." -ForegroundColor Cyan

    if (-not $ResourceGroup) {
        $ResourceGroup = (terraform -chdir=$terraformDir output -raw resource_group_name)
    }
    if (-not $FunctionAppName) {
        $FunctionAppName = (terraform -chdir=$terraformDir output -raw function_app_name)
    }
}

Write-Host "デプロイ先: $FunctionAppName (リソースグループ: $ResourceGroup)" -ForegroundColor Green

# --- ビルドと発行 ---------------------------------------------------------------
if (Test-Path $publishDir) {
    Remove-Item $publishDir -Recurse -Force
}
New-Item -ItemType Directory -Path $publishDir -Force | Out-Null

Write-Host "dotnet publish を実行します..." -ForegroundColor Cyan
dotnet publish $projectPath --configuration $Configuration --output $publishDir --nologo
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish に失敗しました。"
}

# --- zip 化 ---------------------------------------------------------------------
# 発行フォルダ「の中身」を zip のルートに置く必要がある (フォルダごと固めるとランタイムが認識しない)
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Write-Host "zip を作成します: $zipPath" -ForegroundColor Cyan
Compress-Archive -Path (Join-Path $publishDir "*") -DestinationPath $zipPath -Force

# --- デプロイ -------------------------------------------------------------------
Write-Host "Azure にデプロイします..." -ForegroundColor Cyan
az functionapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $FunctionAppName `
    --src $zipPath
if ($LASTEXITCODE -ne 0) {
    throw "zip デプロイに失敗しました。"
}

# --- 動作確認用の情報を表示 ------------------------------------------------------
$hostName = (az functionapp show -g $ResourceGroup -n $FunctionAppName --query defaultHostName -o tsv)
$key      = (az functionapp keys list -g $ResourceGroup -n $FunctionAppName --query "functionKeys.default" -o tsv)

Write-Host ""
Write-Host "デプロイが完了しました。" -ForegroundColor Green
Write-Host ""
Write-Host "動作確認:" -ForegroundColor Yellow
Write-Host "  curl `"https://$hostName/api/token-claims?code=$key`""
Write-Host "  curl `"https://$hostName/api/whoami?mode=oidc&code=$key`""
Write-Host "  curl `"https://$hostName/api/files?mode=oidc&code=$key`""
Write-Host "  curl `"https://$hostName/api/download?key=hello.txt&mode=oidc&code=$key`""
Write-Host ""
Write-Host "注意: ランタイムの起動直後は数十秒ほど 503 が返ることがあります。" -ForegroundColor DarkGray

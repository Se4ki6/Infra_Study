# API疎通確認スクリプト (Windows PowerShell)
# 使用方法: .\test.ps1 <API_ENDPOINT_URL>
# 例: .\test.ps1 "https://xxxxx.execute-api.ap-northeast-1.amazonaws.com"

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiEndpoint
)

$testUrl = "${ApiEndpoint}/generate?url=https://example.com"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "API疎通確認テスト" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "テスト対象: $testUrl" -ForegroundColor White
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $testUrl -Method GET -UseBasicParsing -ErrorAction Stop

    if ($response.StatusCode -eq 200) {
        Write-Host "✅ テスト成功" -ForegroundColor Green
        Write-Host "ステータスコード: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Content-Type: $($response.Headers['Content-Type'])" -ForegroundColor Gray
        Write-Host "レスポンスサイズ: $($response.RawContentLength) bytes" -ForegroundColor Gray
        exit 0
    }
    else {
        Write-Host "⚠️  予期しないステータスコード: $($response.StatusCode)" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "❌ テスト失敗" -ForegroundColor Red
    Write-Host "エラー: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$PKG_DIR = "python_payload"

# クリーンアップ
if (Test-Path $PKG_DIR) { Remove-Item -Recurse -Force $PKG_DIR }
if (Test-Path "lambda_function_payload.zip") { Remove-Item -Force "lambda_function_payload.zip" }

# ディレクトリ作成
New-Item -ItemType Directory -Path $PKG_DIR

# ライブラリのインストール
pip install -r lambda_code/requirements.txt -t $PKG_DIR

# ソースコードのコピー
Copy-Item lambda_code/handler.py -Destination $PKG_DIR

# ZIP化
Compress-Archive -Path "$PKG_DIR\*" -DestinationPath "lambda_function_payload.zip"

# クリーンアップ
Remove-Item -Recurse -Force $PKG_DIR

Write-Host "Build complete: lambda_function_payload.zip" -ForegroundColor Green

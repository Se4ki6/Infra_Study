# モノレポ移行マニフェスト

作成日: 2026-11-08（Asia/Tokyo）

この一覧は移行候補と判定結果。移行元は現在の working tree を参照し、移行元の内容は変更しない。機密値は出力・記録しない。 gitleaks/trufflehog は環境に見つからなかったため、320 候補ファイルに対して秘密鍵・クラウド token・secret/connection string の代入を探すローカルのパターン検査を実施した。4 件の一致は既知の説明用 placeholder 3 件と、コピー時に置換する api_key 例 1 件だった。

候補ファイル数: 326（通常候補 320 + provider lock file 6）
除外候補ファイル数: 16

## 候補ファイル

| 移行元 | 移行先 | 判定 | 確認事項 |
| --- | --- | --- | --- |
| `AWS:AWS_Blocks/janken/.blocks/config.json` | `AWS/projects/aws-blocks/janken/.blocks/config.json` | 除外（L8） | telemetry.projectId を含む個別設定。アプリソースに不要と確認 |
| `AWS:AWS_Blocks/janken/.gitignore` | `AWS/projects/aws-blocks/janken/.gitignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/AGENTS.md` | `AWS/projects/aws-blocks/janken/AGENTS.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/index.cdk.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/index.cdk.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/index.handler.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/index.handler.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/index.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/index.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/package.json` | `AWS/projects/aws-blocks/janken/aws-blocks/package.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/cleanup.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/cleanup.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/console.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/console.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/deploy.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/deploy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/destroy.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/destroy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/sandbox-destroy.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/sandbox-destroy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/sandbox-id.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/sandbox-id.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/sandbox.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/sandbox.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/aws-blocks/scripts/server.ts` | `AWS/projects/aws-blocks/janken/aws-blocks/scripts/server.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/cdk.json` | `AWS/projects/aws-blocks/janken/cdk.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/index.html` | `AWS/projects/aws-blocks/janken/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/package-lock.json` | `AWS/projects/aws-blocks/janken/package-lock.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/package.json` | `AWS/projects/aws-blocks/janken/package.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/src/index.ts` | `AWS/projects/aws-blocks/janken/src/index.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/test/e2e.test.ts` | `AWS/projects/aws-blocks/janken/test/e2e.test.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/tsconfig.json` | `AWS/projects/aws-blocks/janken/tsconfig.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/janken/vite.config.ts` | `AWS/projects/aws-blocks/janken/vite.config.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/.blocks/config.json` | `AWS/projects/aws-blocks/my-todo-app/.blocks/config.json` | 除外（L8） | telemetry.projectId を含む個別設定。アプリソースに不要と確認 |
| `AWS:AWS_Blocks/my-todo-app/.gitignore` | `AWS/projects/aws-blocks/my-todo-app/.gitignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/AGENTS.md` | `AWS/projects/aws-blocks/my-todo-app/AGENTS.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/index.cdk.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/index.cdk.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/index.handler.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/index.handler.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/index.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/index.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/package.json` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/package.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/cleanup.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/cleanup.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/console.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/console.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/deploy.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/deploy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/destroy.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/destroy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/sandbox-destroy.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/sandbox-destroy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/sandbox-id.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/sandbox-id.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/sandbox.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/sandbox.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/aws-blocks/scripts/server.ts` | `AWS/projects/aws-blocks/my-todo-app/aws-blocks/scripts/server.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/cdk.json` | `AWS/projects/aws-blocks/my-todo-app/cdk.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/index.html` | `AWS/projects/aws-blocks/my-todo-app/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/package-lock.json` | `AWS/projects/aws-blocks/my-todo-app/package-lock.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/package.json` | `AWS/projects/aws-blocks/my-todo-app/package.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/src/index.ts` | `AWS/projects/aws-blocks/my-todo-app/src/index.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/test/e2e.test.ts` | `AWS/projects/aws-blocks/my-todo-app/test/e2e.test.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/tsconfig.json` | `AWS/projects/aws-blocks/my-todo-app/tsconfig.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:AWS_Blocks/my-todo-app/vite.config.ts` | `AWS/projects/aws-blocks/my-todo-app/vite.config.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Amplify/Host_Github_Repository/.gitignore` | `AWS/resources/Amplify/Host_Github_Repository/.gitignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Amplify/Host_Github_Repository/amplify.tf` | `AWS/resources/Amplify/Host_Github_Repository/amplify.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Amplify/Host_Github_Repository/outputs.tf` | `AWS/resources/Amplify/Host_Github_Repository/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Amplify/Host_Github_Repository/provider.tf` | `AWS/resources/Amplify/Host_Github_Repository/provider.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Amplify/Host_Github_Repository/variables.tf` | `AWS/resources/Amplify/Host_Github_Repository/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Basic/Bedrock/progress.md` | `AWS/docs/Bedrock/progress.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/Implemention_details.md` | `AWS/resources/CloudFront_Functions/Implemention_details.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/README.md` | `AWS/resources/CloudFront_Functions/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/function.js` | `AWS/resources/CloudFront_Functions/function.js` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/main.tf` | `AWS/resources/CloudFront_Functions/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/outputs.tf` | `AWS/resources/CloudFront_Functions/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/providers.tf` | `AWS/resources/CloudFront_Functions/providers.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/upload_file/error.html` | `AWS/resources/CloudFront_Functions/upload_file/error.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/upload_file/index.html` | `AWS/resources/CloudFront_Functions/upload_file/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_Functions/variables.tf` | `AWS/resources/CloudFront_Functions/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/README.md` | `AWS/resources/CloudFront_S3/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/cloudfront.tf` | `AWS/resources/CloudFront_S3/cloudfront.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/docs/cloudfront-beginner-guide.md` | `AWS/resources/CloudFront_S3/docs/cloudfront-beginner-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/outputs.tf` | `AWS/resources/CloudFront_S3/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/providers.tf` | `AWS/resources/CloudFront_S3/providers.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/s3.tf` | `AWS/resources/CloudFront_S3/s3.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/example.txt` | `AWS/resources/CloudFront_S3/upload_file/example.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/example2.txt` | `AWS/resources/CloudFront_S3/upload_file/example2.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/example3.txt` | `AWS/resources/CloudFront_S3/upload_file/example3.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/images/.gitkeep` | `AWS/resources/CloudFront_S3/upload_file/images/.gitkeep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/images/zushihokki1.png` | `AWS/resources/CloudFront_S3/upload_file/images/zushihokki1.png` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/images/zushihokki2.jpg` | `AWS/resources/CloudFront_S3/upload_file/images/zushihokki2.jpg` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/images/zushihokki3.gif` | `AWS/resources/CloudFront_S3/upload_file/images/zushihokki3.gif` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/website/error.html` | `AWS/resources/CloudFront_S3/upload_file/website/error.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/upload_file/website/index.html` | `AWS/resources/CloudFront_S3/upload_file/website/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/variables.tf` | `AWS/resources/CloudFront_S3/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_S3/waf.tf` | `AWS/resources/CloudFront_S3/waf.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/README.md` | `AWS/resources/CloudFront_test/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/main.tf` | `AWS/resources/CloudFront_test/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/outputs.tf` | `AWS/resources/CloudFront_test/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/providers.tf` | `AWS/resources/CloudFront_test/providers.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/upload_file/error.html` | `AWS/resources/CloudFront_test/upload_file/error.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/upload_file/index.html` | `AWS/resources/CloudFront_test/upload_file/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:CloudFront_test/variables.tf` | `AWS/resources/CloudFront_test/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda/README.md` | `AWS/resources/Lambda/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda/main.tf` | `AWS/resources/Lambda/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda/src/index.py` | `AWS/resources/Lambda/src/index.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/README.md` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/api_gateway.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/api_gateway.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda_code/handler.py` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda_code/handler.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda_code/requirements.txt` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda_code/requirements.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/main.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/outputs.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/build.ps1` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/build.ps1` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/build.sh` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/build.sh` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/test.ps1` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/test.ps1` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/test.sh` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/script/test.sh` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/variable.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/Lambda_ApiGw/variable.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/README.md` | `AWS/projects/Lambda_ApiGW_QR_Generator/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/main.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/S3/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/outputs.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/S3/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/s3.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/S3/s3.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/upload_file/index.html` | `AWS/projects/Lambda_ApiGW_QR_Generator/S3/upload_file/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/variable.tf` | `AWS/projects/Lambda_ApiGW_QR_Generator/S3/variable.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:README.md` | `AWS/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/README.md` | `AWS/resources/S3/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/docs/cache-control-strategies.md` | `AWS/resources/S3/docs/cache-control-strategies.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/docs/gitignore-tips.md` | `AWS/resources/S3/docs/gitignore-tips.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/docs/presigned-url-automation.md` | `AWS/resources/S3/docs/presigned-url-automation.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/docs/presigned-url-setup-guide.md` | `AWS/resources/S3/docs/presigned-url-setup-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/docs/static-website-hosting.md` | `AWS/resources/S3/docs/static-website-hosting.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/docs/terraform-s3-guide.md` | `AWS/resources/S3/docs/terraform-s3-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/iam.tf` | `AWS/resources/S3/iam.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/main.tf` | `AWS/resources/S3/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/outputs.tf` | `AWS/resources/S3/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/scripts/.env.example` | `AWS/resources/S3/scripts/.env.example` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/scripts/generate_presigned_url.py` | `AWS/resources/S3/scripts/generate_presigned_url.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/scripts/requirements.txt` | `AWS/resources/S3/scripts/requirements.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/testfile.txt` | `AWS/resources/S3/testfile.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/error.html` | `AWS/resources/S3/upload_file/error.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/example.txt` | `AWS/resources/S3/upload_file/example.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/example2.txt` | `AWS/resources/S3/upload_file/example2.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/example3.txt` | `AWS/resources/S3/upload_file/example3.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/images/.gitkeep` | `AWS/resources/S3/upload_file/images/.gitkeep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/images/zushihokki1.png` | `AWS/resources/S3/upload_file/images/zushihokki1.png` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/images/zushihokki2.jpg` | `AWS/resources/S3/upload_file/images/zushihokki2.jpg` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/images/zushihokki3.gif` | `AWS/resources/S3/upload_file/images/zushihokki3.gif` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/upload_file/index.html` | `AWS/resources/S3/upload_file/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3/variables.tf` | `AWS/resources/S3/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/README.md` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/Variable.tf` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/Variable.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/api_gateway.tf` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/api_gateway.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/lambda.tf` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/lambda.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/main.tf` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/outputs.tf` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/s3.tf` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/s3.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/src/frontend/index.html` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/src/frontend/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_APIGW_Lambda_SimpleApp/src/lambda/app.py` | `AWS/projects/S3_APIGW_Lambda_SimpleApp/src/lambda/app.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/.gitignore` | `Cross-Cloud/S3_STS_AzureFunction/.gitignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/README.md` | `Cross-Cloud/S3_STS_AzureFunction/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/docs/company-account-testing.md` | `Cross-Cloud/S3_STS_AzureFunction/docs/company-account-testing.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/docs/s3-access-control.md` | `Cross-Cloud/S3_STS_AzureFunction/docs/s3-access-control.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/docs/setup-guide.md` | `Cross-Cloud/S3_STS_AzureFunction/docs/setup-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/docs/verification.md` | `Cross-Cloud/S3_STS_AzureFunction/docs/verification.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/sample_files/hello.txt` | `Cross-Cloud/S3_STS_AzureFunction/sample_files/hello.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/sample_files/sample.json` | `Cross-Cloud/S3_STS_AzureFunction/sample_files/sample.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/scripts/deploy.ps1` | `Cross-Cloud/S3_STS_AzureFunction/scripts/deploy.ps1` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/.gitignore` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/.gitignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Functions/DiagnosticsFunctions.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Functions/DiagnosticsFunctions.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Functions/HttpResponses.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Functions/HttpResponses.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Functions/S3Functions.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Functions/S3Functions.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Program.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Program.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/S3StsDownload.csproj` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/S3StsDownload.csproj` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/AccessKeyAssumeRoleProvider.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/AccessKeyAssumeRoleProvider.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/AwsCredentialProviderFactory.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/AwsCredentialProviderFactory.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/AwsTemporaryCredentials.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/AwsTemporaryCredentials.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/AzureOidcWebIdentityProvider.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/AzureOidcWebIdentityProvider.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/CachedCredentialProvider.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/CachedCredentialProvider.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/IAwsCredentialProvider.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/IAwsCredentialProvider.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/JwtInspector.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/JwtInspector.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/S3AccessService.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/S3AccessService.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/Services/StsSettings.cs` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/Services/StsSettings.cs` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/host.json` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/host.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/src/S3StsDownload/local.settings.json.example` | `Cross-Cloud/S3_STS_AzureFunction/src/S3StsDownload/local.settings.json.example` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/aws/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/aws/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/aws/provider.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/provider.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/aws/terraform.tfvars.company.example` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/terraform.tfvars.company.example` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/aws/terraform.tfvars.example` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/terraform.tfvars.example` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/aws/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/azure/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/azure/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/azure/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/azure/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/azure/provider.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/azure/provider.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/azure/terraform.tfvars.example` | `Cross-Cloud/S3_STS_AzureFunction/terraform/azure/terraform.tfvars.example` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/azure/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/azure/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_bucket_lockdown/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_read_policy/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/s3_secure_bucket/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_access_key_flow/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/aws/sts_oidc_flow/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/entra_app/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/entra_app/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/entra_app/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/entra_app/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/entra_app/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/entra_app/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/entra_app/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/entra_app/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/function_app/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/function_app/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/function_app/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/function_app/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/function_app/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/function_app/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/modules/azure/function_app/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/modules/azure/function_app/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/partner-handoff/README.md` | `Cross-Cloud/S3_STS_AzureFunction/terraform/partner-handoff/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/partner-handoff/main.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/partner-handoff/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/partner-handoff/outputs.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/partner-handoff/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/partner-handoff/terraform.tfvars.example` | `Cross-Cloud/S3_STS_AzureFunction/terraform/partner-handoff/terraform.tfvars.example` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/partner-handoff/variables.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/partner-handoff/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:S3_STS_AzureFunction/terraform/partner-handoff/versions.tf` | `Cross-Cloud/S3_STS_AzureFunction/terraform/partner-handoff/versions.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/AWS_API_Gateway/about_aws_api_gateway.md` | `AWS/docs/AWS_API_Gateway/about_aws_api_gateway.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/AWS_API_Gateway/simpleapicallingapp/design.md` | `AWS/docs/AWS_API_Gateway/simpleapicallingapp/design.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/AWS_API_Gateway/simpleapicallingapp/simple_apicallingapp_scratchpad.md` | `AWS/docs/AWS_API_Gateway/simpleapicallingapp/simple_apicallingapp_scratchpad.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/AWS_API_Gateway/weatherforecastapp/weatherforecastapp_scratchpad.md` | `AWS/docs/AWS_API_Gateway/weatherforecastapp/weatherforecastapp_scratchpad.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/AWS_Blocks/aws-blocks-handson.md` | `AWS/docs/AWS_Blocks/aws-blocks-handson.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/AWS_Blocks/aws-blocks-overview.md` | `AWS/docs/AWS_Blocks/aws-blocks-overview.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/Lambda/about_lambda.md` | `AWS/docs/Lambda/about_lambda.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/Lambda/lambda_example.md` | `AWS/docs/Lambda/lambda_example.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/Lambda/memo` | `AWS/docs/Lambda/memo` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/Lambda_ApiGW_QR_Generator/design.md` | `AWS/docs/Lambda_ApiGW_QR_Generator/design.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/Lambda_ApiGW_QR_Generator/review.md` | `AWS/docs/Lambda_ApiGW_QR_Generator/review.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/Lambda_ApiGW_QR_Generator/todo.md` | `AWS/docs/Lambda_ApiGW_QR_Generator/todo.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/README.md` | `AWS/docs/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/S3_APIGW_Lambda_SimpleApp/api_gateway.tf.description.md` | `AWS/docs/S3_APIGW_Lambda_SimpleApp/api_gateway.tf.description.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/S3_APIGW_Lambda_SimpleApp/lambda.tf.description.md` | `AWS/docs/S3_APIGW_Lambda_SimpleApp/lambda.tf.description.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/S3_APIGW_Lambda_SimpleApp/main.tf.description.md` | `AWS/docs/S3_APIGW_Lambda_SimpleApp/main.tf.description.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/S3_APIGW_Lambda_SimpleApp/outputs.tf.description.md` | `AWS/docs/S3_APIGW_Lambda_SimpleApp/outputs.tf.description.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/S3_APIGW_Lambda_SimpleApp/s3.tf.description.md` | `AWS/docs/S3_APIGW_Lambda_SimpleApp/s3.tf.description.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/S3_APIGW_Lambda_SimpleApp/variable.tf.description.md` | `AWS/docs/S3_APIGW_Lambda_SimpleApp/variable.tf.description.md` | 採用（コピー時に api_key の値をプレースホルダーへ置換） | 例示値を移行先で `replace-with-api-key` に置換 |
| `AWS:docs/about_apigateway.md` | `AWS/docs/about_apigateway.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/amplify/about_amplify.md` | `AWS/docs/amplify/about_amplify.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/cloudfront/about_CloudFront_Functions.md` | `AWS/docs/cloudfront/about_CloudFront_Functions.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/cloudfront/difference_between_CloudFront_S3.md` | `AWS/docs/cloudfront/difference_between_CloudFront_S3.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/cloudfront/flowchart.md` | `AWS/docs/cloudfront/flowchart.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:docs/cloudfront/sequence_diagram.md` | `AWS/docs/cloudfront/sequence_diagram.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/.blocks/config.json` | `AWS/projects/aws-blocks/standalone-my-janken/.blocks/config.json` | 除外（L8） | telemetry.projectId を含む個別設定。アプリソースに不要と確認 |
| `AWS:my-janken/.gitignore` | `AWS/projects/aws-blocks/standalone-my-janken/.gitignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/AGENTS.md` | `AWS/projects/aws-blocks/standalone-my-janken/AGENTS.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/README.md` | `AWS/projects/aws-blocks/standalone-my-janken/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/index.cdk.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/index.cdk.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/index.handler.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/index.handler.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/index.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/index.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/package.json` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/package.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/cleanup.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/cleanup.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/console.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/console.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/deploy.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/deploy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/destroy.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/destroy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/sandbox-destroy.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/sandbox-destroy.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/sandbox-id.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/sandbox-id.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/sandbox.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/sandbox.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/aws-blocks/scripts/server.ts` | `AWS/projects/aws-blocks/standalone-my-janken/aws-blocks/scripts/server.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/cdk.json` | `AWS/projects/aws-blocks/standalone-my-janken/cdk.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/index.html` | `AWS/projects/aws-blocks/standalone-my-janken/index.html` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/package-lock.json` | `AWS/projects/aws-blocks/standalone-my-janken/package-lock.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/package.json` | `AWS/projects/aws-blocks/standalone-my-janken/package.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/src/index.ts` | `AWS/projects/aws-blocks/standalone-my-janken/src/index.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/test/e2e.test.ts` | `AWS/projects/aws-blocks/standalone-my-janken/test/e2e.test.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/tsconfig.json` | `AWS/projects/aws-blocks/standalone-my-janken/tsconfig.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `AWS:my-janken/vite.config.ts` | `AWS/projects/aws-blocks/standalone-my-janken/vite.config.ts` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:LICENSE` | `Azure/LICENSE` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:plans/azure-functions-minimal-hello-world-plan.md` | `Azure/plans/azure-functions-minimal-hello-world-plan.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:plans/azure-vm-minimal-bicep-plan.md` | `Azure/plans/azure-vm-minimal-bicep-plan.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/blob/README.md` | `Azure/resources/blob/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/blob/infra-terraform/main.tf` | `Azure/resources/blob/infra-terraform/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/blob/infra-terraform/sample.md` | `Azure/resources/blob/infra-terraform/sample.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/README.md` | `Azure/resources/functions/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/.funcignore` | `Azure/resources/functions/app/.funcignore` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/function_app.py` | `Azure/resources/functions/app/function_app.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/host.json` | `Azure/resources/functions/app/host.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/requirements.txt` | `Azure/resources/functions/app/requirements.txt` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/src/handlers/hello.py` | `Azure/resources/functions/app/src/handlers/hello.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/src/main.py` | `Azure/resources/functions/app/src/main.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/app/src/services/response_builder.py` | `Azure/resources/functions/app/src/services/response_builder.py` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/main.tf` | `Azure/resources/functions/infra-terraform/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/function_app/main.tf` | `Azure/resources/functions/infra-terraform/modules/function_app/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/function_app/outputs.tf` | `Azure/resources/functions/infra-terraform/modules/function_app/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/function_app/variables.tf` | `Azure/resources/functions/infra-terraform/modules/function_app/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/monitoring/main.tf` | `Azure/resources/functions/infra-terraform/modules/monitoring/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/monitoring/outputs.tf` | `Azure/resources/functions/infra-terraform/modules/monitoring/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/monitoring/variables.tf` | `Azure/resources/functions/infra-terraform/modules/monitoring/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/resource_group/main.tf` | `Azure/resources/functions/infra-terraform/modules/resource_group/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/resource_group/outputs.tf` | `Azure/resources/functions/infra-terraform/modules/resource_group/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/resource_group/variables.tf` | `Azure/resources/functions/infra-terraform/modules/resource_group/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/storage_account/main.tf` | `Azure/resources/functions/infra-terraform/modules/storage_account/main.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/storage_account/outputs.tf` | `Azure/resources/functions/infra-terraform/modules/storage_account/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/modules/storage_account/variables.tf` | `Azure/resources/functions/infra-terraform/modules/storage_account/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/outputs.tf` | `Azure/resources/functions/infra-terraform/outputs.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/providers.tf` | `Azure/resources/functions/infra-terraform/providers.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/functions/infra-terraform/variables.tf` | `Azure/resources/functions/infra-terraform/variables.tf` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/README.md` | `Azure/resources/vm/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/docs/gui-bicep-mapping.md` | `Azure/resources/vm/docs/gui-bicep-mapping.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/docs/memo-20260704.md` | `Azure/resources/vm/docs/memo-20260704.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/docs/memo-20260710.md` | `Azure/resources/vm/docs/memo-20260710.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/docs/memo-20260718.md` | `Azure/resources/vm/docs/memo-20260718.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/docs/reference/nsg-vnet-subnet-pip-nic.md` | `Azure/resources/vm/docs/reference/nsg-vnet-subnet-pip-nic.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/infra-bicep/main.bicep` | `Azure/resources/vm/infra-bicep/main.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/infra-bicep/main.bicepparam` | `Azure/resources/vm/infra-bicep/main.bicepparam` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/infra-bicep/main.json` | `Azure/resources/vm/infra-bicep/main.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/infra-bicep/modules/auto_shutdown.bicep` | `Azure/resources/vm/infra-bicep/modules/auto_shutdown.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/infra-bicep/modules/network.bicep` | `Azure/resources/vm/infra-bicep/modules/network.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-learn/vm/infra-bicep/modules/virtual_machine.bicep` | `Azure/resources/vm/infra-bicep/modules/virtual_machine.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/README.md` | `Azure/projects/bastion-web-todo/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/docs/deployment-guide.md` | `Azure/projects/bastion-web-todo/docs/deployment-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/docs/implementation-guide.md` | `Azure/projects/bastion-web-todo/docs/implementation-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/docs/nginx-guide.md` | `Azure/projects/bastion-web-todo/docs/nginx-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/docs/operation-check-guide.md` | `Azure/projects/bastion-web-todo/docs/operation-check-guide.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/cloud-init/web-todo.yaml` | `Azure/projects/bastion-web-todo/infra-bicep/cloud-init/web-todo.yaml` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/main.bicep` | `Azure/projects/bastion-web-todo/infra-bicep/main.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/main.bicepparam` | `Azure/projects/bastion-web-todo/infra-bicep/main.bicepparam` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/main.json` | `Azure/projects/bastion-web-todo/infra-bicep/main.json` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/modules/auto_shutdown.bicep` | `Azure/projects/bastion-web-todo/infra-bicep/modules/auto_shutdown.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/modules/network.bicep` | `Azure/projects/bastion-web-todo/infra-bicep/modules/network.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/bastion-web-todo/infra-bicep/modules/virtual_machine.bicep` | `Azure/projects/bastion-web-todo/infra-bicep/modules/virtual_machine.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/blob-publicshere/README.md` | `Azure/projects/blob-publicshere/README.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/blob-publicshere/infra-bicep/main.bicep` | `Azure/projects/blob-publicshere/infra-bicep/main.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/blob-publicshere/infra-bicep/main.bicepparam` | `Azure/projects/blob-publicshere/infra-bicep/main.bicepparam` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:resource-project/blob-publicshere/infra-bicep/modules/storage_account.bicep` | `Azure/projects/blob-publicshere/infra-bicep/modules/storage_account.bicep` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:zenn/publish/bicep-overview-for-terraform-users.md` | `Azure/zenn/publish/bicep-overview-for-terraform-users.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |
| `Azure:zenn/publish/terraform-aws-to-azure-functions-apim.md` | `Azure/zenn/publish/terraform-aws-to-azure-functions-apim.md` | 採用（候補ファイルのパターン検査済み） | 内容と参照先を L3 で確認 |

## 個別に追加した Terraform lock file

これらは移行元の ignore 設定で一覧から漏れていたため、ローカルに存在する lock file のうち、採用対象の Terraform ルートに属するものだけ追加した。

| 移行元 | 移行先 | 判定 | 確認事項 |
| --- | --- | --- | --- |
| `AWS:CloudFront_S3/.terraform.lock.hcl` | `AWS/resources/CloudFront_S3/.terraform.lock.hcl` | 採用 | provider lock file |
| `AWS:S3/.terraform.lock.hcl` | `AWS/resources/S3/.terraform.lock.hcl` | 採用 | provider lock file |
| `AWS:S3_STS_AzureFunction/terraform/aws/.terraform.lock.hcl` | `Cross-Cloud/S3_STS_AzureFunction/terraform/aws/.terraform.lock.hcl` | 採用 | provider lock file |
| `AWS:S3_STS_AzureFunction/terraform/azure/.terraform.lock.hcl` | `Cross-Cloud/S3_STS_AzureFunction/terraform/azure/.terraform.lock.hcl` | 採用 | provider lock file |
| `Azure:resource-learn/blob/infra-terraform/.terraform.lock.hcl` | `Azure/resources/blob/infra-terraform/.terraform.lock.hcl` | 採用 | provider lock file |
| `Azure:resource-learn/functions/infra-terraform/.terraform.lock.hcl` | `Azure/resources/functions/infra-terraform/.terraform.lock.hcl` | 採用 | provider lock file |

## 除外したファイル

| 移行元 | 判定理由 |
| --- | --- |
| `AWS:AWS_Blocks/janken/.hosting/static/assets/__vite-browser-external-BIHI7g3E.js` | 生成物・依存物・ローカル状態 |
| `AWS:AWS_Blocks/janken/.hosting/static/assets/index-DbF2Xl6z.js` | 生成物・依存物・ローカル状態 |
| `AWS:AWS_Blocks/janken/.hosting/static/index.html` | 生成物・依存物・ローカル状態 |
| `AWS:AWS_Blocks/my-todo-app/.hosting/static/assets/__vite-browser-external-BIHI7g3E.js` | 生成物・依存物・ローカル状態 |
| `AWS:AWS_Blocks/my-todo-app/.hosting/static/assets/index-DRQtM2y9.js` | 生成物・依存物・ローカル状態 |
| `AWS:AWS_Blocks/my-todo-app/.hosting/static/index.html` | 生成物・依存物・ローカル状態 |
| `AWS:CloudFront_S3/_terraform.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:Lambda/lambda_function.zip` | 生成物 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/dev.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/lambda_function_payload.zip` | 生成物 |
| `AWS:Lambda_ApiGW_QR_Generator/Lambda_ApiGw/prod.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/dev.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:Lambda_ApiGW_QR_Generator/S3/prod.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:S3/_terraform.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:S3_APIGW_Lambda_SimpleApp/dev.tfvars` | 実値混入の可能性があるため全件除外 |
| `AWS:S3_APIGW_Lambda_SimpleApp/prod.tfvars` | 実値混入の可能性があるため全件除外 |

## 検査上の制約とコピー時の変換

- パターン検査は一般的な資格情報形式を対象にしたもので、完全な秘密情報検出を保証しない。tfvars 実ファイル、state、ローカル設定、生成物は候補から除外した。
- `AWS:docs/S3_APIGW_Lambda_SimpleApp/variable.tf.description.md` は移行先へコピーした後に `api_key` の例示値だけ `replace-with-api-key` へ変更する。移行元には触れない。
- 追跡済み AWS tfvars 8 件は全て除外し、追跡しない。例ファイルに credential pattern の一致はなかった。

## 保留候補

- AWS の追跡済み `*.tfvars`（8 件）: 実値の可能性があるため今回の候補には含めない。
- AWS `Project/Obsidian_Publish/`: 現在見つかったのは単独の GitHub workflow のみでアプリソースがないため除外。
- AWS `.github/`、ルート `.gitignore`、Azure の `AGENTS.md`、`CLAUDE.md`、`.codex/`、`.claude/skills/`、`.github/`: L8 で統合要否とパスを確認する。
- AWS `AWS_Blocks/{janken,my-todo-app}/.blocks/config.json`、`my-janken/.blocks/config.json`: telemetry projectId を含むローカル設定。ソースコード・READMEから参照されていないため除外。

## L8 で選別したエージェント設定

| 移行元 | 移行先 | 判定 | 理由 |
| --- | --- | --- | --- |
| `AWS:.github/prompts/make_document.prompt.md` | `.github/prompts/make_document.prompt.md` | 採用 | GitHub prompt としてルートに統合 |
| `Azure:.github/agents/azure-terraform-learning.agent.md` | `.github/agents/azure-terraform-learning.agent.md` | 採用 | Azure 固有の agent としてルートに統合 |
| `Azure:AGENTS.md` | `Azure/AGENTS.md` | 採用 | Azure 学習ルール。L9 で新しいパスに合わせる |
| `Azure:.codex/rules/bicep-conventions.md` | `Azure/.codex/rules/bicep-conventions.md` | 採用 | Azure の Bicep 規約として保持 |
| `Azure:.codex/rules/bicep-templates.md` | `Azure/.codex/rules/bicep-templates.md` | 採用 | Azure の Bicep 雛形として保持 |
| `Azure:.codex/skills/bicep-orchestrator/SKILL.md` | `Azure/.codex/skills/bicep-orchestrator/SKILL.md` | 採用 | Azure 固有の手順として保持 |
| `Azure:.codex/skills/microsoft-learn/SKILL.md` | `Azure/.codex/skills/microsoft-learn/SKILL.md` | 採用 | Azure 公式 Docs 調査手順として保持 |
| `Azure:.codex/skills/microsoft-learn/pyproject.toml` | `Azure/.codex/skills/microsoft-learn/pyproject.toml` | 採用 | 対応 CLI の依存定義 |
| `Azure:.codex/skills/microsoft-learn/scripts/mslmcp_cli.py` | `Azure/.codex/skills/microsoft-learn/scripts/mslmcp_cli.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/.env.example` | `Azure/.codex/skills/use-tavily/.env.example` | 採用 | placeholder のみの環境設定例 |
| `Azure:.codex/skills/use-tavily/SKILL.md` | `Azure/.codex/skills/use-tavily/SKILL.md` | 採用 | Azure 調査手順として保持 |
| `Azure:.codex/skills/use-tavily/scripts/crawl_site_content.py` | `Azure/.codex/skills/use-tavily/scripts/crawl_site_content.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/extract_url_content.py` | `Azure/.codex/skills/use-tavily/scripts/extract_url_content.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/map_extract_site_content.py` | `Azure/.codex/skills/use-tavily/scripts/map_extract_site_content.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/map_site_titles.py` | `Azure/.codex/skills/use-tavily/scripts/map_site_titles.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/research_topic.py` | `Azure/.codex/skills/use-tavily/scripts/research_topic.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/search_extract_topic.py` | `Azure/.codex/skills/use-tavily/scripts/search_extract_topic.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/search_topic.py` | `Azure/.codex/skills/use-tavily/scripts/search_topic.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/use-tavily/scripts/tavily_common.py` | `Azure/.codex/skills/use-tavily/scripts/tavily_common.py` | 採用 | 対応 CLI |
| `Azure:.codex/skills/zenn/SKILL.md` | `Azure/.codex/skills/zenn/SKILL.md` | 採用 | Azure の記事作成手順として保持 |

Azure の `.claude/` と `CLAUDE.md` は Codex 設定との重複があるため対象外。`.claude/worktrees/` と `.claude/skills/use-tavily/src/logs/` は作業用 checkout と検索ログのため対象外。`.codex/skills/use-tavily/.env` はローカル秘密設定のため除外し、例ファイルだけを移行する。選別した L8 ファイルは追加のパターン検査で一致 0 件。

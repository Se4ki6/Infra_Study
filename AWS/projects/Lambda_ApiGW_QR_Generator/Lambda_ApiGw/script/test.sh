#!/bin/bash
# API疎通確認スクリプト (Linux/Mac Bash)
# 使用方法: ./test.sh <API_ENDPOINT_URL>
# 例: ./test.sh "https://xxxxx.execute-api.ap-northeast-1.amazonaws.com"

if [ -z "$1" ]; then
    echo "使用方法: ./test.sh <API_ENDPOINT_URL>"
    echo "例: ./test.sh https://xxxxx.execute-api.ap-northeast-1.amazonaws.com"
    exit 1
fi

API_ENDPOINT=$1
TEST_URL="${API_ENDPOINT}/generate?url=https://example.com"

echo "========================================"
echo "API疎通確認テスト"
echo "========================================"
echo "テスト対象: ${TEST_URL}"
echo ""

# curlでステータスコードを取得
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${TEST_URL}")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ テスト成功"
    echo "ステータスコード: ${HTTP_STATUS}"

    # 追加情報を取得
    CONTENT_TYPE=$(curl -s -I "${TEST_URL}" | grep -i "content-type" | cut -d' ' -f2-)
    echo "Content-Type: ${CONTENT_TYPE}"
    exit 0
else
    echo "❌ テスト失敗"
    echo "ステータスコード: ${HTTP_STATUS}"
    exit 1
fi

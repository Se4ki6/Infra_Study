#!/usr/bin/env python3
"""
S3署名付きURL生成スクリプト

使用方法:
    python generate_presigned_url.py <image_filename>
    python generate_presigned_url.py logo.png
    python generate_presigned_url.py products/item-001.jpg

機能:
    - S3バケット内の画像ファイルに対して署名付きURLを生成
    - 有効期限付き（デフォルト: 1時間）
    - セキュアなプライベートアクセス
"""

import os
import sys
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv
from datetime import datetime, timedelta

# 環境変数の読み込み
load_dotenv()


class PresignedURLGenerator:
    """S3署名付きURL生成クラス"""

    def __init__(self):
        """初期化とAWS認証情報の設定"""
        self.bucket_name = os.getenv('S3_BUCKET_NAME')
        self.images_prefix = os.getenv('S3_IMAGES_PREFIX', 'images')
        self.expiration = int(os.getenv('PRESIGNED_URL_EXPIRATION', 3600))

        # AWS認証情報の検証
        if not self.bucket_name:
            raise ValueError("S3_BUCKET_NAME が設定されていません")

        # S3クライアントの初期化
        try:
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
                aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
                region_name=os.getenv('AWS_REGION', 'ap-southeast-2')
            )
        except NoCredentialsError:
            raise ValueError("AWS認証情報が設定されていません")

    def generate_presigned_url(self, object_key: str, expiration: int = None) -> dict:
        """
        署名付きURLを生成

        Args:
            object_key: S3オブジェクトのキー（例: "logo.png" or "products/item.jpg"）
            expiration: URL有効期限（秒）。Noneの場合はデフォルト値を使用

        Returns:
            dict: URLと有効期限情報を含む辞書
            {
                'url': '署名付きURL',
                'expires_at': '有効期限（ISO形式）',
                'expires_in_seconds': 有効期限（秒）
            }

        Raises:
            ClientError: S3へのアクセスエラー
        """
        if expiration is None:
            expiration = self.expiration

        # プレフィックスを含む完全なオブジェクトキーを構築
        full_key = f"{self.images_prefix}/{object_key}"

        try:
            # オブジェクトの存在確認
            self.s3_client.head_object(Bucket=self.bucket_name, Key=full_key)

            # 署名付きURL生成
            presigned_url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': full_key
                },
                ExpiresIn=expiration
            )

            # 有効期限の計算
            expires_at = datetime.now() + timedelta(seconds=expiration)

            return {
                'url': presigned_url,
                'expires_at': expires_at.isoformat(),
                'expires_in_seconds': expiration,
                'object_key': full_key
            }

        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                raise FileNotFoundError(f"オブジェクトが見つかりません: {full_key}")
            else:
                raise e

    def list_available_images(self) -> list:
        """
        利用可能な画像ファイルのリストを取得

        Returns:
            list: 画像ファイルのキー一覧
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=f"{self.images_prefix}/"
            )

            if 'Contents' not in response:
                return []

            # プレフィックスを除いたファイル名のリスト
            images = [
                obj['Key'].replace(f"{self.images_prefix}/", "")
                for obj in response['Contents']
                if not obj['Key'].endswith('/')  # フォルダを除外
            ]

            return images

        except ClientError as e:
            print(f"エラー: 画像リストの取得に失敗しました - {e}")
            return []


def main():
    """メイン実行関数"""

    # コマンドライン引数のチェック
    if len(sys.argv) < 2:
        print("使用方法: python generate_presigned_url.py <image_filename>")
        print("\n例:")
        print("  python generate_presigned_url.py logo.png")
        print("  python generate_presigned_url.py products/item-001.jpg")
        print("\n利用可能な画像を表示するには: python generate_presigned_url.py --list")
        sys.exit(1)

    try:
        generator = PresignedURLGenerator()

        # 画像リスト表示モード
        if sys.argv[1] == '--list':
            print(f"\n利用可能な画像ファイル（バケット: {generator.bucket_name}）:")
            print("-" * 60)
            images = generator.list_available_images()
            if images:
                for img in images:
                    print(f"  {img}")
            else:
                print("  画像ファイルが見つかりません")
            print()
            return

        # 署名付きURL生成
        image_filename = sys.argv[1]
        result = generator.generate_presigned_url(image_filename)

        # 結果を表示
        print("\n" + "=" * 80)
        print("署名付きURL生成成功")
        print("=" * 80)
        print(f"オブジェクトキー: {result['object_key']}")
        print(f"有効期限: {result['expires_in_seconds']}秒 ({result['expires_in_seconds'] // 60}分)")
        print(f"期限切れ日時: {result['expires_at']}")
        print("\n署名付きURL:")
        print("-" * 80)
        print(result['url'])
        print("-" * 80)
        print("\nこのURLは上記の有効期限まで使用できます。")
        print("=" * 80 + "\n")

    except FileNotFoundError as e:
        print(f"\nエラー: {e}")
        print("\n利用可能な画像を確認するには:")
        print("  python generate_presigned_url.py --list\n")
        sys.exit(1)
    except ValueError as e:
        print(f"\n設定エラー: {e}")
        print("`.env` ファイルを確認してください。\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n予期しないエラー: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

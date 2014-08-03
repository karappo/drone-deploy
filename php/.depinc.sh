#!/bin/bash

# for PHP website deploy

before_sync(){

  # backup file's extention
  # 置換する際に一時的に作成するバックアップファイルの拡張子
  ext=".temp_bakup"

  # .htaccess内の「#RM_SYNC_REMOTE 」コメントを消去
  find . -name "*.htaccess" -exec sed -i$ext "s|#RM_SYNC_REMOTE ||" {} \;

  # php内の「//RM_SYNC_REMOTE 」コメントを消去
  find . -name "*.php" -exec sed -i$ext "s|//RM_SYNC_REMOTE ||" {} \;

  # バックファイルを削除
  find . -name "*$ext" -exec rm {} \;

  return
}

#!/bin/bash

# for PHP website deploy

before_sync(){

  # backup file's extention
  # 置換する際に一時的に作成するバックアップファイルの拡張子
  ext=".temp_bakup"

  # .htaccess
  find . -name "*.htaccess" -exec sed -i$ext "s|#RM_SYNC_REMOTE ||" {} \; # 「#RM_SYNC_REMOTE 」コメントを消去
  find . -name "*.htaccess" -exec sed -i$ext "s|#RM_SYNC_${DRONE_BRANCH^^} ||" {} \; # 「#RM_SYNC_[BRANCH] 」コメントを消去

  # php
  find . -name "*.php" -exec sed -i$ext "s|//RM_SYNC_REMOTE ||" {} \; #「//RM_SYNC_REMOTE 」コメントを消去
  find . -name "*.php" -exec sed -i$ext "s|//RM_SYNC_${DRONE_BRANCH^^} ||" {} \; #「//RM_SYNC_[BRANCH] 」コメントを消去

  # バックファイルを削除
  find . -name "*$ext" -exec rm {} \;

  return
}

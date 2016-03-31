#!/bin/bash

# for PHP website deploy

before_sync(){

  # backup file's extention
  # 置換する際に一時的に作成するバックアップファイルの拡張子
  ext=".temp_bakup"

  # .htaccess
  sudo find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_REMOTE_RM ||" {} \; # 「#DEP_REMOTE_RM 」コメントを消去
  sudo find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_${DRONE_BRANCH^^}_RM ||" {} \; # 「#DEP_[BRANCH]_RM 」コメントを消去

  # php
  sudo find . -name "*.php" -exec sed -i$ext "s|//DEP_REMOTE_RM ||" {} \; #「//DEP_REMOTE_RM 」コメントを消去
  sudo find . -name "*.php" -exec sed -i$ext "s|//DEP_${DRONE_BRANCH^^}_RM ||" {} \; #「//DEP_[BRANCH]_RM 」コメントを消去

  # バックファイルを削除
  sudo find . -name "*$ext" -exec rm {} \;

  return
}

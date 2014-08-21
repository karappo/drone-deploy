#!/bin/bash

# for MODX deploy

# 不用意にテンプレートファイルをそのまま実行しないようにしている
# [TODO] TODOタグの箇所を書き換えたら下記のを削除
# ----------------------------------------------------------------
echo "[DEPLOY] - ERROR -> Template file has included !!"
exit 1
# ----------------------------------------------------------------

before_sync(){

  # backup file's extention
  # 置換する際に一時的に作成するバックアップファイルの拡張子
  ext=".temp_bakup"

  # [TODO]
  # # 不要なファイルの消去
  rm -rf ./core/cache/*

  # .htaccess
  find . -name "*.htaccess" -exec sed -i$ext "s|#RM_SYNC_REMOTE ||" {} \; # 「#RM_SYNC_REMOTE 」コメントを消去
  find . -name "*.htaccess" -exec sed -i$ext "s|#RM_SYNC_${DRONE_BRANCH^^} ||" {} \; # 「#RM_SYNC_[BRANCH] 」コメントを消去

  # php
  find . -name "*.php" -exec sed -i$ext "s|//RM_SYNC_REMOTE ||" {} \; #「//RM_SYNC_REMOTE 」コメントを消去
  find . -name "*.php" -exec sed -i$ext "s|//RM_SYNC_${DRONE_BRANCH^^} ||" {} \; #「//RM_SYNC_[BRANCH] 」コメントを消去
  
  # [TODO]
  # ファイルディレクトリをリモート用に変換。「/Users/terada/Sites/example.com」の部分を適宜設定すること
  find . -name "*.php" -exec sed -i$ext "s|/Users/terada/Sites/example.com|$DEP_HOST|g" {} \;

  # [TODO]
  # 「localhost」をリモート用に変換
  find . -name "*.php" -exec sed -i$ext "s|localhost|$DEP_HOST|g" {} \;

  # [TODO]
  # （任意）
  # リモートのDBサーバーへのアクセスが「localhost」のみの場合はもう一度元に戻しておく
  # find . -name "*config.inc.php" -exec sed -i".temp_bakup" "s|database_server = '$DEP_HOST';|database_server = 'localhost';|" {} \;
  # find . -name "*config.inc.php" -exec sed -i".temp_bakup" "s|database_dsn = 'mysql:host=$DEP_HOST;|database_dsn = 'mysql:host=localhost;|" {} \;
  
  # バックファイルを削除
  find . -name "*$ext" -exec rm {} \;

  return
}

# after_sync(){
#   # phpMyAdminへのシンボリックリンクがある場合に再作成
#   # ssh $DEP_USER@$DEP_HOST "ln -s /usr/local/phpMyAdmin $DEP_HOST_DIR/mysqladmin"
#   return
# }

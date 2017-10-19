#!/bin/bash

# for MODX deploy

# 不用意にテンプレートファイルをそのまま実行しないようにしている
# [TODO] TODOタグの箇所を書き換えたら下記のを削除
# ----------------------------------------------------------------
echo "[DEPLOY] - ERROR -> Template file has included !!"
exit 1
# ----------------------------------------------------------------

before_sync(){

  # extension of backup files which are created before replacement
  ext=".temp_bakup"

  # [TODO]
  # # 不要なファイルの消去
  rm -rf ./core/cache/*

  # remove "DEP_XXX_RM "
  sudo find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_REMOTE_RM ||" {} \;
  sudo find . -name "*.htaccess" -exec sed -i$ext "s|#RM_SYNC_${DRONE_BRANCH^^} ||" {} \;
  sudo find . -name "*.php" -exec sed -i$ext "s|//DEP_REMOTE_RM ||" {} \;
  sudo find . -name "*.php" -exec sed -i$ext "s|//DEP_${DRONE_BRANCH^^}_RM ||" {} \;

  # [TODO]
  # ファイルディレクトリをリモート用に変換。「/Users/terada/Sites/example.com」と「/home/remote/example.com」の部分を適宜設定すること
  sudo find . -name "*.php" -exec sed -i$ext "s|/Users/terada/Sites/example.com|/home/remote/example.com|g" {} \;

  # [TODO]
  # 「localhost」をリモート用に変換
  sudo find . -name "*.php" -exec sed -i$ext "s|localhost|$DEP_HOST|g" {} \;

  # [TODO]
  # （任意）
  # リモートのDBサーバーへのアクセスが「localhost」のみの場合はもう一度元に戻しておく
  # sudo find . -name "*config.inc.php" -exec sed -i".temp_bakup" "s|database_server = '$DEP_HOST';|database_server = 'localhost';|" {} \;
  # sudo find . -name "*config.inc.php" -exec sed -i".temp_bakup" "s|database_dsn = 'mysql:host=$DEP_HOST;|database_dsn = 'mysql:host=localhost;|" {} \;

  # delete backup files
  sudo find . -name "*$ext" -exec rm {} \;

  return
}

# after_sync(){
#   # phpMyAdminへのシンボリックリンクがある場合に再作成
#   # ssh $DEP_USER@$DEP_HOST "ln -s /usr/local/phpMyAdmin $DEP_HOST_DIR/mysqladmin"
#   return
# }

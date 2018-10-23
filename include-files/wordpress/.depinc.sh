#!/bin/bash

# for WordPress website deploy (need SSH)

before_sync(){

  # extension of backup files which are created before replacement
  ext=".temp_bakup"

  # remove "DEP_XXX_RM "
  find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_REMOTE_RM ||" {} \;
  find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_${DRONE_BRANCH^^}_RM ||" {} \;
  find . -name "*.php" -exec sed -i$ext "s|//DEP_REMOTE_RM ||" {} \;
  find . -name "*.php" -exec sed -i$ext "s|//DEP_${DRONE_BRANCH^^}_RM ||" {} \;

  # delete backup files
  find . -name "*$ext" -exec rm {} \;

  return
}

after_sync(){
  sh -c "echo '
cd '${DEP_HOST_DIR}'

# Set permissions
find ./ -type d -exec chmod 705 {} \;
find ./ -type f -exec chmod 604 {} \;
find ./ -name .htaccess -exec chmod 604 {} \;
find ./ -name wp-config.php -exec chmod 400 {} \;

echo ''
echo --- Check Permissions -----------
stat -f \"%N %Mp%Lp\" .htaccess
stat -f \"%N %Mp%Lp\" wp/wp-config.php
stat -f \"%N %Mp%Lp\" wp/wp-content/plugins
stat -f \"%N %Mp%Lp\" wp/wp-content/themes
stat -f \"%N %Mp%Lp\" wp/wp-content/uploads
echo ---------------------------------
echo ''
' > script.sh"
  if [ "${DEP_PORT:+isexists}" = "isexists" ]; then
    ssh $DEP_USER@$DEP_HOST -p $DEP_PORT 'bash -s' < script.sh
  else
    ssh $DEP_USER@$DEP_HOST 'bash -s' < script.sh
  fi
  rm -f script.sh
}

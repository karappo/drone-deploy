#!/bin/bash

# for WordPress website deploy (need SSH)

before_sync(){

  # extension of backup files which are created before replacement
  ext=".temp_bakup"

  # remove "DEP_XXX_RM "
  sudo find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_REMOTE_RM ||" {} \;
  sudo find . -name "*.htaccess" -exec sed -i$ext "s|#DEP_${DRONE_BRANCH^^}_RM ||" {} \;
  sudo find . -name "*.php" -exec sed -i$ext "s|//DEP_REMOTE_RM ||" {} \;
  sudo find . -name "*.php" -exec sed -i$ext "s|//DEP_${DRONE_BRANCH^^}_RM ||" {} \;

  # delete backup files
  sudo find . -name "*$ext" -exec rm {} \;

  return
}

after_sync(){
  sudo sh -c "echo '
cd '${DEP_HOST_DIR}'

# Set permissions
find ./ -type d -exec chmod 705 {} \;
find ./ -type f -exec chmod 604 {} \;
chmod 604 .htaccess
chmod 400 wp/wp-config.php

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
  ssh $DEP_USER@$DEP_HOST 'bash -s' < script.sh
  sudo rm -f script.sh
}

#!/bin/bash

# for PHP website deploy

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

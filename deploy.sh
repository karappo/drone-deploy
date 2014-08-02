#!/bin/bash

# for sed's "RE error: illegal byte sequence"
# LANG=C
# NOLOCALE=1

# ----------------
# methods

do_sync()
{
  if type before_sync 1>/dev/null 2>/dev/null; then
    # detect before_sync method
    echo -n '| Processing "before_sync" ... '
    before_sync
    echo 'done.'
  fi
    
  echo "| Syncing with $DEP_COMMAND. This could take a while..."

  # download defaults if ignore file isn't exists
  if [ ${DEP_IGNORE_FILE:-isnil} = "isnil" -o ! -f "$DEP_IGNORE_FILE" ]; then
    echo '| Downloading default ignore file...'
    wget https://raw.githubusercontent.com/KarappoInc/deploy/master/.depignore
    DEP_IGNORE_FILE=$PWD/.depignore
  fi

  if [ "$DEP_COMMAND" = "rsync" ]; then
    
    opt_exclude=''
    if [ -f $DEP_IGNORE_FILE ]; then
      opt_exclude="--exclude-from=$DEP_IGNORE_FILE"
    fi
    rsync -aIzhv --stats --delete -e ssh $opt_exclude . $DEP_USER@$DEP_HOST:$DEP_HOST_DIR

  else

    opt_exclude=""
    while read line; do
      # TODO: allow commentout in the middle of line

      if [ "${line:0:1}" = "/" ]; then
        # /xxx/yyy -> xxx/yyy
        opt_exclude="$opt_exclude -X ${line:1}"
      elif [ "${line:0:1}" != "#" -a "$line" != "" ]; then
        opt_exclude="$opt_exclude -X $line"
      fi
    done<$DEP_IGNORE_FILE

    opt_setting=""
    if [ "$FTPS" = "no" ]; then
      echo '< FTP >'
      opt_setting="set ftp:ssl-allow off;"
    else
      # TODO: chanto FTPS ni natteruka kakunin
      echo '< FTPS >'
      opt_setting="set ftp:ssl-auth TLS;set ftp:ssl-force true;set ftp:ssl-allow yes;set ftp:ssl-protect-list yes;set ftp:ssl-protect-data yes;set ftp:ssl-protect-fxp yes;"
    fi

    sudo apt-get install lftp
    lftp -u $DEP_USER,$DEP_PASSWORD -e "$opt_setting;pwd;mirror -evR --parallel=10 $opt_exclude ./ $DEP_HOST_DIR;exit" $DEP_HOST
  
  fi
  
  echo '| Syncing ... done.'

  if type after_sync 1>/dev/null 2>/dev/null; then
    # detect after_sync method
    echo -n '| Processing "after_sync" ... '
    after_sync
    echo 'done.'
  fi
}

# ----------------
# check parameters

NECESSARY_PARAMS=(DEP_COMMAND DEP_HOST DEP_USER DEP_HOST_DIR)

for item in ${NECESSARY_PARAMS[@]}; do
  eval 'val=${'$item'}'
  if [ ! $val ]; then
    echo "[DEPLOY ERROR] Not defined: $item"
    exit 1
  fi
done

if [ "$DEP_COMMAND" = "rsync" -a "${DEP_HOST_DIR:0:1}" != "/" ]; then
  echo "[DEPLOY ERROR] DEP_HOST_DIR must be absolute path: $DEP_HOST_DIR"
  exit 1
fi

# ----------------
# main

do_sync

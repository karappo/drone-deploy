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
    
  echo "| Syncing with $SYNC_COMMAND. This could take a while..."
  
  if [ ${SYNC_COMMAND} = "rsync" ]; then
    
    opt_exclude=''
    if [ -f $SYNC_IGNORES ]; then
      opt_exclude="--exclude-from=$SYNC_IGNORES"
    fi
    rsync -aIzhv --stats --delete -e ssh $opt_exclude . $SYNC_USER@$SYNC_HOST:$SYNC_HOST_DIR

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
    done<${SYNC_IGNORES}

    opt_setting=""
    if [ $FTPS = "no" ]; then
      echo '< FTP >'
      opt_setting="set ftp:ssl-allow off;"
    else
      # TODO: chanto FTPS ni natteruka kakunin
      echo '< FTPS >'
      opt_setting="set ftp:ssl-auth TLS;set ftp:ssl-force true;set ftp:ssl-allow yes;set ftp:ssl-protect-list yes;set ftp:ssl-protect-data yes;set ftp:ssl-protect-fxp yes;"
    fi

    sudo apt-get install lftp
    lftp -u $SYNC_USER,$SYNC_PW -e "$opt_setting;pwd;mirror -evR --parallel=10 $opt_exclude ./ $SYNC_HOST_DIR;exit" $SYNC_HOST
  
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

NECESSARY_PARAMS=(SYNC_COMMAND SYNC_HOST SYNC_USER SYNC_HOST_DIR)

for item in ${NECESSARY_PARAMS[@]}; do
  eval 'val=${'$item'}'
  if [ ! $val ]; then
    echo "[ERROR] Not defined: $item"
    exit 1
  fi
done

if [ $SYNC_COMMAND = "rsync" -a "${SYNC_HOST_DIR:0:1}" != "/" ]; then
  echo "[ERROR] SYNC_HOST_DIR must be absolute: $SYNC_HOST_DIR"
  exit 1
fi

# ----------------
# main

do_sync

#!/bin/bash

# ----------------
# methods


# ログ出力の先頭に付加するラベル
log_label="[DEPLOY] "
log()
{
  echo "$log_label$1"
}


do_sync()
{
  # ----------------
  # Before Sync

  if type before_sync 1>/dev/null 2>/dev/null; then
    # detect before_sync method
    echo -n "$log_label- before_sync -> Processing..."
    before_sync
    log " -> Done."
  fi

  # ----------------
  # Sync

  log "- sync -> Start with $DEP_COMMAND. This could take a while..."

  # download defaults if ignore file isn't exists
  if [ ${DEP_IGNORE_FILE:-isnil} = "isnil" -o ! -f "$DEP_IGNORE_FILE" ]; then
    log "| Downloading default ignore file..."
    wget -O .depignore https://raw.githubusercontent.com/KarappoInc/drone-deploy/master/.depignore
    DEP_IGNORE_FILE=$PWD/.depignore
  fi

  log "- ignore file -> $DEP_IGNORE_FILE"

  if [ "$DEP_COMMAND" = "rsync" ]; then

    # ------ install -------
    if [ `which ssh-askpass` ]; then
      log "- ssh-askpass -> installed"
    else
      log "- ssh-askpass -> install"
      sudo apt-get install ssh-askpass
    fi

    if [ -f $DEP_PASSWORD ]; then
      if [ `which sshpass` ]; then
        log "- sshpass -> installed"
      else
        log "- sshpass -> install"
        sudo apt-get install sshpass
      fi
    fi
    # ------ /install -------

    opt_exclude=''
    if [ -f $DEP_IGNORE_FILE ]; then
      opt_exclude="--exclude-from=$DEP_IGNORE_FILE"
    fi


    RSYNC_COMMAND=rsync -aIzhv --stats --delete -e ssh $opt_exclude . $DEP_USER@$DEP_HOST:$DEP_HOST_DIR

    # WITH password
    if [ -f $DEP_PASSWORD ]; then
      RSYNC_COMMAND=sshpass -p $DEP_PASSWORD $RSYNC_COMMAND
    fi

    if $RSYNC_COMMAND; then
      log "- sync -> done."
    else
      log "- sync -> [ERROR]"
      exit 1
    fi

  else

    # ------ install -------
    if [ `which lftp` ]; then
      log "- lftp -> installed"
    else
      log "- lftp -> install"
      sudo apt-get install lftp
    fi
    # ------ /install -------

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
    if [ "$DEP_FTPS" = "no" ]; then
      log "- sync -> via FTP"
      opt_setting="set ftp:ssl-allow off;"
    else
      # TODO: chanto FTPS ni natteruka kakunin
      log "- sync -> via FTPS"
      opt_setting="set ftp:ssl-auth TLS;set ftp:ssl-force true;set ftp:ssl-allow yes;set ftp:ssl-protect-list yes;set ftp:ssl-protect-data yes;set ftp:ssl-protect-fxp yes;"
    fi

    if lftp -u $DEP_USER,$DEP_PASSWORD -e "$opt_setting;pwd;mirror -evR --parallel=10 $opt_exclude ./ $DEP_HOST_DIR;exit" $DEP_HOST; then
      log "- sync -> done."
    else
      log "- sync -> [ERROR]"
      exit 1
    fi

  fi

  # ----------------
  # After Sync

  if type after_sync 1>/dev/null 2>/dev/null; then
    # detect after_sync method
    echo -n "$log_label- after_sync -> Processing... "
    after_sync
    log " -> Done."
  fi
}

# ----------------
# check parameters

ALL_PARAMS=(COMMAND FTPS HOST USER PASSWORD HOST_DIR INCLUDE_FILE IGNORE_FILE)

# log '-'
# log "$DEP_${DRONE_BRANCH^^}_COMMAND"
# log '-'
# log $DEP_2015MASTER_COMMAND
# log '-'
# log '$DEP_'${DRONE_BRANCH^^}'_COMMAND'
# log '-'
# log 'DEP_'${DRONE_BRANCH^^}'_COMMAND'
# log '-'
# if [ '$DEP_'${DRONE_BRANCH^^}'_COMMAND' = "rsync" ]; then
#   log '-----1'
#   NECESSARY_PARAMS=(HOST USER HOST_DIR)
# else
#   log '-----2'
#   NECESSARY_PARAMS=(HOST USER PASSWORD HOST_DIR)
# fi
NECESSARY_PARAMS=(HOST USER HOST_DIR)

for param in ${NECESSARY_PARAMS[@]}; do
  branch_param='DEP_'${DRONE_BRANCH^^}'_'$param
  eval 'val=${'$branch_param'}'
  if [ ! $val ]; then
    log '- ERROR -> Not defined necessary parameter: '$branch_param
    exit 1
  fi
done

# ----------------
# casting all parameters
# e.g. DEP_COMMAND=${DEP_MASTER_COMMAND}

for param in ${ALL_PARAMS[@]}; do
  branch_param='DEP_'${DRONE_BRANCH^^}'_'$param
  eval 'val=${'$branch_param'}'
  if [ $val ]; then
    eval 'DEP_'$param'='$val
  fi
done


# ----------------
# default value

if [ ${DEP_COMMAND:-isnil} = "isnil" ]; then
  DEP_COMMAND=lftp
fi

# ----------------
# main

if [ "$DEP_COMMAND" = "rsync" -a "${DEP_HOST_DIR:0:1}" != "/" ]; then
  log "- ERROR -> DEP_HOST_DIR must be absolute path: $DEP_HOST_DIR"
  exit 1
fi

# include file

# from web
if [ ${DEP_INCLUDE_FILE:+isexists} = "isexists" ]; then
  if [ "${DEP_INCLUDE_FILE:0:7}" = "http://" -o "${DEP_INCLUDE_FILE:0:8}" = "https://" ]; then
    log "| Downloading include file..."
    wget -O .depinc.sh $DEP_INCLUDE_FILE
    DEP_INCLUDE_FILE=$PWD/.depinc.sh
  fi
fi

if [ ${DEP_INCLUDE_FILE:-isnil} = "isnil" -o ! -f "$DEP_INCLUDE_FILE" ]; then
  log "- include file -> Detect failed..."
else
  log "- include file -> Detect : $DEP_INCLUDE_FILE"
  source $DEP_INCLUDE_FILE
fi

do_sync

exit 0
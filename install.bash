#!/bin/bash
# (C) 2013 - July - 05
# Nathaniel Hellabyte
# nate@hellabit.es
# RECOMMENDED USAGE
#   bash ./install.bash
# INSTALLS quick-cd.bash
# TO       /usr/local/lib 
#          /usr/local/bin
#          $HOME/.bashrc
#          $HOME/.quick-cd
# CHECKS   before overwrite
# BACKUPS  $FUNCTIONS_TARGET 
# = = = = = = = = = = = = = =-

USER_HOME=$(eval echo ~${SUDO_USER})
PROGRAM_RAW="$(pwd)/quick-cd.bash"
FUNCTIONS_RAW="$(pwd)/functions.bash"
PROGRAM_TARGET_LIB="/usr/local/lib/quick-cd"
PROGRAM_TARGET_BIN="/usr/local/bin/quick-cd"
NEW_HOME_DIR="${USER_HOME}/.quick-cd"
GENERAL_DIR="${NEW_HOME_DIR}/.general_dirs"
QUERIED_DIR="${NEW_HOME_DIR}/.queried_dirs"
FUNCTIONS_SOURCE_TARGET="${USER_HOME}/.bashrc"
FUNCTIONS_TARGET_BACKUP="${NEW_HOME_DIR}/.backups"
FUNCTIONS_TARGET="${FUNCTIONS_TARGET_BACKUP}/.supporting_rc.bash"
FUNCTIONS_TEMP="${FUNCTIONS_TARGET_BACKUP}/.supporting_rc_temp"

[[ -f $PROGRAM_RAW ]] || ( echo "Please change into directory containing install files" >&2 && exit 3 )

if [ ! -d $NEW_HOME_DIR ]; then
    mkdir -p $NEW_HOME_DIR
fi
if [ ! -d $FUNCTIONS_TARGET_BACKUP ]; then
    mkdir -p $FUNCTIONS_TARGET_BACKUP
fi

touch $GENERAL_DIR $QUERIED_DIR
cp $FUNCTIONS_SOURCE_TARGET "${FUNCTIONS_TARGET_BACKUP}"

if [ -f $PROGRAM_TARGET_LIB ]; then
    echo "WARNING--${PROGRAM_TARGET_LIB} ALREADY EXISTS."
    while true; do
        read -p "overwrite? [y/n]: " OVERWRITE_DECISION || exit
        if [ "$OVERWRITE_DECISION" == 'y' ]; then
            rm $PROGRAM_TARGET_LIB
            break
        else
            echo "Choosing to quit because of overwrite potential."
            exit 1
        fi
    done
fi

if [ -f $FUNCTIONS_SOURCE_TARGET ]; then
    BEG_FLAG="# BEGIN QUICK-CD FUNCTIONS"
    END_FLAG="# END QUICK-CD FUNCTIONS"
    BEG_FLAG_LINE_NUMBER=$(grep -n "$BEG_FLAG" $FUNCTIONS_SOURCE_TARGET | cut -f 1 -d ':')
    END_FLAG_LINE_NUMBER=$(grep -n "$END_FLAG" $FUNCTIONS_SOURCE_TARGET | cut -f 1 -d ':')
    read -a BLN -d ' ' < <(echo "${BEG_FLAG_LINE_NUMBER[@]}")
    read -a ELN -d ' ' < <(echo "${END_FLAG_LINE_NUMBER[@]}")
    BIN=0; EIN=$((${#ELN[@]} - 1))
    if [ ${#BLN[@]} -eq ${#ELN[@]} ]; then
        if [ $EIN -ne -1 ]; then
            sed "${BLN[$BIN]},${ELN[$EIN]}d" $FUNCTIONS_SOURCE_TARGET > $FUNCTIONS_TEMP
            mv $FUNCTIONS_TEMP $FUNCTIONS_SOURCE_TARGET
        fi
    else
        echo "WARNING -- Manual tidying of $FUNCTIONS_SOURCE_TARGET required." >&2
    fi
fi

cp $PROGRAM_RAW $PROGRAM_TARGET_LIB || exit 72
chmod 744 $PROGRAM_TARGET_LIB || exit 73
if [ -f $PROGRAM_TARGET_BIN ]; then
    rm $PROGRAM_TARGET_BIN | exit 75
fi
ln -s $PROGRAM_TARGET_LIB $PROGRAM_TARGET_BIN || exit 77
cp $FUNCTIONS_RAW $FUNCTIONS_TARGET || exit 78
cat << EOF >> $FUNCTIONS_SOURCE_TARGET 
# BEGIN QUICK-CD FUNCTIONS
# DO NOT DELETE ABOVE COMMENT
[[ -f "$FUNCTIONS_TARGET" ]] && builtin source "$FUNCTIONS_TARGET"
# DO NOT DELETE BELOW COMMENT
# END QUICK-CD FUNCTIONS
EOF

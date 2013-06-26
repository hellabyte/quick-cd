#!/bin/bash
# (C) 2013 - June - 26
# Nathaniel Hellabyte
# nate@hellabit.es
# RECOMMENDED USAGE
#   bash -c ./install.bash
# INSTALLS quick-cd.bash
# TO       /usr/local/lib 
#          /usr/local/bin
#          $HOME/.bashrc
#          $HOME/.quick-cd
# CHECKS   before overwrite
# BACKUPS  $FUNCTIONS_TARGET 
# = = = = = = = = = = = = = =-

PROGRAM_RAW="$(pwd)/quick-cd.bash"
PROGRAM_TARGET="/usr/local/bin/quick-cd"
FUNCTIONS_RAW="$(pwd)/functions.bash"
FUNCTIONS_TARGET="${HOME}.bashrc"
FUNCTIONS_TEMP="${HOME}.bashrctemp"
NEW_HOME_DIR="${HOME}/.quick-cd"
GENERAL_DIR="${NEW_HOME_DIR}/.general_dirs"
QUERIED_DIR="${NEW_HOME_DIR}/.queried_dirs"
FUNCTIONS_TARGET_BACKUP="${NEW_HOME_DIR}/.backups"

if [ ! -d $NEW_HOME_DIR ]; then
    mkdir -p $NEW_HOME_DIR
fi
if [ ! -d $FUNCTIONS_TARGET_BACKUP ]; then
    mkdir -p $FUNCTIONS_TARGET_BACKUP
fi

touch $GENERAL_DIR $QUERIED_DIR
cp $FUNCTIONS_TARGET "${FUNCTIONS_TARGET_BACKUP}"

if [ -f $PROGRAM_TARGET ]; then
    echo "WARNING--${PROGRAM_TARGET} ALREADY EXISTS."
    while true; do
        read -p "overwrite? [y/n]: " OVERWRITE_DECISION || return
        if [ "$OVERWRITE_DECISION" == 'y' ]; then
            rm $PROGRAM_TARGET
            break
        else
            echo "Choosing to quit because of overwrite potential."
            exit 1
        fi
    done
fi

if [ -f $FUNCTIONS_TARGET ]; then
    BEG_FLAG="# BEGIN QUICK-CD FUNCTIONS"
    END_FLAG="# END QUICK-CD FUNCTIONS"
    BEG_FLAG_LINE_NUMBER=$(grep -n "$BEG_FLAG" $FUNCTIONS_TARGET | cut -f 1 -d ':')
    END_FLAG_LINE_NUMBER=$(grep -n "$END_FLAG" $FUNCTIONS_TARGET | cut -f 1 -d ':')
    if [ ! -z $BEG_FLAG_LINE_NUMBER ]; then
        if [ ! -z $END_FLAG_LINE_NUMBER ]; then
            BLN=$BEG_FLAG_LINE_NUMBER; ELN=$END_FLAG_LINE_NUMBER;
            sed "${BLN},${ELN}d" $FUNCTIONS_TARGET > $FUNCTIONS_TEMP
            mv $FUNCTIONS_TEMP $FUNCTIONS_TARGET
        fi
    fi
fi

chmod 744 $PROGRAM_RAW
ln -s $PROGRAM_RAW $PROGRAM_TARGET
cat $FUNCTIONS_RAW >> $FUNCTIONS_TARGET

builtin source $FUNCTIONS_TARGET

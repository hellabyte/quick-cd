#!/bin/bash
# (C) 2014 - January - 12
# Nathaniel Hellabyte
# nate@hellabit.es
# RECOMMENDED USAGE
#   bash ./install.bash [PREFIX]
# default PREFIX=/usr/local
# INSTALLS quick-cd.bash
# TO       [PREFIX]/lib 
#          [PREFIX]/bin
#          $HOME/.bashrc
#          $HOME/.quick-cd
# CHECKS   before overwrite
# BACKUPS  $FUNCTIONS_TARGET 
# = = = = = = = = = = = = = =-
USER_HOME=$(eval echo ~${SUDO_USER})
PROGRAM_RAW="$(pwd)/quick-cd.bash"
FUNCTIONS_RAW="$(pwd)/functions.bash"
PREFIX=${1:-"/usr/local"}
PROGRAM_TARGET_LIB="${PREFIX}/lib/quick-cd"
PROGRAM_TARGET_BIN="${PREFIX}/bin/quick-cd"
NEW_HOME_DIR="${USER_HOME}/.quick-cd"
GENERAL_DIR="${NEW_HOME_DIR}/.general_dirs"
QUERIED_DIR="${NEW_HOME_DIR}/.queried_dirs"
FUNCTIONS_SOURCE_TARGET="${USER_HOME}/.bashrc"
FUNCTIONS_TARGET_BACKUP="${NEW_HOME_DIR}/.backups"
FUNCTIONS_TARGET="${FUNCTIONS_TARGET_BACKUP}/.supporting_rc.bash"
FUNCTIONS_TARGET_STRING="\${HOME}/.quick-cd/.backups/.supporting_rc.bash"
FUNCTIONS_SOURCE_TARGET_STRING="\${HOME}/.bashrc"
FUNCTIONS_TEMP="${FUNCTIONS_TARGET_BACKUP}/.supporting_rc_temp"
FUNCTIONS_SOURCE_SUPPORT="${USER_HOME}/.bash_profile"
CLIENT_KERNEL="$(uname -s | awk '{print tolower($0)}')"

if [[ $CLIENT_KERNEL == linux* ]]; then
    echo "If you do not have sudo access, consider creating the directory"
    echo -e "\t${HOME}/.local"
    echo "And passing it to the installer as so:"
    echo -e "\t\$ bash install.bash ${HOME}/.local"
    echo "It is recommended to install with sudo, otherwise."
    sleep 1
fi


[[ -f $PROGRAM_RAW ]] || (  
        echo "Please change into directory containing install files" >&2 && 
            exit 29 
    )

[[ ! -d $NEW_HOME_DIR ]] && mkdir -p $NEW_HOME_DIR || :
chmod 700 $NEW_HOME_DIR
[[ ! -d $FUNCTIONS_TARGET_BACKUP ]] && mkdir -p $FUNCTIONS_TARGET_BACKUP || :

touch $GENERAL_DIR $QUERIED_DIR
cp $FUNCTIONS_SOURCE_TARGET "${FUNCTIONS_TARGET_BACKUP}"

function installer {
    if [[ -f $PROGRAM_TARGET_LIB ]]; then
        echo "WARNING--${PROGRAM_TARGET_LIB} ALREADY EXISTS."
        while true; do
            read -p "overwrite? [y/n]: " OVERWRITE_DECISION || exit
            if [[ "$OVERWRITE_DECISION" == 'y' ]]; then
                rm $PROGRAM_TARGET_LIB
                break
            else
                echo "Choosing to quit because of overwrite potential."
                exit 1
            fi
        done
    fi

    if [[ -f $FUNCTIONS_SOURCE_TARGET ]]; then
        BEG_FLAG="# BEGIN QUICK-CD FUNCTIONS"
        END_FLAG="# END QUICK-CD FUNCTIONS"
        BEG_FLAG_LINE_NUMBER=$(
            grep -n "$BEG_FLAG" $FUNCTIONS_SOURCE_TARGET | cut -f 1 -d ':'
        )
        END_FLAG_LINE_NUMBER=$(
            grep -n "$END_FLAG" $FUNCTIONS_SOURCE_TARGET | cut -f 1 -d ':'
        )
        read -a BLN -d ' ' < <(echo "${BEG_FLAG_LINE_NUMBER[@]}")
        read -a ELN -d ' ' < <(echo "${END_FLAG_LINE_NUMBER[@]}")
        BIN=0; EIN=$((${#ELN[@]} - 1))
        if [[ ${#BLN[@]} -eq ${#ELN[@]} ]]; then
            if [[ $EIN -ne -1 ]]; then
                sed "${BLN[$BIN]},${ELN[$EIN]}d" $FUNCTIONS_SOURCE_TARGET > $FUNCTIONS_TEMP
                mv $FUNCTIONS_TEMP $FUNCTIONS_SOURCE_TARGET
            fi
        else
            echo "WARNING -- Manual tidying of $FUNCTIONS_SOURCE_TARGET required." >&2
        fi
    fi

    cp $PROGRAM_RAW $PROGRAM_TARGET_LIB || exit 72
    chmod 755 $PROGRAM_TARGET_LIB || exit 73
    [[ -f $PROGRAM_TARGET_BIN ]] && ( rm $PROGRAM_TARGET_BIN || exit 75 )
    ln -s $PROGRAM_TARGET_LIB $PROGRAM_TARGET_BIN || exit 77
    cp $FUNCTIONS_RAW $FUNCTIONS_TARGET || exit 78
    cat << ____EOF >> $FUNCTIONS_SOURCE_TARGET 
# BEGIN QUICK-CD FUNCTIONS
# DO NOT DELETE ABOVE COMMENT
[[ -f "$FUNCTIONS_TARGET_STRING" ]] && \\
    builtin source "$FUNCTIONS_TARGET_STRING" || :
# DO NOT DELETE BELOW COMMENT
# END QUICK-CD FUNCTIONS
____EOF
    builtin source $FUNCTIONS_SOURCE_TARGET
}

function function_support_linker {
    echo "quick-cd resides as an alias in ${FUNCTIONS_SOURCE_TARGET}."
    echo "In order to work properly, ${FUNCTIONS_SOURCE_TARGET} must"
    echo "be sourced by the files sourced by BASH environments."
    echo "Linking now..."

    if [[ -f $FUNCTIONS_SOURCE_SUPPORT ]]; then
        BEG_FLAG="# BEGIN QUICK-CD SUPPORT"
        END_FLAG="# END QUICK-CD SUPPORT"
        BEG_FLAG_LINE_NUMBER=$(grep -n "$BEG_FLAG" $FUNCTIONS_SOURCE_SUPPORT | cut -f 1 -d ':')
        END_FLAG_LINE_NUMBER=$(grep -n "$END_FLAG" $FUNCTIONS_SOURCE_SUPPORT | cut -f 1 -d ':')
        read -a BLN -d ' ' < <(echo "${BEG_FLAG_LINE_NUMBER[@]}")
        read -a ELN -d ' ' < <(echo "${END_FLAG_LINE_NUMBER[@]}")
        BIN=0; EIN=$((${#ELN[@]} - 1))
        if [[ ${#BLN[@]} -eq ${#ELN[@]} ]]; then
            if [[ $EIN -ne -1 ]]; then
                sed "${BLN[$BIN]},${ELN[$EIN]}d" $FUNCTIONS_SOURCE_SUPPORT > $FUNCTIONS_TEMP
                mv $FUNCTIONS_TEMP $FUNCTIONS_SOURCE_SUPPORT
            fi
        else
            echo "WARNING -- Manual tidying of $FUNCTIONS_SOURCE_SUPPORT required." >&2
        fi
    fi
    cat << ____EOF >> $FUNCTIONS_SOURCE_SUPPORT   
# BEGIN QUICK-CD SUPPORT -- DO NOT DELETE
[[ \$(uname -s) = "Darwin" ]] && \\
    [[ -f "$FUNCTIONS_SOURCE_TARGET_STRING" ]] && \\
        builtin source "$FUNCTIONS_SOURCE_TARGET_STRING" || :
# END QUICK-CD SUPPORT -- DO NOT DELETE
____EOF
}

if [[ ! -z $CLIENT_KERNEL ]]; then
    if [[ $CLIENT_KERNEL == darwin* ]]; then
        echo "INSTALLING..."
        installer
        echo "ADDING FUNCTION SUPPORT..."
        function_support_linker
    elif [[ $CLIENT_KERNEL == linux* ]] && [[ $PREFIX == /usr/local ]]; then
        echo "If you do not have sudo access, consider creating the directory"
        echo -e "\t${HOME}/.local"
        echo "And passing it to the installer as so:"
        echo -e "\t\$ bash install.bash ${HOME}/.local"
        echo "It is recommended to install with sudo, otherwise."
        sudo -p "${USER}, please provide your password to allow sudo: " installer
    elif [[ $CLIENT_KERNEL == linux* ]]; then
        echo "INSTALLING..."
        installer
    else
        echo "Operating System unrecognized." >&2 && exit 96
    fi
fi

echo 'Installation complete.'

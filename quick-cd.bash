#!/usr/bin/env bash
# (C) 2014 - January 12
# Nathaniel Hellabyte
# nate@hellabit.es
# = = = = = = = = = = =-

function print_help(){
    cat << ____EOF
NAME
    qcd -- quick change directory
SYNOPSIS
    qcd [-d <depth>] [-ap <path>] [-i <index>] [-t <time>] [-s] <searchterm>
DESCRIPTION
  MAIN PROGRAM LOOP:
        find \$BASEDIRS -maxdepth \$MAXDEPTH -type d -iname \$SEARCHTERM 
  OPTIONS
    -a 
        Appends directory specified to ${HOME}/.quick-cd/.general_dirs.
    -s
        Specifies which directory to find. RECOMMENDED: use when other flags are 
        implemented. Program will try to search for last option even if -s is 
        not passed. Note that program automatically wraps search term in 
        globs (*<searchterm>*).
    -d
        Specifies maximum depth to search from base, default value is 3.
        Less than 3 is usually too shallow, greater than 3 comprimises speed.
        It is better to pass a path with -p than to increase depth for large 
        filesystems. Note also that as qcd matures it's general directory 
        database, a lower depth will work more often.
    -p
        Specifies Path(s) to launch search from. The speed of target acquistion 
        is dependent on distance from base. To include multiple paths, enclose 
        in double quotes.
    -i
        Specifies which directory to switch to when multiple matches are found.
    -t 
        Specifies time given to select the currect directory from a multiple 
        matching. Default value is 30 seconds. Set to 0 to only print matches.
    -h
        Prints this help message.
____EOF
}
if [ $# == 0 ]; then
    echo "ERROR -- qcd requires arguments. Printing help text." >&2
    print_help
    return 1
fi
BASEDIRS=(); PATHS=()
MAXDEPTH=3; INDEX=-1; SEARCHTERM=""; TIME_OUT=30;
QUICKCD_HOME_ROOT="${HOME}/.quick-cd"
GENERAL_DIRS="${QUICKCD_HOME_ROOT}/.general_dirs"
QUERIED_DIRS="${QUICKCD_HOME_ROOT}/.queried_dirs"
TEMP_DIRS="${QUICKCD_HOME_ROOT}/.tdirs"
[[ ! -d $QUICKCD_HOME_ROOT ]] && mkdir $QUICKCD_HOME_ROOT || :
[[ ! -f $GENERAL_DIRS ]]      && touch $GENERAL_DIRS      || :
[[ ! -f $QUERIED_DIRS ]]      && touch $QUERIED_DIRS      || :

awk -F/ '{ if( $5 ) { print $2FS$3FS$4 } else { print } }' $GENERAL_DIRS | \
    sort -u > $TEMP_DIRS
while read LINE; do BASEDIRS+=("$LINE"); done < "${TEMP_DIRS}"
mv $TEMP_DIRS $GENERAL_DIRS

OPTIND=1
while getopts ":a:d:p:i:s:t:h" OPTNAME; do
    case $OPTNAME in
        'a')
            APPEND_DIR=$OPTARG
            if [[ -d $APPEND_DIR ]]; then
                echo "${OPTARG}" >> $GENERAL_DIRS
            else
                [[ -z $APPEND_DIR ]] && \
                    echo "No directory given for -a." >&2 && return 2
                echo "${OPTARG} is an invalid specification for -a" >&2 
                return 1
            fi
            ;;
        'd')
            MAXDEPTH=$OPTARG
            [[ -z $MAXDEPTH ]] && \
                echo "No depth given for -d." >&2 && return 2
            ;;
        'p')
            while read -r -d $'\0'; do
                BASEDIRS+=("$REPLY")
            done < <(printf "%s\0" "${OPTARG[@]}")
            ;;
        'i')
            INDEX=$OPTARG
            [[ -z $INDEX ]] && \
                echo "No index given for -i." >&2 && return 2
            if [[ $INDEX -gt -1 ]] && [[ -f $QUERIED_DIRS ]]; then
                while read LINE; do
                    PATHS+=("$LINE")
                done < "$QUERIED_DIRS"
                cd "${PATHS[$INDEX]}"
                return
            fi
            ;;
        's')
            SEARCHTERM="$OPTARG"
            [[ -z $SEARCHTERM ]] && \
                echo "No search term given for -s." >&2 && return 2
            SEARCHTERM="*${SEARCHTERM}*"
            ;;
        't') 
            TIME_OUT=$OPTARG
            [[ -z $TIME_OUT ]] && \
                echo "No time given for -t." >&2 && return 2
            ;;
        'h' ) 
            print_help
            return 5
            ;;
        : | ? | *)
            echo "Option -${OPTARG} requires an argument." >&2
            return 1
            ;;
    esac
    shift 2; OPTIND=1
done

if [[ -z "$SEARCHTERM" ]] && [[ -n "$@" ]]; then 
    SEARCHTERM="*${@}*"
else
    echo "No search term provided." >&2; return 1
fi

while read -r -d $'\0'; do
    PATHS+=("$REPLY")
done < <(find ${BASEDIRS[@]} -type d \
    -maxdepth $MAXDEPTH -iname "$SEARCHTERM" -print0 2> /dev/null)
# PATHS pruner
: > $QUERIED_DIRS
while read -d $'\0' QPATHNAME; do
    echo "$QPATHNAME" >> $QUERIED_DIRS
done < <(printf "%s\0" "${PATHS[@]}")
sort -u $QUERIED_DIRS > $TEMP_DIRS
PATHS=()
while read LINE; do
    PATHS+=("$LINE")
done < "$TEMP_DIRS"
mv $TEMP_DIRS $QUERIED_DIRS

LENGTH="${#PATHS[@]}"
if [ "$LENGTH" == 0 ]; then
    echo "No results found." >&2
    return 3
elif [ "$LENGTH" == 1 ]; then
    if [ "${PATHS[0]}" = "" ]; then
        echo -n "Result not found. Consider increasing depth from current " >&2
        echo -n "value of $MAXDEPTH with -d flag." >&2
        return 3
    else
        cd ${PATHS[0]}
    fi
else
    if [ $INDEX == -1 ]; then
        echo "There were many results. Printing candidates:"
        WIDTH=$(awk -v val=$LENGTH 'BEGIN{print int(log(val))}')
        FORMATSTR="%${WIDTH}.1d"
        COUNT=0;
        for i in {0..4}; do echo -n "================"; done; echo ""
        echo -e "INDEX\tABSOLUTE PATH"
        for i in {0..4}; do echo -n "----------------"; done; echo ""
        while read -d $'\0' DIR; do
            echo -e "$(printf ${FORMATSTR} ${COUNT}).)\t${DIR}"
            let COUNT++
        done < <(printf "%s\0" "${PATHS[@]}");

        if [ $TIME_OUT == 0 ]; then
            echo "Use -i to specify an index next run, or use nonzero -t argument"
            return 1
        fi
        PROMPT="Please enter the desired index number: "
        READ_ERROR=0
        read -t $TIME_OUT -p "${PROMPT}" INDEX || READ_ERROR=$?
        if [ "$READ_ERROR" != 0 ]; then 
            echo -e "NULL\nRead timed out. Try using -i or -d."
            return "$READ_ERROR"
        fi
    fi
    if [ $INDEX -ge 0 2> /dev/null ]; then
        cd ${PATHS[$INDEX]}
        return
    else
        echo "Incorrect index value."
        return 1
    fi
fi

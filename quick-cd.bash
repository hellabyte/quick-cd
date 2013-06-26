#!/bin/bash
# (C) 2013 - June - 26 
# Nathaniel Hellabyte
# nate@hellabit.es
# = = = = = = = = = = =-

function print_help(){
cat << EOF
NAME
    qcd -- quick change directory
SYNOPSIS
    qcd [-sdpith]
    qcd [-d <depth>] [-p <path>] [-i <index>] [-t <time>] [-s] <searchterm>
DESCRIPTION
  MAIN PROGRAM LOOP:
        find \$BASEDIRS -maxdepth \$MAXDEPTH -type d -iname \$SEARCHTERM 
  OPTIONS
    -s
        Specifies which directory to find. RECOMMENDED use when other flags are implemented.
        Program will try to search for last option even if -s is not passed.
        Note that program automatically wraps search term in globs (*<searchterm>*).
    -d
        Specifies maximum depth to search from base, default value is 3.
        Less than 3 is usually too shallow, greater than 3 comprimises speed.
        It is better to pass a path with -p than to increase depth for large filesystems.
        Note also that as qcd matures it's general directory database, a lower depth
        will work more often.
    -p
        Specifies Path(s) to launch search from.
        The speed of target acquistion is dependent on distance from base.
        To include multiple paths, enclose in double quotes.
    -i
        Specifies which directory to switch to when multiple matches are found.
    -t 
        Specifies time given to select the currect directory from a multiple matching.
        Default value is 30 seconds. Set to 0 to only print matches.
    -h
        Prints this help message.
EOF
}
if [ $# == 0 ]; then
    echo "ERROR -- scd requires arguments." >&2
    return 1
fi
BASEDIRS=(); PATHS=()
MAXDEPTH=3; INDEX=-1; SEARCHTERM=""; TIME_OUT=30;
QUICKCD_HOME_ROOT="${HOME}/.quick-cd"
GENERAL_DIRS="${QUICKCD_HOME_ROOT}/.general_dirs"
QUERIED_DIRS="${QUICKCD_HOME_ROOT}/.queried_dirs"
TEMP_DIRS="${QUICKCD_HOME_ROOT}/.tdirs"
if [ ! -d $QUICKCD_HOME_ROOT ]; then mkdir $QUICKCD_HOME_ROOT; fi
if [ ! -f $GENERAL_DIRS ]; then touch $GENERAL_DIRS; fi
if [ ! -f $QUERIED_DIRS ]; then touch $QUERIED_DIRS; fi
sort $GENERAL_DIRS | uniq > $TEMP_DIRS
while read LINE; do
    BASEDIRS+=("$LINE")
done < "${TEMP_DIRS}"
mv $TEMP_DIRS $GENERAL_DIRS
OPTIND=1
while getopts ":d:p:i:s:t:h" OPTNAME; do
    case $OPTNAME in
        'd')
            MAXDEPTH=$OPTARG
            ;;
        'p')
            while read -r -d $'\0'; do
                BASEDIRS+=("$REPLY")
            done < <(printf "%s\0" "${OPTARG[@]}")
            ;;
        'i')
            INDEX=$OPTARG
            if [ $INDEX -gt -1 ] && [ -f $QUERIED_DIRS ]; then
                while read LINE; do
                    PATHS+=("$LINE")
                done < "$QUERIED_DIRS"
                cd "${PATHS[$INDEX]}"
                return
            fi
            ;;
        's')
            SEARCHTERM="*${OPTARG}*"
            ;;
        't') 
            TIME_OUT=$OPTARG
            ;;
        'h' ) 
            print_help
            return 2
            ;;
        : | \? | \*)
            echo "Option -${OPTARG} requires an argument." >&2
            return 1
            ;;
    esac
done
OPTIND=1 # shift $(( OPTIND - 1 )) not working on OS 10.8.4
VAL="${@: -1}"
if [ -z "$SEARCHTERM" ] && [ -n "$VAL" ]; then
    SEARCHTERM="*${VAL}*"
fi
if [ -n "${SEARCHTERM}" ]; then
    while read -r -d $'\0'; do
        PATHS+=("$REPLY")
    done < <(find ${BASEDIRS[@]} -type d \
        -maxdepth $MAXDEPTH -iname "$SEARCHTERM" -print0 2> /dev/null)
else 
    echo "No search term provided." >&2
    return 1
fi
# PATHS pruner
echo -n '' > $QUERIED_DIRS
while read -d $'\0' QPATHNAME; do
    echo "$QPATHNAME" >> $QUERIED_DIRS
done < <(printf "%s\0" "${PATHS[@]}")
sort $QUERIED_DIRS | uniq > $TEMP_DIRS
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
    cd ${PATHS[0]}
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

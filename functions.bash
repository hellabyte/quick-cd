# BEGIN QUICK-CD FUNCTIONS
# DO NOT INSERT ANYTHING BETWEEN BEGIN AND END
# DO NOT REMOVE THESE COMMENTS AS THEY ARE IMPORTANT FOR UNINSTALLING
# VERSION DATE 2013 - June - 26 
# qcd 
#   sources quick-cd and allows for getopts to work in the environment
function qcd(){
    builtin source "quick-cd"
    builtin unset $OPTSTRING
}
# GENERAL_DIRS is the absolute path of the file containing
#   the newline seperated list of used directories.
GENERAL_DIRS="${HOME}/.quick-cd/.general_dirs"
TEMP_DIRS="${HOME}/.quick-cd/.tdirs"
if [ ! -s $GENERAL_DIRS ]; then
    while read -d $'\0' DIRNAME; do 
        echo $DIRNAME >> $GENERAL_DIRS
    done < <(printf "%s\0" "${DIRSTACK[@]}")
fi
# CD_COUNT counts the number of times the cd command is used,
#   allowing for redundancy removal of $GENERAL_DIRS.
CD_COUNT=0
# cd
#   redefines the builtin so that a list of commonly used
#   directories can be built. Supplemental to qcd, as a more
#   mature .common_dirs file increases the usability of qcd.
function cd(){
    TARGET_DIR=$1
    builtin cd $TARGET_DIR || return

    builtin echo "$(pwd)" >> $GENERAL_DIRS
    builtin let CD_COUNT++
    # Low number specific to local session redundancy.
    if [ $(($CD_COUNT % 6)) -eq 0 ]; then
        sort $GENERAL_DIRS | uniq 1> $TEMP_DIRS 2> /dev/null
        mv $TEMP_DIRS $GENERAL_DIRS 
    fi
    # Higher number specific to global session redundancy.
    # Places limit on number of files in $GENERAL_DIRS
    if [ $(wc -l $GENERAL_DIRS | awk '{print $1}') -gt 30 ]; then
        sort $GENERAL_DIRS | uniq -c | sort -r | head -25 | \
            awk '{print $2}' 1> $TEMP_DIRS 2> /dev/null
        mv $TEMP_DIRS $GENERAL_DIRS 
    fi
}
# END QUICK-CD FUNCTIONS

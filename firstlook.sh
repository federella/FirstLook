#!/bin/bash

#color/formatting codes
BOLD="\e[1m"
MAGENTA="\e[35m"
GREEN="\e[92m"
RED="\e[91m"
CYAN="\e[96m"
STANDARD="\e[0m"


TYPES="filetypes.txt"
LIB="libraries.txt"

if [ $# -ne 1 ]
then
	echo "Usage: firstlook.sh <filename>"
	exit 1
fi

if [ ! -f $1 ]
then
	echo "File \"$1\" does not exists."
	exit 2
fi

SAMPLE=$1

# TMPDIR environment variable can be used to choose a different base directory
# for temporary files
WORKDIR=$(mktemp -d "${TMPDIR:-/tmp/}firstlook.XXXXXXXXXXX")

printf "$BOLD***EXTRACTING INFOS***\n$STANDARD"
strings $SAMPLE > $WORKDIR/sample.strings

printf "done\n\n"

printf "$BOLD$MAGENTA***GENERAL INFO***\n$STANDARD"
printf "\tName: $SAMPLE\n" #filename
size=`stat --format="%s" $SAMPLE` #filesize
printf "\tSize: $size bytes\n"
type=`file $SAMPLE | awk -F: '{print $2}'\n`
printf "\tType:$type\n"


#KNOWN DLLs"
dll_arrays=($(grep ".dll" $WORKDIR/sample.strings | tr '[:upper:]' '[:lower:]'))
unknown_lib=()
printf "$BOLD$RED\n***KNOWN LIBRARIES***\n$STANDARD"
for i in "${dll_arrays[@]}"
do
	grep $i $LIB > /dev/null
	if [ $? -eq 0 ]; then
		info=`awk -F, -v lib="$i" '$1==lib {print $2}' $LIB`
		printf "\t$i: $info\n"
	else
		unknown_lib+=("$i")
	fi
done
#UNKNOWN DLLs
if [ ${#unknown_lib[@]} -ne 0 ]
then
	printf "$BOLD$RED\n***UNKNOWN LIBRARIES***\n$STANDARD"
	for i in "${unknown_lib[@]}"
	do
		printf "\t$i\n"
	done
fi


#INTERESTING STRINGS
printf "$BOLD$GREEN\n***INTERESTING STRINGS***\n$STANDARD"

printf "\t"; grep -Ei "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" $WORKDIR/sample.strings #ip addresses
printf "\t"; grep -Ei ".*@.*\..*" $WORKDIR/sample.strings #email address
printf "\t"; grep -Ei ".*https?://.*|s?ftps?://.*|tcp://" $WORKDIR/sample.strings # http/(s)ftp(s)/tcp addresses
printf "\t"; grep -Ei "[[:digit:]]{1,3}:[[:digit:]]{1,3}:[[:digit:]]{1,3}" $WORKDIR/sample.strings #time
printf "\t"; grep -Ei "[[:digit:]]{1,2}[:/-][[:digit:]]{1,2}[:/-][[:digit:]]{2,4}" $WORKDIR/sample.strings #DD-MM-YYYY
printf "\t"; grep -Ei "[[:digit:]]{2,4}[:/-][[:digit:]]{1,2}[:/-][[:digit:]]{1,2}" $WORKDIR/sample.strings #YYYY-DD-MM
file_f=($(grep -Ei "file" $WORKDIR/sample.strings | grep -Ei "^[[:alpha:]]*$"))

#INTERESTING FUNCTIONS
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***FILE FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${file_f[@]}"
fi
#
mem_f=($(grep -Ei "memory|mem|alloc" $WORKDIR/sample.strings |grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***MEMORY FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${mem_f[@]}"
fi

net_f=($(grep -Ei "url|http|ftp|host|hostname|internet|bind" $WORKDIR/sample.strings | grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***NETWORK FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${net_f[@]}"
fi

proc_f=($(grep -Ei "process|proc|thread|shell" $WORKDIR/sample.strings | grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***PROCESS/THREAD FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${proc_f[@]}"
fi

reg_f=($(grep -Ei "reg|registry" $WORKDIR/sample.strings | grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***REGISTRY FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${reg_f[@]}"
fi

rm -rf $WORKDIR

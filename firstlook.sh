#!/bin/bash

#color/formatting codes
BOLD="\e[1m"
MAGENTA="\e[35m"
GREEN="\e[92m"
RED="\e[91m"
CYAN="\e[96m"
STANDARD="\e[0m"


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





printf "$BOLD$MAGENTA***GENERAL INFO***\n$STANDARD"
printf "\tName: $1\n" #filename
size=`stat --format="%s" $1` #filesize
printf "\tSize: $size bytes\n"
type=`file $1 | awk -F: '{print $2}'\n`
printf "\tType:$type\n"


#KNOWN DLLs
dll_arrays=($(strings $1 | grep ".dll" | tr '[:upper:]' '[:lower:]'))
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

printf "\t"; strings $1 |  grep -Ei "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" #ip addresses
printf "\t";strings $1 |  grep -Ei ".*@.*\..*"  #email address
printf "\t";strings $1 | grep -Ei ".*https?://.*|s?ftps?://.*"
printf "\t";strings $1 | grep -Ei "[[:digit:]]{1,3}:[[:digit:]]{1,3}:[[:digit:]]{1,3}"  #time
printf "\t";strings $1 | grep -Ei "[[:digit:]]{1,2}[:/-][[:digit:]]{1,2}[:/-][[:digit:]]{2,4}"  #DD-MM-YYYY
printf "\t";strings $1 | grep -Ei "[[:digit:]]{2,4}[:/-][[:digit:]]{1,2}[:/-][[:digit:]]{1,2}"  #YYYY-DD-MM
file_f=($(strings $1 |  grep -Ei "file"|grep -Ei "^[[:alpha:]]*$"))

#INTERESTING FUNCTIONS
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***FILE FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${file_f[@]}"
fi
#
mem_f=($(strings $1 | grep -Ei "memory|mem|alloc"|grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***MEMORY FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${mem_f[@]}"
fi

net_f=($(strings $1 | grep -Ei "url|http|ftp|host|hostname|internet|bind"| grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***NETWORK FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${net_f[@]}"
fi

# Looking for any functions that can crypt files
crypt_f=($(strings $1 | grep -Ei "crypt|Key|Decrypt|Encrypt"| grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***CRYPTOGRAPHIC FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${proc_f[@]}"
fi

proc_f=($(strings $1 | grep -Ei "process|proc|thread|shell"|grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***PROCESS/THREAD FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${proc_f[@]}"
fi

reg_f=($(strings $1 | grep -Ei "reg|registry"|grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***REGISTRY FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${reg_f[@]}"
fi

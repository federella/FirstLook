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

printf "$BOLD$MAGENTA***GENERAL INFO***\n$STANDARD"
printf "\tName: $1\n" #filename
size=`stat --format="%s" $1` #filesize
printf "\tSize: $size bytes\n"

#CHECKING THE FILE TYPE BY USING MAGIC BYTES
string=`xxd -l 16 $1`
bytes_arr=()
types_arr=()
while IFS=, read key val
do
		bytes_arr+=("$val")
		types_arr+=("$key")
done < $TYPES

for i in ${!bytes_arr[@]}
do
	magic_byte="${bytes_arr[$i]}"
	file_type="${types_arr[$i]}"
	echo $string | grep "$magic_byte" > /dev/null
	if [ $? -eq 0 ];then
		printf "\tType: %s\n" "$file_type"
	fi
done

#KNOWN DLLs"
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

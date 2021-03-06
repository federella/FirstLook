#!/bin/bash

#color/formatting codes
BOLD="\e[1m"
MAGENTA="\e[35m"
GREEN="\e[92m"
RED="\e[91m"
CYAN="\e[96m"
YELLOW="\e[93m"
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

SAMPLE=$1

# TMPDIR environment variable can be used to choose a different base directory
# for temporary files
WORKDIR=$(mktemp -d "${TMPDIR:-/tmp/}firstlook.XXXXXXXXXXX")

printf "$BOLD***EXTRACTING INFOS***\n$STANDARD"
strings $SAMPLE > $WORKDIR/sample.strings.std
strings -e b $SAMPLE > $WORKDIR/sample.strings.utf16be
strings -e l $SAMPLE > $WORKDIR/sample.strings.utf16le
strings -e B $SAMPLE > $WORKDIR/sample.strings.utf32be
strings -e L $SAMPLE > $WORKDIR/sample.strings.utf32le

cat $WORKDIR/sample.strings.* | sort | uniq > $WORKDIR/sample.strings

printf "done\n\n"

printf "$BOLD$MAGENTA***GENERAL INFO***\n$STANDARD"
printf "\tName: $SAMPLE\n" #filename
size=`stat --format="%s" $SAMPLE` #filesize
printf "\tSize: $size bytes\n"
type=`file $SAMPLE | awk -F: '{print $2}'\n`
printf "\tType: $type\n"
md5_val=`md5sum $SAMPLE | awk '{print $1}'\n`
printf "\tMD5: $md5_val\n"
sha=`sha256sum $SAMPLE | awk '{print $1}'\n`
printf "\tSHA256: $sha\n"

#KNOWN DLLs
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

#PACKER INDICATORS
packer_i=($(grep -Ei "\.UPX[0-9]|UPX|LoadLibraryA?|GetProcAddress|SR" $WORKDIR/sample.strings))
if [ $? -eq 0 ]
then
	printf "$BOLD$YELLOW\n***POSSIBLE PACKERS INDICATORS***\n$STANDARD"
	printf '\t%s\n' "${packer_i[@]}"
fi

#INTERESTING STRINGS
printf "$BOLD$GREEN\n***INTERESTING STRINGS***\n$STANDARD"
grep -Ei "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" $WORKDIR/sample.strings > $WORKDIR/interesting #ip addresses
grep -Ei ".*@.*\..*" $WORKDIR/sample.strings >> $WORKDIR/interesting #email address
grep -Ei ".*https?://.*|s?ftps?://.*|tcp://" $WORKDIR/sample.strings >> $WORKDIR/interesting # http/(s)ftp(s)/tcp addresses
grep -Eoi "([a-z0-9][a-z0-9-]{1,61}[a-z0-9]\.[a-z]{2,})*" $WORKDIR/sample.strings | grep -viE '\.dll|\.exe' >> $WORKDIR/interesting # domains, file names (incidentally)
grep -Ei "[[:digit:]]{1,3}:[[:digit:]]{1,3}:[[:digit:]]{1,3}" $WORKDIR/sample.strings >> $WORKDIR/interesting #time
grep -Ei "[[:digit:]]{1,2}[:/-][[:digit:]]{1,2}[:/-][[:digit:]]{2,4}" $WORKDIR/sample.strings >> $WORKDIR/interesting #DD-MM-YYYY
grep -Ei "^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$" $WORKDIR/sample.strings >> $WORKDIR/interesting # Bitcoin addresses
grep -Ei "[[:digit:]]{2,4}[:/-][[:digit:]]{1,2}[:/-][[:digit:]]{1,2}" $WORKDIR/sample.strings >> $WORKDIR/interesting #YYYY-DD-MM
cat $WORKDIR/interesting | sort | uniq

#INTERESTING FUNCTIONS
file_f=($(grep -Ei "file" $WORKDIR/sample.strings | grep -Ei "^[[:alpha:]]*$"))

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

# Looking for any functions that can crypt files
crypt_f=($(grep -Ei "crypt|Key|Decrypt|Encrypt" $WORKDIR/sample.strings | grep -Ei "^[[:alpha:]]*$"))
if [ $? -eq 0 ]
then
	printf "$BOLD$CYAN\n***CRYPTOGRAPHIC FUNCTIONS***\n$STANDARD"
	printf '\t%s\n' "${proc_f[@]}"
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

printf "\n"

rm -rf $WORKDIR

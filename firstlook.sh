#!/bin/bash

string=`xxd -l 16 $1`

bytes_arr=()
types_arr=()
while IFS=, read key val
do
		bytes_arr+=("$val")
		types_arr+=("$key")
done < filetypes.txt

for i in ${!bytes_arr[@]}
do
	magic_byte="${bytes_arr[$i]}"
	file_type="${types_arr[$i]}"
	echo $string | grep "$magic_byte" > /dev/null
	if [ $? -eq 0 ];then
		printf "File type is: %s\n" "$file_type"
	fi
done

dll_arrays=($(strings $1 | grep ".dll"))
for i in "${dll_arrays[@]}"
do
	echo "***$i"
done

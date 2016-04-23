#!/bin/bash

###############################################################
# The MIT License (MIT)                                       #
# Copyright (c) 2016 Jen Herting <jen@herting.cc>             #
#                                                             #
# Permission is hereby granted, free of charge, to any person #
# obtaining a copy of this software and associated            #
# documentation files (the "Software"), to deal in the        #
# Software without restriction, including without limitation  #
# the rights to use, copy, modify, merge, publish,            #
# distribute, sublicense, and/or sell copies of the Software, #
# and to permit persons to whom the Software is furnished to  #
# do so, subject to the following conditions:                 #
#                                                             #
# The above copyright notice and this permission notice shall #
# be included in all copies or substantial portions of the    #
# Software.                                                   #
#                                                             #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY   #
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE  #
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR     #
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS  #
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR    #
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR  #
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE   #
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.      #
###############################################################

. stack.sh

function stack_peak() {
	stack_pop "$1" "$2"
	stack_push "$1" ""
}

TORRENT_PATH="$1"

full_length=$(wc -c "$TORRENT_PATH" | cut -d' ' -f1)
position=0

stack_new "mode"


depth=0
echo "{"

read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
(( position += 1 ))
if [[ $read_char == 'd' ]] ; then
	(( depth ++ ))
	stack_push "mode" d
fi
while [[ $position -lt $full_length ]] ; do
	
	stack_pop "mode" "current_mode"
	stack_push "mode" "${current_mode}"
	if [[ $current_mode == 'd' ]] ; then
		# GET KEY LENGTH
		key_len=0
		read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
		(( position += 1 ))
		while [[ $read_char != ':' ]] ; do 
			(( key_len *= 10 ))
			(( key_len += read_char ))
			read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
			(( position += 1 ))
		done

		# GET KEY
		key=$(dd "if=${TORRENT_PATH}" bs=1 count=${key_len} skip=$position 2> /dev/null)
		(( position += key_len ))
	fi

	# CHECK DEPTH
	read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
	if [[ $read_char == 'd' ]] ; then 
		# OUTPUT DATA
		i=$depth
		while [[ $i -gt 0 ]]; do 
			echo -ne "\t"
			(( i -- ))
		done
	
		if [[ $current_mode == 'l' ]] ; then
			printf '{'
		else	
			printf '"%s": {' "$key"
		fi
		echo

		(( depth ++ ))
		(( position ++ ))
		stack_push "mode" d

		continue
	fi

	if [[ $read_char == 'l' ]] ; then 
		# OUTPUT DATA
		i=$depth
		while [[ $i -gt 0 ]]; do 
			echo -ne "\t"
			(( i -- ))
		done
		
		if [[ $current_mode == 'l' ]] ; then
			printf '['
		else	
			printf '"%s": [' "$key"
		fi
		echo

		(( depth ++ ))
		(( position ++ ))
		stack_push "mode" l

		continue
	fi


	#read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
	value_type=""
	if [[ $read_char =~ [0-9] ]] ; then
		value_type="s"
		# GET VALUE LENGTH
		value_len=0
		read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
		(( position += 1 ))
		while [[ $read_char != ':' ]] ; do 
			(( value_len *= 10 ))
			(( value_len += read_char ))
			read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
			(( position += 1 ))
		done

		# GET VALUE
		value=$(dd "if=${TORRENT_PATH}" bs=1 count=${value_len} skip=$position 2> /dev/null)
		(( position += value_len ))
	
	elif [[ $read_char =~ 'i' ]] ; then
		value_type="i"
		value_len=0
		value=0
		read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
		(( position += 1 ))
		while [[ $read_char != 'e' ]] ; do
			(( value_len ++ ))
			(( value *= 10 ))
			(( value += read_char ))
			read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
			(( position += 1 ))
		done
	fi

	# OUTPUT DATA
	i=$depth
	while [[ $i -gt 0 ]]; do 
		echo -ne "\t"
		(( i -- ))
	done
	
	if [[ $value_len -gt 100 ]] ; then 
		value="[...]"
	fi

	if [[ $current_mode == 'l' ]] ; then
		if [[ $value_type == 'i' ]] ; then
			printf '%s' "$value"
		else
			printf '"%s"' "$value"
		fi
	else
		if [[ $value_type == 'i' ]] ; then
			printf '"%s": %s' "$key" "$value"
		else
			printf '"%s": "%s"' "$key" "$value"
		fi
	fi

	read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
	if [[ $read_char != 'e' ]] ; then
		echo ','
	else
		echo
	fi
	while [[ $read_char == 'e' ]] ; do
		# OUTPUT DATA
		(( depth -- ))
		i=$depth
		while [[ $i -gt 0 ]]; do 
			echo -ne "\t"
			(( i -- ))
		done
		
		stack_pop "mode" "last_mode"
		if [[ $last_mode == 'l' ]] ; then
			printf "]"
		else
			printf "}"
		fi

		(( position ++ ))
		read_char=$(dd "if=${TORRENT_PATH}" bs=1 count=1 skip=$position 2> /dev/null)
		if [[ ( $read_char == 'e' ) || ( $depth == 0 ) ]] ; then
			echo 
		else
			echo ','
		fi
	done
done




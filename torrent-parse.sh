#!/bin/bash


TORRENT_PATH=$1

full_length=$(wc -c $TORRENT_PATH | cut -d' ' -f1)
position=0

depth=0
echo "{"

read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
(( position += 1 ))
if [[ $read_char == 'd' ]] ; then
	(( depth ++ ))
fi
while [[ $position -lt $full_length ]] ; do
		
	# GET KEY LENGTH
	key_len=0
	read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
	(( position += 1 ))
	while [[ $read_char != ':' ]] ; do 
		(( key_len *= 10 ))
		(( key_len += read_char ))
		read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
		(( position += 1 ))
	done

	# GET KEY
	key=$(dd if=${TORRENT_PATH} bs=1 count=${key_len} skip=$position 2> /dev/null)
	(( position += key_len ))

	# CHECK DEPTH
	read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
	if [[ $read_char == 'd' ]] ; then 
		# OUTPUT DATA
		i=$depth
		while [[ $i -gt 0 ]]; do 
			echo -ne "\t"
			(( i -- ))
		done
		
		printf '"%s" {' "$key"
		echo

		(( depth ++ ))
		(( position ++ ))

		continue
	fi


	#read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
	if [[ $read_char =~ [0-9] ]] ; then
		# GET VALUE LENGTH
		value_len=0
		read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
		(( position += 1 ))
		while [[ $read_char != ':' ]] ; do 
			(( value_len *= 10 ))
			(( value_len += read_char ))
			read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
			(( position += 1 ))
		done

		# GET VALUE
		value=$(dd if=${TORRENT_PATH} bs=1 count=${value_len} skip=$position 2> /dev/null)
		(( position += value_len ))
	
	elif [[ $read_char =~ 'i' ]] ; then
		value_len=0
		value=0
		read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
		(( position += 1 ))
		while [[ $read_char != 'e' ]] ; do
			(( value_len ++ ))
			(( value *= 10 ))
			(( value += read_char ))
			read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
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
	printf '"%s": "%s"' "$key" "$value"
	echo

	read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
	while [[ $read_char == 'e' ]] ; do
		# OUTPUT DATA
		(( depth -- ))
		i=$depth
		while [[ $i -gt 0 ]]; do 
			echo -ne "\t"
			(( i -- ))
		done
		
		echo "}"

		(( position ++ ))
		read_char=$(dd if=${TORRENT_PATH} bs=1 count=1 skip=$position 2> /dev/null)
	done
done




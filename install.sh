#!/bin/bash

if [ `id -u` -ne 0 ]
	then
	echo "You must be root to perform this action!"
	exit 0
fi

cp -r ./usr /
echo "Copying scripts - done."
cp -r ./etc /
echo "Copying settings - done."
touch '/var/log/isida.log'
touch '/var/log/checker.log'
echo "Visit https://github.com/vlad-syan/isida for news."


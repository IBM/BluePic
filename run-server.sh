#!/bin/bash

#set -e 
cd "$(dirname "$0")" 
cd BluePic-Server 
kill `ps aux | grep -F '.build/debug/Server' | grep -v -F 'grep' | awk '{ print $2 }'`
echo 'got here'
if [[ "$1" = "xcode" ]]; then
	echo 'got xcode'
	.build/debug/Server
else
	echo 'default'
	.build/debug/Server &
fi
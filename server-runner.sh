#!/bin/bash

set -e 
cd "$(dirname "$0")" 
cd BluePic-Server 
brew install http-parser curl 
make clean 
make 

if kill `ps aux | grep -F '.build/debug/Server' | grep -v -F 'grep' | awk '{ print $2 }'`; then
	echo 'Server was already running, killing server and then starting it back up again'
	.build/debug/Server &
else
	echo 'Server wasnt already running, starting it up'
	.build/debug/Server &
fi
#!/bin/bash

set -e 
cd "$(dirname "$0")" 
cd BluePic-Server 
.build/debug/Server &
#kill `ps aux | grep -F '.build/debug/Server' | grep -v -F 'grep' | awk '{ print $2 }'` || false
#if [[ "$1" = "xcode" ]]; then
#	echo 'got xcode'
#	.build/debug/Server
#else
#	.build/debug/Server &
#fi
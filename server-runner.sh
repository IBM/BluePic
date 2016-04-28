#!/bin/bash

set -e 
if [[ "$1" != "xcode" ]]; then
	brew install http-parser curl
fi
./compile-server.sh
./run-server.sh $1
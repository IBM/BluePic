#!/bin/bash

set -e

brew install http-parser curl

#if [[ "$1" != "xcode" ]]; then
#	brew install http-parser curl
#fi

./compile-server.sh
./run-server.sh $1
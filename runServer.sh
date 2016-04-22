#!/bin/bash

cd "$(dirname "$0")" && cd BluePic-Server && brew install http-parser curl && make clean && make && .build/debug/Server
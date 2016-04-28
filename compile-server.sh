#!/bin/bash

set -e 
cd "$(dirname "$0")" 
cd BluePic-Server 
make clean 
make 
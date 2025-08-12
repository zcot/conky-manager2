#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

sh ./build-source.sh
dput ppa:zcot/ppa ../builds/conky-manager2*.changes

cd "$backup"

#!/bin/bash
args=( $@ )
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
export THEIA_DEFAULT_PLUGINS=local-dir:$SCRIPTPATH/plugins
\cd $SCRIPTPATH
node src-gen/backend/main.js ${args[*]}

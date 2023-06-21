#!/usr/bin/env bash

# Default target
TARGET="killbill"

ACTION=
TAGGED_PATH=

help() {
    echo "dockerTemplate.sh -i -c  -v THE_VERSION -t TARGET"
    echo "-i : init (create the template file)"
    echo "-c : clean (create the tagged template file). To be executed after init"
    echo "-v : the version to build"
    echo "-t : the target to build"
    echo "-p : the parent version to use"
    exit 1
}

init() {
  if [[ $VERSION != 'latest' ]]; then
    clean
    cat "$TAGGED_PATH/Dockerfile.template" | sed -e "s/__PARENT_VERSION__/$PARENT_VERSION/" | sed -e "s/__VERSION__/$VERSION/" > "$TAGGED_PATH/Dockerfile"
    echo "Built $TAGGED_PATH/Dockerfile with FROM:"
    grep FROM $TAGGED_PATH/Dockerfile
    if [[ -f "$TAGGED_PATH/kpm.yml.template" ]]; then
        cat "$TAGGED_PATH/kpm.yml.template" | sed -e "s/__VERSION__/$VERSION/" > "$TAGGED_PATH/kpm.yml"
    fi
  else
    cat "$LATEST_PATH/Dockerfile.template" | sed -e "s/__PARENT_VERSION__/$PARENT_VERSION/" > "$LATEST_PATH/Dockerfile"
    echo "Built $LATEST_PATH/Dockerfile with FROM:"
    grep FROM $LATEST_PATH/Dockerfile
  fi
}

clean() {
    rm -f "$TAGGED_PATH/Dockerfile"
    rm -f "$TAGGED_PATH/kpm.yml"
}

while getopts "hict:v:p:" OPTION; do
  case $OPTION in
    h) help;;
    i) ACTION="INIT";;
    c) ACTION="CLEAN";;
    v) VERSION="$OPTARG";;
    t) TARGET="$OPTARG";;
    p) PARENT_VERSION="$OPTARG";;
  esac
done

TAGGED_PATH="templates/$TARGET/tagged"
LATEST_PATH="templates/$TARGET/latest"

if [[ $ACTION == "INIT" ]]; then
  init
elif [[ $ACTION == "CLEAN" ]]; then
  clean
else
  help
fi

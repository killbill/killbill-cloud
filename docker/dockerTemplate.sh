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
    echo "-t : the target to build; either killbill, kaui, data and for data a version MUST be specified"
    exit 1
}

init() {
  if [[ $VERSION != 'latest' ]]; then
    clean
    cat "$TAGGED_PATH/Dockerfile.template"  | sed -e "s/__VERSION__/$VERSION/" > "$TAGGED_PATH/Dockerfile"
  fi
}

clean() {
    rm -f "$TAGGED_PATH/Dockerfile"
}

while getopts "hict:v:" OPTION; do
  case $OPTION in
    h) help;;
    i) ACTION="INIT";;
    c) ACTION="CLEAN";;
    v) VERSION="$OPTARG";;
    t) TARGET="$OPTARG";;
  esac
done

TAGGED_PATH="templates/$TARGET/tagged"

if [[ $TARGET == "data" ]] && [[ -z $VERSION ]]; then
    help
fi

if [[ $ACTION == "INIT" ]]; then
  init
elif [[ $ACTION == "CLEAN" ]]; then
  clean
else
  help
fi

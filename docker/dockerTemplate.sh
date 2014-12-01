#!/usr/bin/env bash

TAGGED_PATH="templates/tagged"

ACTION=

help() {
    echo "dockerTemplate.sh -i (init) -c (clean) -v THE_VERSION"
    exit 1
}

init() {
  if [[ $VERSION != 'LATEST' ]]; then
    clean
    cat "$TAGGED_PATH/Dockerfile.template"  | sed -e "s/__VERSION__/$VERSION/" > "$TAGGED_PATH/Dockerfile"
  fi
}

clean() {
    rm -f "$TAGGED_PATH/Dockerfile"
}

while getopts "hicv:" OPTION; do
  case $OPTION in
    h) help;;
    i) ACTION="INIT";;
    c) ACTION="CLEAN";;
    v) VERSION="$OPTARG";;
  esac
done

if [[ $ACTION == "INIT" ]]; then
  init
elif [[ $ACTION == "CLEAN" ]]; then
  clean
else
  help
fi
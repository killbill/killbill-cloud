#!/usr/bin/env bash

TAGGED_PATH="templates/tagged"

if [[ $VERSION != 'LATEST' ]]; then
    rm -f "$TAGGED_PATH/Dockerfile"
    cat "$TAGGED_PATH/Dockerfile.template"  | sed -e "s/__VERSION__/$VERSION/" > "$TAGGED_PATH/Dockerfile"
    rm -f "$TAGGED_PATH/Dockerfile"
fi
#!/bin/bash

set -e

if [ "${1-}" = "--help" ] || [ "${1-}" = "-h" ]; then
    echo "Usage: $0 RESULT_FOLDER"
    exit 0
fi
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 RESULT_FOLDER" >&2
    exit 2
fi
RESULT_FOLDER="$1"
if [ ! -f "$RESULT_FOLDER/ro-crate-metadata.json" ]; then
    echo "No ro-crate-metadata.json in $RESULT_FOLDER" >&2
    exit 2
fi

pos results publish upload --result-folder "$RESULT_FOLDER" \
    --access-token-file "$HOME/.secrets/zenodo_token"

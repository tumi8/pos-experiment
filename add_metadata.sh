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


pos results modify add_author --result-folder "$RESULT_FOLDER" \
    --user-id gallenmu --roles "Project administration"
pos results modify add_author --result-folder "$RESULT_FOLDER" \
    --given-name Kilian --family-name Holzinger \
    --affiliation "Technical University of Munich" \
    --orcid "0000-0003-2098-6367" \
    --roles "Project administration, Methodology"

pos results modify add_license --result-folder "$RESULT_FOLDER" "CC-BY-SA-4.0"
pos results modify add_title --result-folder "$RESULT_FOLDER" \
    "SLICES-DE pos MoonGen throughput and energy demo"
#pos results modify add_description --result-folder "$RESULT_FOLDER" \
#    "Two-node Ethernet experiment using MoonGen: node-a generates traffic and node-b reflects it. Measurements run for about 20 seconds per packet size (64, 128, 256, 512, 768, 1024, 1280 and 1518 bytes). Results include traffic logs, RX/TX throughput statistics and energy measurements where supported."
pos results modify add_keywords --result-folder "$RESULT_FOLDER" \
    "pos,SLICES-DE,GreenDigit,MoonGen,throughput,energy"

pos results show --result-folder "$RESULT_FOLDER"

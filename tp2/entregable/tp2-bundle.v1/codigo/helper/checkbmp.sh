#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 img.bmp";
    echo "Checks if the image is an rgba 8b uncompressed bmp"
    exit 1;
fi

FILE="$(file "$1")"
CHAN="$(identify -format '%[channels]' "$1")"
DEPTH="$(identify -format '%[depth]' "$1")"

if [[ ! $FILE =~ "PC bitmap" ]]; then
    echo "Invalid format"
    echo $FILE
    exit 2;
fi
if [[ ! $CHAN == "srgba" ]]; then
    echo "Invalid channels: $CHAN"
    exit 3;
fi
if [[ ! $DEPTH == "8" ]]; then
    echo "Invalid depth: ${DEPTH}b"
    exit 4;
fi

echo "Valid file"


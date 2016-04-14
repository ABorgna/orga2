#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 img.bmp";
    echo "Checks if the image is an rgba 8b uncompressed bmp"
    exit 1;
fi

file "$1"
identify -format '%[channels] %[depth]b \n' "$1"


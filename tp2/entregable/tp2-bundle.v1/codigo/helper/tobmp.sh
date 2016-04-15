#!/bin/bash
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 src.ext dst.bmp";
    echo "Converts the src image to an rgba 8b uncompressed bmp"
    exit 1;
fi

convert "$1" -colorspace rgb -type TrueColor -depth 8 -alpha on -compress none "BMP3:$2"


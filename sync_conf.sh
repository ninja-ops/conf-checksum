#!/bin/bash

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_path> <target_path>"
    exit 1
fi

SRC="$1"
DST="$2"

if [ ! -d "$SRC" ]; then
    echo "Source path '$SRC' is not a directory."
    exit 2
fi

if [ ! -d "$DST" ]; then
    echo "Target path '$DST' is not a directory."
    exit 3
fi

find "$SRC" -type f | while read -r srcfile; do
    relpath="${srcfile#$SRC/}"
    dstfile="$DST/$relpath"
    dstdir="$(dirname "$dstfile")"

    if [ ! -e "$dstfile" ]; then
        mkdir -p "$dstdir"
        cp "$srcfile" "$dstfile"
        echo "Copied (new): $relpath"
    else
        srcsum=$(./conf_checksum "$srcfile")
        dstsum=$(./conf_checksum "$dstfile")
        if [ "$srcsum" != "$dstsum" ]; then
            cp "$srcfile" "$dstfile"
            echo "Copied (changed): $relpath"
        fi
    fi
done

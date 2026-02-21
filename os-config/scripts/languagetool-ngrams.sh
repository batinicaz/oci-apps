#!/bin/bash
set -euo pipefail

NGRAM_DIR="/opt/data/languagetool/ngrams"
ZIPFILE="$NGRAM_DIR/.en.zip"

[ -d "$NGRAM_DIR/en" ] && exit 0

mkdir -p "$NGRAM_DIR"

curl -fSL -o "$ZIPFILE" "https://languagetool.org/download/ngram-data/ngrams-en-20150817.zip"
bsdtar -xf "$ZIPFILE" -C "$NGRAM_DIR"
chown -R 783:783 "$NGRAM_DIR"

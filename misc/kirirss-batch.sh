#!/bin/sh
# Convenience script to generate multiple feeds at once, takes configs
# ($feedname.toml) from $CONFIG_DIR and writes feeds ($feedname.rss) into
# $OUTPUT_DIR.

# Usage: ./kirirss-batch.sh feedname...

KIRIRSS_BIN="kirirss.rb"
KIRIRSS_DIR="."
CONFIG_DIR="$HOME/.config/kirirss"
OUTPUT_DIR="$HOME/.local/share/rss"

die() {
  status="$1"; shift
  echo "$@" >&2
  exit "$status"
}

[ -d "$OUTPUT_DIR" ] || die 1 "output path '$OUTPUT_DIR' is not a directory, exiting"

for i in "$@"; do
    "$KIRIRSS_DIR"/"$KIRIRSS_BIN" "$CONFIG_DIR"/"$i".toml > "$OUTPUT_DIR"/"$i".rss &
done

wait

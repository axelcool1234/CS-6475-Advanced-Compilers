#!/bin/sh
# Interesting when known bits proves that bits 5-7 of an addition result are
# zero after a masked value is incremented.
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 input.ll" >&2
  exit 2
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN=${PLUGIN:-"$SCRIPT_DIR/../build/KnownBits.so"}
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

mlir-translate --import-llvm "$1" -o "$TMP_DIR/input.mlir" 2>/dev/null || exit 1
mlir-opt --load-pass-plugin="$PLUGIN" \
  --pass-pipeline='builtin.module(known-bits)' \
  "$TMP_DIR/input.mlir" -o /dev/null 2>"$TMP_DIR/analysis.txt" || exit 1

grep -Eq 'llvm\.add .*has known bits width=8 ones=0b00000000 zeros=0b11100000' \
  "$TMP_DIR/analysis.txt"

#!/bin/sh
# Interesting when a control flow merge retains the seven high zero bits that
# are common to incoming constants zero and one.
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

grep -Eq 'argument: .*has known bits width=8 ones=0b00000000 zeros=0b11111110' \
  "$TMP_DIR/analysis.txt"
grep -Eq 'llvm\.cond_br %arg[0-9]+' "$TMP_DIR/analysis.txt"

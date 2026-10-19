#!/bin/sh
# Instrument an LLVM-dialect MLIR program, lower it to LLVM IR, link the tiny
# assertion runtime, and execute an exhaustive i8 harness.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_dir=$(dirname -- "$script_dir")
build_dir=${BUILD_DIR:-"$project_dir/build"}
input=${INPUT:-"$script_dir/bug-trigger.mlir"}
harness=${HARNESS:-"$script_dir/harness.c"}
pass_options="instrument=true"

if [ "${1:-}" = "--inject-bug" ]; then
  pass_options="instrument=true inject-unsound-add=true"
  shift
fi
if [ "$#" -gt 0 ]; then
  input=$1
fi

plugin=""
for candidate in "$build_dir/KnownBits.so" "$build_dir/KnownBits.dylib"; do
  if [ -f "$candidate" ]; then
    plugin=$candidate
    break
  fi
done
if [ -z "$plugin" ]; then
  echo "No plugin found in $build_dir; build HW3 first." >&2
  exit 2
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/known-bits-check.XXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT HUP INT TERM

mlir-opt \
  --load-pass-plugin="$plugin" \
  "--pass-pipeline=builtin.module(known-bits{$pass_options})" \
  "$input" -o "$work_dir/instrumented.mlir" \
  2>"$work_dir/analysis.txt"
mlir-translate --mlir-to-llvmir "$work_dir/instrumented.mlir" \
  -o "$work_dir/instrumented.ll"
clang "$work_dir/instrumented.ll" "$script_dir/runtime.c" \
  "$harness" -o "$work_dir/checker"
"$work_dir/checker"

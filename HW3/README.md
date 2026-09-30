# MLIR out-of-tree known-bits analysis

An MLIR sparse forward dataflow analysis implemented as a loadable `mlir-opt`
plugin, with no LLVM source tree required and nothing to patch upstream.

The `known-bits` pass determines which bits of scalar integer SSA values are
definitely zero or definitely one. It currently handles integer constants and
the LLVM dialect's `and`, `or`, `xor`, `add`, and `sub` operations. Unsupported
operations conservatively produce no known-bit facts.

## Building

The included Nix flake pins LLVM and MLIR 23. Enter its development shell and
use the ordinary CMake workflow:

```sh
nix develop
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build --output-on-failure
```

The flake also exposes the plugin as a package. `nix build` builds and tests it,
while `nix flake check` runs the same build as a flake check. The resulting
`result/bin/known-bits` wrapper invokes the matching MLIR 23 `mlir-opt`:

```sh
nix run . -- test/known-bits.mlir -o /dev/null
```

Without Nix, use any matching LLVM/MLIR installation:

```sh
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

That is the whole procedure on Linux, macOS, and WSL2. There is no platform
flag to set and no path to edit. `CMakeLists.txt` finds MLIR by asking
whichever `llvm-config` is on your `PATH` where its CMake package lives, so if
`mlir-opt` runs, the build should configure.

To build against a specific MLIR instead:

```sh
cmake -S . -B build -DMLIR_DIR=/path/to/prefix/lib/cmake/mlir
```

You need an LLVM built with MLIR enabled and plugins enabled
(`-DLLVM_ENABLE_PROJECTS=mlir -DLLVM_ENABLE_PLUGINS=ON`; both are ordinary on
Linux and macOS). Distribution packages work: on Debian and Ubuntu that is
`libmlir-dev` alongside `llvm-dev`. On macOS, Homebrew's `llvm` is the easy
route if it ships `mlir-opt` for your version; otherwise build LLVM yourself.
The configure step diagnoses the cases it can detect — no MLIR
found, plugins disabled in the host LLVM, or an `mlir-opt` on `PATH` whose
version does not match what you are building against.

## Running

```sh
./run.sh input.mlir
```

`run.sh` locates the plugin whatever it is called on your platform and puts the
annotated listing on stdout. Or invoke `mlir-opt` yourself:

```sh
mlir-opt --load-pass-plugin=build/KnownBits.so \
         --pass-pipeline='builtin.module(known-bits)' \
         input.mlir -o /dev/null
```

using `build/KnownBits.dylib` on macOS. The pass leaves the IR unchanged and
writes it to stdout as usual; the annotated view goes to stderr, so the two
streams can be redirected independently. Annotations are comments, so the
annotated listing is still valid MLIR. Values at top or bottom are left
unannotated, so that what prints is exactly what was proved.

Get input in the LLVM dialect from C with:

```sh
clang -S -emit-llvm -o - input.c | mlir-translate --import-llvm
```

## What is where

Two files hold the analysis and one holds its domain; the rest is reusable
scaffolding.

| File | |
|---|---|
| `KnownBitsDomain.h` | The known-zero/known-one domain, lattice join, and operation helpers. |
| `KnownBits.cpp` | MLIR transfer functions and entry-state construction. |
| `KnownBits.h` | Ties the domain to MLIR's sparse forward analysis. |
| `Annotate.{h,cpp}` | Prints IR with a comment on each value. Domain-agnostic. |
| `Plugin.cpp` | The pass, the solver setup, and the `mlir-opt` entry point. |
| `cmake/RunTest.cmake` | The test runner. |

The reusable plugin and annotation scaffolding is separate from the
analysis-specific domain and transfer functions.

## Tests

`test/known-bits.mlir` exercises constants, exact and partially known bitwise
operations, addition, subtraction, wrapping behavior, control-flow joins, and
multiple bit widths. It also includes a smoke test for obtaining the `index`
width from a 32-bit DLTI layout.

`test/known-bits.expected` lists annotated operation fragments that must appear
in the output. A leading `!` denotes a fragment that must not appear. The
checks are attached to the operations producing the facts so that an unrelated
constant cannot accidentally satisfy a transfer-function test.

Note that MLIR's printer renumbers SSA values, so the checks are written
against operation text rather than source SSA names. After adding or reordering
operations, inspect the output with `./run.sh test/known-bits.mlir`.

## Notes on portability

Most of the platform-specific knowledge lives in `CMakeLists.txt`, next to the
code it affects. The parts worth knowing about:

**The plugin's file name differs.** It is `KnownBits.dylib` on macOS and
`KnownBits.so` on Linux and WSL2. Nothing in this project spells out a single
suffix: CMake is asked via `$<TARGET_FILE:KnownBits>`, and `run.sh` probes for
both.

**Linking a plugin on macOS needs special flags.** The plugin deliberately
leaves its MLIR symbols undefined, to be resolved from the `mlir-opt` process
that loads it. On macOS that requires `-undefined dynamic_lookup`, which
`include(HandleLLVMOptions)` supplies. The same include also matches LLVM's
RTTI and exception settings, which differ between distribution packages and
local builds and cause link errors or silent ODR violations when they are
wrong. That is also why `project()` enables C: `HandleLLVMOptions` probes flags
with the C compiler and fails if none is configured.

**A plugin only loads into the LLVM it was built against.** The version is
recorded at compile time and checked at load time, so a mismatch is a clear
error rather than a crash. The configure step warns about it earlier still, by
comparing against the `mlir-opt` it finds.

**The test suite needs no shell.** `cmake/RunTest.cmake` is a CMake script
rather than a shell script, so `ctest` depends on nothing the build did not
already require.

**Under WSL2, build on the Linux filesystem.** A tree under `/mnt/c` is
slow enough to be noticeable and does not reliably carry execute bits.
`.gitattributes` forces LF endings, which keeps `run.sh` working when a
repository is cloned by a Windows git and built inside WSL2.

## How the analysis works

`Plugin.cpp` loads three analyses into one solver. `DeadCodeAnalysis` supplies
reachability — without it the solver must assume every branch is taken — and
`SparseConstantPropagation` resolves branch conditions on its behalf. The
`KnownBitsAnalysis` then propagates states through operations and block
arguments until the solver reaches a fixed point.

`KnownBitsState` stores a bit width and two `llvm::BitVector`s: one for bits
known to be zero and one for bits known to be one. Bottom represents an
unreachable or not-yet-analyzed value. Top uses the ordinary known-bits
encoding in which both vectors contain only zeroes, meaning no bit is known.
The width is retained even at top so later operations can safely manipulate
the vectors.

Joining two reachable states intersects their known-zero masks and intersects
their known-one masks. A fact survives a control-flow merge only when it holds
on every incoming path. Constructors and binary operations assert that vector
sizes agree with the recorded width and that no bit is simultaneously known
zero and known one.

Integer constants produce exact masks. Bitwise operations use the usual
per-bit rules. Addition uses a three-valued carry (`false`, `true`, or unknown)
and preserves a known carry through `0 + ? + 0` and `1 + ? + 1`. Subtraction is
implemented as two's-complement addition, `lhs + ~rhs + 1`. LLVM represents
bitwise NOT as XOR with an all-ones value, which is already handled by the XOR
transfer function.

Entry states for integer types take their width from `IntegerType`. Entry
states for `index` query the closest MLIR `DataLayout`, so the analysis does not
assume a host-specific index width. Top and bottom values are omitted from the
annotated listing; every printed annotation is therefore a fact proved by the
analysis.

## Current scope

The analysis is intraprocedural and currently supports scalar integer results.
It does not yet implement shifts, multiplication, integer casts, vectors, or
range-sensitive operations. The `nuw` and `nsw` flags are currently ignored;
the wrapping transfer remains conservative, but using those flags could prove
additional high bits on non-poison executions. Poison is deliberately not
represented in this domain.

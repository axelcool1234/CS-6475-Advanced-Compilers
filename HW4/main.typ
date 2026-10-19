#import "worksheet-template.typ": homework-header, setup

#show: setup
#homework-header(4, subtitle: [Dynamic Soundness Checking for MLIR Dataflow Analysis])

= Overview

For this assignment, I extended my known bits dataflow analysis
so that the same pass can optionally insert assertions. These assert statements check
if the abstract values match the concrete values at runtime.

I first tested the original transfer functions. The instrumented programs
completed 66,306 executions without an assertion failure, and an additional
exhaustive check of small abstract states found no error in addition or
subtraction. Because I did not find a pre-existing soundness bug, I added an optional, 
deliberately unsound addition transfer function.

= Dataflow fact assertions

Let $Z$ be the mask of bits known to be zero, $O$ the mask of bits known to be
one, and $x$ the concrete runtime value. A concrete value satisfies the
known bits fact exactly when

#align(center)[`(x & (Z | O)) == O`]

The bitwise union of $Z$ and $O$ selects every known bit. Masking $x$ removes all
unknown bits, after which the selected bits must equal the known one mask. This
single equality checks both kinds of facts: a selected zero bit cannot appear in
the result, and every selected one bit must appear.

For example, suppose the analysis reports

```text
ones  = 0b00000001
zeros = 0b11110000
```

Then the inserted condition is equivalent to

```c
assert((x & 0b11110001) == 0b00000001);
```

I omit top and bottom states because neither can be checked in a practical way.
The pass checks both operation results and block arguments, so facts created by
control flow joins are covered as well.

= MLIR Runtime

Instrumentation is enabled with the `instrument=true` pass option. For every
integer fact inside an LLVM dialect function, the pass inserts two
constants, an `llvm.and`, an `llvm.icmp`, and an unconditional call to a small C
runtime:

```mlir
%known_mask = llvm.mlir.constant(-16 : i8) : i8
%known_ones = llvm.mlir.constant(0 : i8) : i8
%selected = llvm.and %value, %known_mask : i8
%valid = llvm.icmp "eq" %selected, %known_ones : i8
%message = llvm.mlir.addressof @__known_bits_message : !llvm.ptr
llvm.call @__known_bits_assert(%valid, %message)
    : (i1, !llvm.ptr) -> ()
```

= Setup

My full setup performs the following steps:

1. Run `mlir-opt` with the plugin and assertion instrumentation enabled.
2. Translate the resulting LLVM dialect MLIR to LLVM IR with
   `mlir-translate --mlir-to-llvmir`.
3. Compile and link the LLVM IR, C assertion runtime, and input harness with
   `clang`.
4. Execute the resulting program.

The main corpus exercises all implemented transfer functions: `and`, `or`,
`xor`, `add`, and `sub`, as well as a control flow join. It runs all 256 values
of an `i8`, all 65,536 pairs of `i8` values through
masked addition, and both outcomes of an `i1` branch. In total, the unchanged
analysis passed 66,306 executions.

= Triggering MLIR program

After the original analysis passed, I enabled a deliberately unsound mode and
reduced the failing case to the following program:

```mlir
module {
  llvm.func @bounded_increment(%input: i8) -> i8 {
    %low_mask = llvm.mlir.constant(15 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    %low = llvm.and %input, %low_mask : i8
    %incremented = llvm.add %low, %one : i8
    llvm.return %incremented : i8
  }
}
```

The `and` constrains `%low` to the range 0 through 15. Therefore the addition
can produce values 1 through 16. A sound known bits result may prove that bits
5, 6, and 7 are zero, but it cannot prove bit 4 is zero because the input 15
produces 16.

= Observed failure

With the original addition transfer function, all 256 inputs to the reduced
program passed. With the deliberately unsound transfer enabled, the checker
stopped at input 15 and printed:

```text
dynamic known bits check failed for input 15:
known bits assertion for %3 after llvm.add at bug-trigger.mlir:9:20
(width=8 ones=0b00000000 zeros=0b11110000)
```

The incorrect state claims the upper four bits are zero. For input 15, the
concrete operation computes `(15 & 15) + 1 = 16`, or `0b00010000`. Bit 4 is set,
so the generated predicate

#align(center)[`(16 & 0xF0) == 0`]

is false.

= Analysis bug

The optional `inject-unsound-add=true` mode models `llvm.add` with the existing XOR
transfer function:

```cpp
const KnownBitsState sum = injectUnsoundAdd ? (lhs ^ rhs) : (lhs + rhs);
```

XOR is equivalent to addition only when no carries occur. In the reduced
program, the buggy transfer treats `%low + 1` as `%low ^ 1`. Since both operands
have zeros in the upper nibble, it concludes that the result also has zeros
there. Real addition propagates a carry from `0b00001111 + 1` into bit 4, making
that conclusion unsound.

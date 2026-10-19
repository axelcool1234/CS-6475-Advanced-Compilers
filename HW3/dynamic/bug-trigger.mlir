// Reduced dynamic-checking target. The argument is unconstrained, so masking
// it to four bits gives a value in [0, 15]. A correct addition transfer must
// allow bit 4 of the result to become one when the argument's low nibble is 15.
module {
  llvm.func @bounded_increment(%input: i8) -> i8 {
    %low_mask = llvm.mlir.constant(15 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    %low = llvm.and %input, %low_mask : i8
    %incremented = llvm.add %low, %one : i8
    llvm.return %incremented : i8
  }
}

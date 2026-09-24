// Starter coverage for operations a known-bits analysis will likely handle.
// The placeholder implementation currently leaves every value at top.
module {
  llvm.func @smoke(%arg0: i32) -> i32 {
    %zero = llvm.mlir.constant(0 : i32) : i32
    %one = llvm.mlir.constant(1 : i32) : i32
    %and = llvm.and %arg0, %one : i32
    %or = llvm.or %and, %zero : i32
    %sum = llvm.add %or, %one : i32
    llvm.return %sum : i32
  }
}

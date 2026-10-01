// Coverage for the known-bits lattice and the currently implemented LLVM
// dialect transfer functions. Keep the values narrow so incorrect masks are
// easy to spot in the annotated output.
module attributes {
  dlti.dl_spec = #dlti.dl_spec<#dlti.dl_entry<index, 32 : i64>>
} {
  llvm.func @constants_i8() -> i8 {
    %zero = llvm.mlir.constant(0 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    %pattern = llvm.mlir.constant(90 : i8) : i8
    %all_ones = llvm.mlir.constant(-1 : i8) : i8
    llvm.return %pattern : i8
  }

  llvm.func @constant_i1() -> i1 {
    %true = llvm.mlir.constant(true) : i1
    llvm.return %true : i1
  }

  llvm.func @constant_i16() -> i16 {
    %pattern = llvm.mlir.constant(4660 : i16) : i16
    llvm.return %pattern : i16
  }

  llvm.func @bitwise_exact() -> i8 {
    %lhs = llvm.mlir.constant(90 : i8) : i8
    %rhs = llvm.mlir.constant(60 : i8) : i8
    %all_ones = llvm.mlir.constant(-1 : i8) : i8
    %and = llvm.and %lhs, %rhs : i8
    %or = llvm.or %lhs, %rhs : i8
    %xor = llvm.xor %lhs, %rhs : i8
    %not = llvm.xor %lhs, %all_ones : i8
    llvm.return %not : i8
  }

  // An unconstrained argument is top. Constants can nevertheless force bits
  // in results involving that argument.
  llvm.func @bitwise_partial(%arg: i8) -> i8 {
    %zero = llvm.mlir.constant(0 : i8) : i8
    %all_ones = llvm.mlir.constant(-1 : i8) : i8
    %low_nibble = llvm.mlir.constant(15 : i8) : i8
    %high_nibble = llvm.mlir.constant(-16 : i8) : i8
    %and_zero = llvm.and %arg, %zero : i8
    %or_ones = llvm.or %arg, %all_ones : i8
    %and_low = llvm.and %arg, %low_nibble : i8
    %or_high = llvm.or %arg, %high_nibble : i8
    %not_low = llvm.xor %and_low, %all_ones : i8
    llvm.return %not_low : i8
  }

  llvm.func @addition_exact() -> i8 {
    %zero = llvm.mlir.constant(0 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    %three = llvm.mlir.constant(3 : i8) : i8
    %five = llvm.mlir.constant(5 : i8) : i8
    %max = llvm.mlir.constant(-1 : i8) : i8
    %signed_max = llvm.mlir.constant(127 : i8) : i8
    %sum = llvm.add %five, %three : i8
    %wrap = llvm.add %max, %one : i8
    %sign_bit = llvm.add %signed_max, %one : i8
    %identity = llvm.add %five, %zero : i8
    llvm.return %sum : i8
  }

  llvm.func @addition_partial(%arg: i8) -> i8 {
    %one = llvm.mlir.constant(1 : i8) : i8
    %low_nibble = llvm.mlir.constant(15 : i8) : i8
    %clear_low_bit = llvm.mlir.constant(-2 : i8) : i8
    %small = llvm.and %arg, %low_nibble : i8
    %even = llvm.and %arg, %clear_low_bit : i8
    %small_plus_one = llvm.add %small, %one : i8
    %even_plus_one = llvm.add %even, %one : i8
    llvm.return %small_plus_one : i8
  }

  // Minimal reproducer: clearing bit 0 makes an unknown value even; adding
  // one must therefore prove only that bit 0 of the result is one.
  llvm.func @odd_from_even(%arg: i8) -> i8 {
    %one = llvm.mlir.constant(1 : i8) : i8
    %clear_low_bit = llvm.mlir.constant(-2 : i8) : i8
    %even = llvm.and %arg, %clear_low_bit : i8
    %odd = llvm.add %even, %one : i8
    llvm.return %odd : i8
  }

  // Bounded arithmetic preserves more than a single parity bit. The low
  // nibble limits the increment, while making it odd prevents a borrow when
  // subtracting one.
  llvm.func @bounded_arithmetic(%arg: i8) -> i8 {
    %one = llvm.mlir.constant(1 : i8) : i8
    %low_nibble = llvm.mlir.constant(15 : i8) : i8
    %low = llvm.and %arg, %low_nibble : i8
    %increment = llvm.add %low, %one : i8
    %odd = llvm.or %low, %one : i8
    %predecessor = llvm.sub %odd, %one : i8
    llvm.return %increment : i8
  }

  llvm.func @subtraction_exact() -> i8 {
    %zero = llvm.mlir.constant(0 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    %three = llvm.mlir.constant(3 : i8) : i8
    %five = llvm.mlir.constant(5 : i8) : i8
    %difference = llvm.sub %five, %three : i8
    %underflow = llvm.sub %zero, %one : i8
    %self = llvm.sub %three, %three : i8
    llvm.return %difference : i8
  }

  llvm.func @subtraction_partial(%arg: i8) -> i8 {
    %one = llvm.mlir.constant(1 : i8) : i8
    %clear_low_bit = llvm.mlir.constant(-2 : i8) : i8
    %set_low_bit = llvm.mlir.constant(1 : i8) : i8
    %even = llvm.and %arg, %clear_low_bit : i8
    %odd = llvm.or %arg, %set_low_bit : i8
    %even_minus_one = llvm.sub %even, %one : i8
    %odd_minus_one = llvm.sub %odd, %one : i8
    llvm.return %even_minus_one : i8
  }

  // The merge argument should retain only facts true on both incoming paths:
  // zero and one agree that their upper seven bits are zero.
  llvm.func @join(%condition: i1) -> i8 {
    %zero = llvm.mlir.constant(0 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    llvm.cond_br %condition, ^zero_path, ^one_path

  ^zero_path:
    llvm.br ^merge(%zero : i8)

  ^one_path:
    llvm.br ^merge(%one : i8)

  ^merge(%value: i8):
    %result = llvm.or %value, %zero : i8
    llvm.return %result : i8
  }

  // Exercise entry-state construction for index using the 32-bit layout on
  // the module. Top is intentionally not printed by the analysis pass.
  func.func @index_width(%arg: index) {
    return
  }
}

// Dynamic corpus covering every implemented transfer function and a CFG join.
module {
  llvm.func @check_bitwise(%input: i8) -> i8 {
    %low_mask = llvm.mlir.constant(15 : i8) : i8
    %high_mask = llvm.mlir.constant(-16 : i8) : i8
    %all_ones = llvm.mlir.constant(-1 : i8) : i8
    %low = llvm.and %input, %low_mask : i8
    %high = llvm.or %input, %high_mask : i8
    %not_low = llvm.xor %low, %all_ones : i8
    %combined = llvm.xor %not_low, %high : i8
    llvm.return %combined : i8
  }

  llvm.func @check_addition(%input: i8) -> i8 {
    %one = llvm.mlir.constant(1 : i8) : i8
    %low_mask = llvm.mlir.constant(15 : i8) : i8
    %clear_low_bit = llvm.mlir.constant(-2 : i8) : i8
    %low = llvm.and %input, %low_mask : i8
    %even = llvm.and %input, %clear_low_bit : i8
    %bounded_increment = llvm.add %low, %one : i8
    %odd = llvm.add %even, %one : i8
    %combined = llvm.xor %bounded_increment, %odd : i8
    llvm.return %combined : i8
  }

  llvm.func @check_subtraction(%input: i8) -> i8 {
    %one = llvm.mlir.constant(1 : i8) : i8
    %clear_low_bit = llvm.mlir.constant(-2 : i8) : i8
    %even = llvm.and %input, %clear_low_bit : i8
    %odd = llvm.or %input, %one : i8
    %even_predecessor = llvm.sub %even, %one : i8
    %even_successor = llvm.sub %odd, %one : i8
    %combined = llvm.xor %even_predecessor, %even_successor : i8
    llvm.return %combined : i8
  }

  llvm.func @check_add_pair(%lhs: i8, %rhs: i8) -> i8 {
    %low_mask = llvm.mlir.constant(15 : i8) : i8
    %low_lhs = llvm.and %lhs, %low_mask : i8
    %low_rhs = llvm.and %rhs, %low_mask : i8
    %sum = llvm.add %low_lhs, %low_rhs : i8
    llvm.return %sum : i8
  }

  llvm.func @check_join(%condition: i1) -> i8 {
    %zero = llvm.mlir.constant(0 : i8) : i8
    %one = llvm.mlir.constant(1 : i8) : i8
    llvm.cond_br %condition, ^zero_path, ^one_path
  ^zero_path:
    llvm.br ^merge(%zero : i8)
  ^one_path:
    llvm.br ^merge(%one : i8)
  ^merge(%value: i8):
    llvm.return %value : i8
  }
}

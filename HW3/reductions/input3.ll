; Reduction 3: merging zero and one retains seven shared known zero bits.
source_filename = "join.c"

define i8 @zero_or_one(i1 %condition, i8 %noise) {
entry:
  %noise.xor = xor i8 %noise, 90
  br i1 %condition, label %zero.path, label %one.path

zero.path:
  %noise.zero = add i8 %noise.xor, 7
  br label %merge

one.path:
  %noise.one = sub i8 %noise.xor, 9
  br label %merge

merge:
  %value = phi i8 [ 0, %zero.path ], [ 1, %one.path ]
  %result = or i8 %value, 0
  ret i8 %result
}

define i8 @unrelated(i8 %x) {
entry:
  %masked = and i8 %x, -86
  ret i8 %masked
}

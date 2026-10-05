; Reduction 1: adding one to an unknown even byte produces an odd byte.
source_filename = "parity.c"

define i8 @odd_from_even(i8 %x) {
entry:
  %noise.xor = xor i8 %x, 90
  %noise.add = add i8 %noise.xor, 7
  %even = and i8 %x, -2
  %odd = add i8 %even, 1
  %noise.or = or i8 %noise.add, -128
  ret i8 %odd
}

define i8 @unrelated(i8 %x, i8 %y) {
entry:
  %sum = add i8 %x, %y
  %masked = and i8 %sum, 85
  ret i8 %masked
}

; Reduction 2: incrementing a low nibble value keeps bits 5-7 clear.
source_filename = "bounded.c"

define i8 @bounded_increment(i8 %x) {
entry:
  %noise.xor = xor i8 %x, -91
  %noise.sub = sub i8 %noise.xor, 12
  %low = and i8 %x, 15
  %incremented = add i8 %low, 1
  %noise.and = and i8 %noise.sub, 63
  ret i8 %incremented
}

define i8 @unrelated(i8 %x) {
entry:
  %set.high = or i8 %x, -16
  %difference = sub i8 %set.high, 3
  ret i8 %difference
}

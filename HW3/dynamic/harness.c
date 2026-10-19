#include <stdint.h>
#include <stdio.h>

extern uint8_t bounded_increment(uint8_t input);

unsigned known_bits_current_input;

int main(void) {
  for (unsigned input = 0; input <= UINT8_MAX; ++input) {
    known_bits_current_input = input;
    (void)bounded_increment((uint8_t)input);
  }

  puts("all 256 i8 inputs passed the dynamic known-bits checks");
  return 0;
}

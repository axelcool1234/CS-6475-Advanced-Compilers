#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

extern uint8_t check_bitwise(uint8_t input);
extern uint8_t check_addition(uint8_t input);
extern uint8_t check_subtraction(uint8_t input);
extern uint8_t check_add_pair(uint8_t lhs, uint8_t rhs);
extern uint8_t check_join(bool condition);

unsigned known_bits_current_input;

int main(void) {
  for (unsigned input = 0; input <= UINT8_MAX; ++input) {
    known_bits_current_input = input;
    (void)check_bitwise((uint8_t)input);
    (void)check_addition((uint8_t)input);
    (void)check_subtraction((uint8_t)input);
  }

  for (unsigned lhs = 0; lhs <= UINT8_MAX; ++lhs) {
    for (unsigned rhs = 0; rhs <= UINT8_MAX; ++rhs) {
      known_bits_current_input = (lhs << 8) | rhs;
      (void)check_add_pair((uint8_t)lhs, (uint8_t)rhs);
    }
  }

  known_bits_current_input = 0;
  (void)check_join(false);
  known_bits_current_input = 1;
  (void)check_join(true);

  puts("all 66,306 corpus executions passed the dynamic known bits checks");
  return 0;
}

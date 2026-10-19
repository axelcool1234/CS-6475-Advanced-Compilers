#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

extern unsigned known_bits_current_input;

void __known_bits_assert(bool condition, const char *message) {
  if (condition)
    return;

  fprintf(stderr, "dynamic known bits check failed for input %u: ",
          known_bits_current_input);
  fputs(message, stderr);
  abort();
}

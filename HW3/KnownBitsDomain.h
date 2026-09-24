//===- KnownBitsDomain.h - Placeholder abstract domain --------------------===//
//
// This deliberately contains only bottom and top.  Replace it with the
// known-bits lattice as part of the homework implementation.
//
//===----------------------------------------------------------------------===//

#ifndef KNOWN_BITS_DOMAIN_H
#define KNOWN_BITS_DOMAIN_H

#include "llvm/Support/raw_ostream.h"

namespace known_bits {

enum class Kind { Bottom, Top };

struct KnownBitsState {
  Kind kind = Kind::Bottom;

  KnownBitsState() = default;
  /* implicit */ KnownBitsState(Kind kind) : kind(kind) {}

  static KnownBitsState bottom() { return Kind::Bottom; }
  static KnownBitsState top() { return Kind::Top; }

  bool isBottom() const { return kind == Kind::Bottom; }
  bool isTop() const { return kind == Kind::Top; }

  static KnownBitsState join(const KnownBitsState &lhs,
                             const KnownBitsState &rhs) {
    if (lhs.isBottom())
      return rhs;
    if (rhs.isBottom())
      return lhs;
    return top();
  }

  bool operator==(const KnownBitsState &other) const {
    return kind == other.kind;
  }

  void print(llvm::raw_ostream &os) const {
    os << (isBottom() ? "bottom" : "top");
  }
};

inline llvm::raw_ostream &operator<<(llvm::raw_ostream &os,
                                     const KnownBitsState &state) {
  state.print(os);
  return os;
}

} // namespace known_bits

#endif

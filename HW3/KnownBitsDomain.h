//===- KnownBitsDomain.h - Known-bits abstract domain ---------------------===//
//
// Bits records which positions are definitely zero and definitely one.
// Transfer functions are responsible for constructing those facts.
//
//===----------------------------------------------------------------------===//

#ifndef KNOWN_BITS_DOMAIN_H
#define KNOWN_BITS_DOMAIN_H

#include "llvm/ADT/BitVector.h"
#include "llvm/Support/raw_ostream.h"

namespace known_bits {

enum class Kind { Bottom, Bits, Top };

struct KnownBitsState {
  llvm::BitVector zeros;
  llvm::BitVector ones;
  unsigned bitWidth = 0;
  Kind kind = Kind::Bottom;

  KnownBitsState() = default;
  /* implicit */ KnownBitsState(Kind kind) : kind(kind) {}
  KnownBitsState(unsigned bitWidth, llvm::BitVector zeros,
                 llvm::BitVector ones)
      : zeros(std::move(zeros)), ones(std::move(ones)), bitWidth(bitWidth),
        kind(Kind::Bits) {
    assert(this->zeros.size() == bitWidth &&
           "known-zero vector must match the bit width");
    assert(this->ones.size() == bitWidth &&
           "known-one vector must match the bit width");
    assert(!this->zeros.anyCommon(this->ones) &&
           "a bit cannot be both known zero and known one");
  }

  static KnownBitsState bottom() { return Kind::Bottom; }
  static KnownBitsState top() { return Kind::Top; }
  static KnownBitsState bits(unsigned bitWidth, llvm::BitVector zeros,
                             llvm::BitVector ones) {
    return KnownBitsState(bitWidth, std::move(zeros), std::move(ones));
  }

  bool isBottom() const { return kind == Kind::Bottom; }
  bool isBits() const { return kind == Kind::Bits; }
  bool isTop() const { return kind == Kind::Top; }

  KnownBitsState operator&&(const KnownBitsState &rhs) const {
    (void)rhs;
    // TODO: Implement known bits for AND.
    return top();
  }

  KnownBitsState operator||(const KnownBitsState &rhs) const {
    (void)rhs;
    // TODO: Implement known bits for OR.
    return top();
  }

  KnownBitsState operator^(const KnownBitsState &rhs) const {
    (void)rhs;
    // TODO: Implement known bits for XOR.
    return top();
  }

  static KnownBitsState join(const KnownBitsState &lhs,
                             const KnownBitsState &rhs) {
    if (lhs.isBottom())
      return rhs;
    if (rhs.isBottom())
      return lhs;
    if (lhs.isTop() || rhs.isTop() || lhs.bitWidth != rhs.bitWidth)
      return top();

    llvm::BitVector zeros = lhs.zeros;
    llvm::BitVector ones = lhs.ones;
    zeros &= rhs.zeros;
    ones &= rhs.ones;
    return bits(lhs.bitWidth, std::move(zeros), std::move(ones));
  }

  bool operator==(const KnownBitsState &other) const {
    if (kind != other.kind)
      return false;
    if (!isBits())
      return true;
    return bitWidth == other.bitWidth && zeros == other.zeros &&
           ones == other.ones;
  }

  bool operator!=(const KnownBitsState &other) const {
    return !(*this == other);
  }

  void print(llvm::raw_ostream &os) const {
    if (isBottom()) {
      os << "bottom";
      return;
    }
    if (isTop()) {
      os << "top";
      return;
    }

    auto printBits = [&](const llvm::BitVector &bits) {
      for (unsigned i = bitWidth; i > 0; --i)
        os << (bits.test(i - 1) ? '1' : '0');
    };

    os << "width=" << bitWidth << " ones=0b";
    printBits(ones);
    os << " zeros=0b";
    printBits(zeros);
  }
};

inline llvm::raw_ostream &operator<<(llvm::raw_ostream &os,
                                     const KnownBitsState &state) {
  state.print(os);
  return os;
}

} // namespace known_bits

#endif

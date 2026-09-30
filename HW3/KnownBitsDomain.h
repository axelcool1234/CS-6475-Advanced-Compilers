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

#include <cassert>
#include <optional>
#include <utility>

namespace mlir::LLVM {
class ConstantOp;
}

namespace known_bits {

enum class Kind { Bottom, Bits };

struct KnownBitsState {
  llvm::BitVector zeros;
  llvm::BitVector ones;
  unsigned bitWidth = 0;
  Kind kind = Kind::Bottom;

  KnownBitsState() = default;
  /* implicit */ KnownBitsState(Kind kind) : kind(kind) {}
  explicit KnownBitsState(mlir::LLVM::ConstantOp constant);
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
  static KnownBitsState top(unsigned bitWidth) {
    return bits(bitWidth, llvm::BitVector(bitWidth, false),
                llvm::BitVector(bitWidth, false));
  }
  static KnownBitsState bits(unsigned bitWidth, llvm::BitVector zeros,
                             llvm::BitVector ones) {
    return KnownBitsState(bitWidth, std::move(zeros), std::move(ones));
  }

  bool isBottom() const { return kind == Kind::Bottom; }
  bool isBits() const { return kind == Kind::Bits; }
  bool isTop() const { return isBits() && zeros.none() && ones.none(); }

  void assertCompatible(const KnownBitsState &rhs) const {
    assert(isBits() && "left operand must contain known-bits information");
    assert(rhs.isBits() &&
           "right operand must contain known-bits information");
    assert(bitWidth == rhs.bitWidth &&
           "known-bits operands must have the same bit width");
  }

  KnownBitsState operator&&(const KnownBitsState &rhs) const {
    assertCompatible(rhs);
    llvm::BitVector resultZeros = zeros;
    llvm::BitVector resultOnes = ones;
    resultZeros |= rhs.zeros;
    resultOnes &= rhs.ones;
    return KnownBitsState(bitWidth, std::move(resultZeros),
                          std::move(resultOnes));
  }

  KnownBitsState operator||(const KnownBitsState &rhs) const {
    assertCompatible(rhs);
    llvm::BitVector resultZeros = zeros;
    llvm::BitVector resultOnes = ones;
    resultZeros &= rhs.zeros;
    resultOnes |= rhs.ones;
    return KnownBitsState(bitWidth, std::move(resultZeros),
                          std::move(resultOnes));
  }

  KnownBitsState operator^(const KnownBitsState &rhs) const {
    assertCompatible(rhs);
    llvm::BitVector resultZeros = zeros;
    resultZeros &= rhs.zeros;
    llvm::BitVector bothOne = ones;
    bothOne &= rhs.ones;
    resultZeros |= bothOne;

    llvm::BitVector resultOnes = zeros;
    resultOnes &= rhs.ones;
    llvm::BitVector oneZero = ones;
    oneZero &= rhs.zeros;
    resultOnes |= oneZero;

    return KnownBitsState(bitWidth, std::move(resultZeros),
                          std::move(resultOnes));
  }

  KnownBitsState add(const KnownBitsState &rhs,
                     std::optional<bool> carry) const {
    assertCompatible(rhs);
    KnownBitsState state = top(bitWidth);
    for (unsigned i = 0; i < bitWidth; ++i) {
      if (zeros[i] == 1 && rhs.zeros[i] == 1) {
        if (carry.has_value()) {
          state.zeros[i] = !*carry;
          state.ones[i] = *carry;
        } else {
          state.zeros[i] = 0;
          state.ones[i] = 0;
        }
        carry = false;
      } else if ((zeros[i] == 1 && rhs.ones[i] == 1) ||
                 (ones[i] == 1 && rhs.zeros[i] == 1)) {
        if (carry.has_value()) {
          state.zeros[i] = *carry;
          state.ones[i] = !*carry;
        } else {
          state.zeros[i] = 0;
          state.ones[i] = 0;
        }
      } else if (ones[i] == 1 && rhs.ones[i] == 1) {
        if (carry.has_value()) {
          state.zeros[i] = !*carry;
          state.ones[i] = *carry;
        } else {
          state.zeros[i] = 0;
          state.ones[i] = 0;
        }
        carry = true;
      } else {
        state.zeros[i] = 0;
        state.ones[i] = 0;
        if (carry.has_value() && *carry == true && (ones[i] == 1 || rhs.ones[i] == 1)) {
          carry = true;
        } else if (carry.has_value() && *carry == false && (zeros[i] == 1 || rhs.zeros[i] == 1)) {
          carry = false;
        } else {
          carry = std::nullopt;
        }
      }
    }
    return state;
  }

  KnownBitsState invert() const {
    assert(isBits() && "operand must contain known-bits information");
    return KnownBitsState(bitWidth, ones, zeros);
  }

  KnownBitsState operator+(const KnownBitsState &rhs) const {
    return add(rhs, false);
  }

  KnownBitsState operator-(const KnownBitsState &rhs) const {
    assertCompatible(rhs);
    return add(rhs.invert(), true);
  }

  static KnownBitsState intersect(const KnownBitsState &lhs,
                                  const KnownBitsState &rhs) {
    lhs.assertCompatible(rhs);
    llvm::BitVector zeros = lhs.zeros;
    llvm::BitVector ones = lhs.ones;
    zeros &= rhs.zeros;
    ones &= rhs.ones;
    return bits(lhs.bitWidth, std::move(zeros), std::move(ones));
  }

  static KnownBitsState join(const KnownBitsState &lhs,
                             const KnownBitsState &rhs) {
    if (lhs.isBottom())
      return rhs;
    if (rhs.isBottom())
      return lhs;
    lhs.assertCompatible(rhs);
    if (lhs.isTop() || rhs.isTop())
      return top(lhs.bitWidth);

    return intersect(lhs, rhs);
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

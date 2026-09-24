//===- KnownBits.cpp - Known-bits transfer functions ----------------------===//
//
// The starter implementation proves nothing: every reachable value is top.
// Add the known-bits transfer functions here.
//
//===----------------------------------------------------------------------===//

#include "KnownBits.h"

using namespace mlir;

namespace known_bits {

void KnownBitsAnalysis::setToEntryState(KnownBitsLattice *lattice) {
  propagateIfChanged(lattice, lattice->join(KnownBitsState::top()));
}

LogicalResult KnownBitsAnalysis::visitOperation(
    Operation *op, ArrayRef<const KnownBitsLattice *> operands,
    ArrayRef<KnownBitsLattice *> results) {
  (void)op;
  (void)operands;
  setAllToEntryStates(results);
  return success();
}

} // namespace known_bits

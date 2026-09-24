//===- KnownBits.cpp - Known-bits transfer functions ----------------------===//
//
// The starter implementation proves nothing: every reachable value is top.
// Add the known-bits transfer functions here.
//
//===----------------------------------------------------------------------===//

#include "KnownBits.h"

#include "mlir/Dialect/LLVMIR/LLVMDialect.h"

using namespace mlir;

namespace known_bits {

void KnownBitsAnalysis::setToEntryState(KnownBitsLattice *lattice) {
  propagateIfChanged(lattice, lattice->join(KnownBitsState::top()));
}

LogicalResult KnownBitsAnalysis::visitOperation(
    Operation *op, ArrayRef<const KnownBitsLattice *> operands,
    ArrayRef<KnownBitsLattice *> results) {
  // Raising a result to top says "this operation could produce anything",
  // which is always a sound answer and is what every unhandled case does.
  auto unknown = [&] {
    setAllToEntryStates(results);
    return success();
  };

  // Bottom means an operand is unreachable or has not been analyzed yet.
  // Leave the results at bottom; the solver will revisit this operation when
  // the operand state changes.
  for (const KnownBitsLattice *operand : operands) {
    if (operand->getValue().isBottom())
      return success();
  }

  // Only single-result integer operations are interesting here. Calls, loads,
  // floats, and vectors all land in `unknown`.
  if (op->getNumResults() != 1 || !op->getResult(0).getType().isIntOrIndex())
    return unknown();
  KnownBitsLattice *result = results[0];

  if (operands.size() == 2) {
    const KnownBitsState &lhs = operands[0]->getValue();
    const KnownBitsState &rhs = operands[1]->getValue();

    if (isa<LLVM::AndOp>(op)) {
      propagateIfChanged(result, result->join(lhs && rhs));
      return success();
    }

    if (isa<LLVM::OrOp>(op)) {
      propagateIfChanged(result, result->join(lhs || rhs));
      return success();
    }

    if (isa<LLVM::XOrOp>(op)) {
      propagateIfChanged(result, result->join(lhs ^ rhs));
      return success();
    }
  }

  // Fallback
  return unknown();
}

} // namespace known_bits

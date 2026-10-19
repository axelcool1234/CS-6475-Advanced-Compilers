//===- KnownBits.h - Sparse forward known-bits analysis -------------------===//

#ifndef KNOWN_BITS_H
#define KNOWN_BITS_H

#include "KnownBitsDomain.h"
#include "mlir/Analysis/DataFlow/SparseAnalysis.h"

namespace known_bits {

using KnownBitsLattice = mlir::dataflow::Lattice<KnownBitsState>;

class KnownBitsAnalysis
    : public mlir::dataflow::SparseForwardDataFlowAnalysis<KnownBitsLattice> {
public:
  explicit KnownBitsAnalysis(mlir::DataFlowSolver &solver,
                             bool injectUnsoundAdd = false)
      : SparseForwardDataFlowAnalysis(solver),
        injectUnsoundAdd(injectUnsoundAdd) {}

  mlir::LogicalResult
  visitOperation(mlir::Operation *op,
                 llvm::ArrayRef<const KnownBitsLattice *> operands,
                 llvm::ArrayRef<KnownBitsLattice *> results) override;

  void setToEntryState(KnownBitsLattice *lattice) override;

private:
  /// Testing hook for the dynamic checker. When enabled, addition is
  /// deliberately (and incorrectly) modeled as carry-free XOR.
  bool injectUnsoundAdd;
};

} // namespace known_bits

#endif

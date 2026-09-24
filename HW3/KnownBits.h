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
  using SparseForwardDataFlowAnalysis::SparseForwardDataFlowAnalysis;

  mlir::LogicalResult
  visitOperation(mlir::Operation *op,
                 llvm::ArrayRef<const KnownBitsLattice *> operands,
                 llvm::ArrayRef<KnownBitsLattice *> results) override;

  void setToEntryState(KnownBitsLattice *lattice) override;
};

} // namespace known_bits

#endif

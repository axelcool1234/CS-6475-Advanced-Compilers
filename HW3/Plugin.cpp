//===- Plugin.cpp - Pass definition and plugin entry point ----------------===//
//
// Scaffolding: wires the analysis into a pass and exposes it to mlir-opt.
//
//===----------------------------------------------------------------------===//

#include "Annotate.h"
#include "KnownBits.h"

#include "mlir/Analysis/DataFlow/ConstantPropagationAnalysis.h"
#include "mlir/Analysis/DataFlow/DeadCodeAnalysis.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/AsmState.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Tools/Plugins/PassPlugin.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"

using namespace mlir;

namespace {

struct AssertionSite {
  Value value;
  known_bits::KnownBitsState state;
  std::string message;
};

/// Convert one known-bits fact into
///
///   ((value & (knownZero | knownOne)) == knownOne)
///
/// and pass the predicate plus a diagnostic string to the tiny C runtime.
/// The call is unconditional; the runtime aborts only when the predicate is
/// false. This avoids changing the program's CFG merely to insert checks.
static void insertAssertion(OpBuilder &builder, const AssertionSite &site,
                            unsigned id) {
  Location loc = site.value.getLoc();
  if (auto result = dyn_cast<OpResult>(site.value))
    builder.setInsertionPointAfter(result.getOwner());
  else
    builder.setInsertionPointToStart(cast<BlockArgument>(site.value).getOwner());

  const known_bits::KnownBitsState &state = site.state;
  llvm::APInt knownZeros(state.bitWidth, 0);
  llvm::APInt knownOnes(state.bitWidth, 0);
  for (unsigned bit = 0; bit < state.bitWidth; ++bit) {
    if (state.zeros[bit])
      knownZeros.setBit(bit);
    if (state.ones[bit])
      knownOnes.setBit(bit);
  }
  llvm::APInt knownMask = knownZeros | knownOnes;

  auto mask = LLVM::ConstantOp::create(builder, loc, site.value.getType(),
                                       knownMask);
  auto expected = LLVM::ConstantOp::create(builder, loc, site.value.getType(),
                                           knownOnes);
  auto masked = LLVM::AndOp::create(builder, loc, site.value, mask);
  auto valid = LLVM::ICmpOp::create(builder, loc, LLVM::ICmpPredicate::eq,
                                    masked, expected);

  std::string globalName = "__known_bits_message_" + std::to_string(id);
  Value message = LLVM::createGlobalString(
      loc, builder, globalName, site.message + "\n", LLVM::Linkage::Internal);
  SmallVector<Value> arguments{valid.getResult(), message};
  LLVM::CallOp::create(builder, loc, TypeRange{}, "__known_bits_assert",
                       arguments);
}

static void instrument(ModuleOp module, DataFlowSolver &solver) {
  SmallVector<AssertionSite> sites;
  AsmState asmState(module);

  module.walk([&](Operation *op) {
    // The checker emits LLVM-dialect operations, so constrain it to values in
    // LLVM functions and to ordinary integer values. Index values belong to a
    // different type system and are intentionally skipped.
    if (!op->getParentOfType<LLVM::LLVMFuncOp>())
      return;
    for (Value value : op->getResults()) {
      if (!isa<IntegerType>(value.getType()))
        continue;
      const auto *lattice =
          solver.lookupState<known_bits::KnownBitsLattice>(value);
      if (!lattice)
        continue;
      const known_bits::KnownBitsState &state = lattice->getValue();
      if (state.isTop() || state.isBottom())
        continue;

      std::string message;
      llvm::raw_string_ostream os(message);
      os << "known bits assertion for ";
      value.printAsOperand(os, asmState);
      os << " after " << op->getName() << " at ";
      op->getLoc().print(os);
      os << " (" << state << ")";
      sites.push_back({value, state, std::move(message)});
    }
  });

  // Block arguments can gain facts at control-flow joins, so check those at
  // block entry as well. Function arguments are usually top and are filtered
  // out naturally.
  module.walk([&](Block *block) {
    if (!block->getParentOp()->getParentOfType<LLVM::LLVMFuncOp>() &&
        !isa<LLVM::LLVMFuncOp>(block->getParentOp()))
      return;
    for (BlockArgument value : block->getArguments()) {
      if (!isa<IntegerType>(value.getType()))
        continue;
      const auto *lattice =
          solver.lookupState<known_bits::KnownBitsLattice>(value);
      if (!lattice)
        continue;
      const known_bits::KnownBitsState &state = lattice->getValue();
      if (state.isTop() || state.isBottom())
        continue;

      std::string message;
      llvm::raw_string_ostream os(message);
      os << "known bits assertion for block argument ";
      value.printAsOperand(os, asmState);
      os << " at ";
      value.getLoc().print(os);
      os << " (" << state << ")";
      sites.push_back({value, state, std::move(message)});
    }
  });

  if (sites.empty())
    return;

  OpBuilder builder(module.getContext());
  if (!module.lookupSymbol<LLVM::LLVMFuncOp>("__known_bits_assert")) {
    builder.setInsertionPointToStart(module.getBody());
    Type voidType = LLVM::LLVMVoidType::get(module.getContext());
    Type pointerType = LLVM::LLVMPointerType::get(module.getContext());
    Type functionType = LLVM::LLVMFunctionType::get(
        voidType, {builder.getI1Type(), pointerType}, false);
    LLVM::LLVMFuncOp::create(builder, module.getLoc(),
                             "__known_bits_assert", functionType);
  }

  for (auto [id, site] : llvm::enumerate(sites))
    insertAssertion(builder, site, id);
}

struct KnownBitsPass
    : PassWrapper<KnownBitsPass, OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(KnownBitsPass)

  KnownBitsPass() = default;
  KnownBitsPass(const KnownBitsPass &other) : PassWrapper(other) {}

  Option<bool> instrumentChecks{
      *this, "instrument",
      llvm::cl::desc("insert executable assertions for known-bits facts"),
      llvm::cl::init(false)};

  Option<bool> injectUnsoundAdd{
      *this, "inject-unsound-add",
      llvm::cl::desc("intentionally model addition as XOR for checker testing"),
      llvm::cl::init(false)};

  StringRef getArgument() const final { return "known-bits"; }

  StringRef getDescription() const final {
    return "Determine the known-zero and known-one bits of integer values";
  }

  void runOnOperation() override {
    DataFlowConfig config;
    config.setInterprocedural(false);

    DataFlowSolver solver(config);
    // DeadCodeAnalysis supplies reachability, without which the solver must
    // assume every branch is taken; SparseConstantPropagation resolves branch
    // conditions for it.  Both are prerequisites, not extras.
    solver.load<dataflow::DeadCodeAnalysis>();
    solver.load<dataflow::SparseConstantPropagation>();
    solver.load<known_bits::KnownBitsAnalysis>(injectUnsoundAdd.getValue());

    if (failed(solver.initializeAndRun(getOperation()))) {
      getOperation().emitError(
          "known-bits analysis failed to reach a fixed point");
      return signalPassFailure();
    }

    // Query states only now that the solver has converged.
    auto describe = [&](Value value, AsmState &asmState) -> std::string {
      const auto *lattice =
          solver.lookupState<known_bits::KnownBitsLattice>(value);
      if (!lattice)
        return {};
      const known_bits::KnownBitsState &state = lattice->getValue();
      // Top and bottom say nothing; printing them would bury the real facts.
      if (state.isTop() || state.isBottom())
        return {};
      std::string description;
      llvm::raw_string_ostream os(description);
      value.printAsOperand(os, asmState);
      os << " has known bits " << state;
      return description;
    };

    // stderr, so that mlir-opt's stdout stays the unmodified IR and the two can
    // be redirected independently.
    known_bits::printAnnotated(getOperation(), describe, llvm::errs());

    if (instrumentChecks)
      instrument(getOperation(), solver);
    else
      markAllAnalysesPreserved();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo mlirGetPassPluginInfo() {
  // LLVM_VERSION_STRING is baked in at compile time and checked by mlir-opt at
  // load time, which is what turns an ABI mismatch into a clear diagnostic.
  return {MLIR_PLUGIN_API_VERSION, "KnownBits", LLVM_VERSION_STRING,
          []() { PassRegistration<KnownBitsPass>(); }};
}

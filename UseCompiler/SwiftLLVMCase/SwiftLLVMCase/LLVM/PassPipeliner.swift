//
//  PassPipeliner.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// Implements a pass manager, pipeliner, and executor for a set of
/// user-provided optimization passes.
///
/// A `PassPipeliner` handles the creation of a related set of optimization
/// passes called a "pipeline".  Grouping passes is done for multiple reasons,
/// chief among them is that optimizer passes are extremely sensitive to their
/// ordering relative to other passes.  In addition, pass groupings allow for
/// the clean segregation of otherwise unrelated passes.  For example, a
/// pipeline might consist of "mandatory" passes such as Jump Threading, LICM,
/// and DCE in one pipeline and "diagnostic" passes in another.
public final class PassPipeliner {
  private enum PipelinePlan {
    case builtinPasses([Pass])
    case functionPassManager(LLVMPassManagerRef)
    case modulePassManager(LLVMPassManagerRef)
  }

  /// The module for this pass pipeline.
  public let module: Module
  /// The pipeline stages registered with this pass pipeliner.
  public private(set) var stages: [String]

  private var stageMapping: [String: PipelinePlan]
  private var frozen: Bool = false

  /// A helper object that can add passes to a pipeline.
  ///
  /// To add a new pass, call `add(_:)`.
  public final class Builder {
    fileprivate var passes: [Pass] = []

    fileprivate init() {}

    /// Appends a pass to the current pipeline.
    public func add(_ type: Pass) {
      self.passes.append(type)
    }
  }

  /// Initializes a new, empty pipeliner.
  ///
  /// - Parameter module: The module the pipeliner will run over.
  public init(module: Module) {
    self.module = module
    self.stages = []
    self.stageMapping = [:]
  }

  deinit {
    for stage in stageMapping.values {
      switch stage {
      case let .functionPassManager(pm):
        LLVMDisposePassManager(pm)
      case let .modulePassManager(pm):
        LLVMDisposePassManager(pm)
      case .builtinPasses(_):
        continue
      }
    }
  }

  /// Appends a stage to the pipeliner.
  ///
  /// The staging function provides a `Builder` object into which the types
  /// of passes for a given pipeline are inserted.
  ///
  /// - Parameters:
  ///   - name: The name of the pipeline stage.
  ///   - stager: A builder function.
  public func addStage(_ name: String, _ stager: (Builder) -> Void) {
    precondition(!self.frozen, "Cannot add new stages to a frozen pipeline!")

    self.frozen = true
    defer { self.frozen = false }

    self.stages.append(name)
    let builder = Builder()
    stager(builder)
    self.stageMapping[name] = .builtinPasses(builder.passes)
  }

  /// Executes the entirety of the pass pipeline.
  ///
  /// Execution of passes is done in a loop that is divided into two phases.
  /// The first phase aggregates all local passes and stops aggregation when
  /// it encounters a module-level pass.  This group of local passes
  /// is then run one at a time on the same scope.  The second phase is entered
  /// and the module pass is run.  The first phase is then re-entered until all
  /// local passes have run on all local scopes and all intervening module
  /// passes have been run.
  ///
  /// The same pipeline may be repeatedly re-executed, but pipeline execution
  /// is not re-entrancy safe.
  ///
  /// - Parameter pipelineMask: Describes the subset of pipelines that should
  ///   be executed.  If the mask is empty, all pipelines will be executed.
  public func execute(mask pipelineMask: Set<String> = []) {
    precondition(!self.frozen, "Cannot execute a frozen pipeline!")

    self.frozen = true
    defer { self.frozen = false }

    stageLoop: for stage in self.stages {
      guard pipelineMask.isEmpty || pipelineMask.contains(stage) else {
        continue
      }

      guard let pipeline = self.stageMapping[stage] else {
        fatalError("Unregistered pass stage?")
      }

      switch pipeline {
      case let .builtinPasses(passTypes):
        guard !passTypes.isEmpty else {
          continue stageLoop
        }
        self.runPasses(passTypes)
      case let .functionPassManager(pm):
        self.runFunctionPasses([], pm)
      case let .modulePassManager(pm):
        LLVMRunPassManager(pm, self.module.llvm)
      }
    }
  }

  private func runFunctionPasses(_ passes: [Pass], _ pm: LLVMPassManagerRef) {
    var keepalive = [Any]()
    LLVMInitializeFunctionPassManager(pm)

    for pass in passes {
      PassPipeliner.configurePass(pass, passManager: pm, keepalive: &keepalive)
    }

    for function in self.module.functions {
      LLVMRunFunctionPassManager(pm, function.asLLVM())
    }
  }

  private func runPasses(_ passes: [Pass]) {
    var keepalive = [Any]()
    let pm = LLVMCreatePassManager()!
    for pass in passes {
      PassPipeliner.configurePass(pass, passManager: pm, keepalive: &keepalive)
    }
    LLVMRunPassManager(pm, self.module.llvm)
    LLVMDisposePassManager(pm)
  }
}

// MARK: Standard Pass Pipelines

extension PassPipeliner {
  /// Adds a pipeline stage populated with function passes that LLVM considers
  /// standard for languages like C and C++.  Additional parameters are
  /// available to tune the overall behavior of the optimization pipeline at a
  /// macro level.
  ///
  /// - Parameters:
  ///   - name: The name of the pipeline stage.
  ///   - optimization: The level of optimization.
  ///   - size: The level of size optimization.
  public func addStandardFunctionPipeline(
    _ name: String,
    optimization: CodeGenOptLevel = .`default`,
    size: CodeGenOptLevel = .none
  ) {
    let passBuilder = self.configurePassBuilder(optimization, size)
    let functionPasses =
      LLVMCreateFunctionPassManagerForModule(self.module.llvm)!
    LLVMPassManagerBuilderPopulateFunctionPassManager(passBuilder,
                                                      functionPasses)
    LLVMPassManagerBuilderDispose(passBuilder)
    self.stages.append(name)
    self.stageMapping[name] = .functionPassManager(functionPasses)
  }

  /// Adds a pipeline stage populated with module passes that LLVM considers
  /// standard for languages like C and C++.  Additional parameters are
  /// available to tune the overall behavior of the optimization pipeline at a
  /// macro level.
  ///
  /// - Parameters:
  ///   - name: The name of the pipeline stage.
  ///   - optimization: The level of optimization.
  ///   - size: The level of size optimization.
  public func addStandardModulePipeline(
    _ name: String,
    optimization: CodeGenOptLevel = .`default`,
    size: CodeGenOptLevel = .none
  ) {
    let passBuilder = self.configurePassBuilder(optimization, size)
    let modulePasses = LLVMCreatePassManager()!
    LLVMPassManagerBuilderPopulateModulePassManager(passBuilder, modulePasses)
    LLVMPassManagerBuilderDispose(passBuilder)
    self.stages.append(name)
    self.stageMapping[name] = .modulePassManager(modulePasses)
  }

  private func configurePassBuilder(
    _ opt: CodeGenOptLevel,
    _ size: CodeGenOptLevel
  ) -> LLVMPassManagerBuilderRef {
    let passBuilder = LLVMPassManagerBuilderCreate()!
    switch opt {
    case .none:
      LLVMPassManagerBuilderSetOptLevel(passBuilder, 0)
    case .less:
      LLVMPassManagerBuilderSetOptLevel(passBuilder, 1)
    case .default:
      LLVMPassManagerBuilderSetOptLevel(passBuilder, 2)
    case .aggressive:
      LLVMPassManagerBuilderSetOptLevel(passBuilder, 3)
    }

    switch size {
    case .none:
      LLVMPassManagerBuilderSetSizeLevel(passBuilder, 0)
    case .less:
      LLVMPassManagerBuilderSetSizeLevel(passBuilder, 1)
    case .default:
      LLVMPassManagerBuilderSetSizeLevel(passBuilder, 2)
    case .aggressive:
      LLVMPassManagerBuilderSetSizeLevel(passBuilder, 3)
    }

    return passBuilder
  }
}


extension PassPipeliner {
  /// Configures and adds a pass to the given pass manager.
  ///
  /// - Parameters:
  ///   - pass: The pass to add to the pass manager.
  ///   - passManager: The pass manager to which to add a pass.
  ///   - keepalive: An array that must stay alive for as long as this pass
  ///                manager stays alive. This array will keep Swift objects
  ///                that may be passed into closures that will use them at
  ///                any point in the pass execution line.
  static func configurePass(
    _ pass: Pass,
    passManager: LLVMPassManagerRef,
    keepalive: inout [Any]) {
    switch pass {
    case .invalid(let reason):
      fatalError("Cannot configure pass: \(reason)")
    case .aggressiveDCE:
      LLVMAddAggressiveDCEPass(passManager)
    case .bitTrackingDCE:
      LLVMAddBitTrackingDCEPass(passManager)
    case .alignmentFromAssumptions:
      LLVMAddAlignmentFromAssumptionsPass(passManager)
    case .cfgSimplification:
      LLVMAddCFGSimplificationPass(passManager)
    case .deadStoreElimination:
      LLVMAddDeadStoreEliminationPass(passManager)
    case .scalarizer:
      LLVMAddScalarizerPass(passManager)
    case .mergedLoadStoreMotion:
      LLVMAddMergedLoadStoreMotionPass(passManager)
    case .gvn:
      LLVMAddGVNPass(passManager)
    case .indVarSimplify:
      LLVMAddIndVarSimplifyPass(passManager)
    case .instructionCombining:
      LLVMAddInstructionCombiningPass(passManager)
    case .jumpThreading:
      LLVMAddJumpThreadingPass(passManager)
    case .licm:
      LLVMAddLICMPass(passManager)
    case .loopDeletion:
      LLVMAddLoopDeletionPass(passManager)
    case .loopIdiom:
      LLVMAddLoopIdiomPass(passManager)
    case .loopRotate:
      LLVMAddLoopRotatePass(passManager)
    case .loopReroll:
      LLVMAddLoopRerollPass(passManager)
    case .loopUnroll:
      LLVMAddLoopUnrollPass(passManager)
    case .loopUnrollAndJam:
      LLVMAddLoopUnrollAndJamPass(passManager)
    case .loopUnswitch:
      LLVMAddLoopUnswitchPass(passManager)
    case .lowerAtomic:
      LLVMAddLowerAtomicPass(passManager)
    case .memCpyOpt:
      LLVMAddMemCpyOptPass(passManager)
    case .partiallyInlineLibCalls:
      LLVMAddPartiallyInlineLibCallsPass(passManager)
    case .lowerSwitch:
      LLVMAddLowerSwitchPass(passManager)
    case .promoteMemoryToRegister:
      LLVMAddPromoteMemoryToRegisterPass(passManager)
    case .addDiscriminators:
      LLVMAddAddDiscriminatorsPass(passManager)
    case .reassociate:
      LLVMAddReassociatePass(passManager)
    case .sccp:
      LLVMAddSCCPPass(passManager)
    case .tailCallElimination:
      LLVMAddTailCallEliminationPass(passManager)
    case .constantPropagation:
        break
//      LLVMAddConstantPropagationPass(passManager)
    case .demoteMemoryToRegister:
      LLVMAddDemoteMemoryToRegisterPass(passManager)
    case .verifier:
      LLVMAddVerifierPass(passManager)
    case .correlatedValuePropagation:
      LLVMAddCorrelatedValuePropagationPass(passManager)
    case .earlyCSE:
      LLVMAddEarlyCSEPass(passManager)
    case .lowerExpectIntrinsic:
      LLVMAddLowerExpectIntrinsicPass(passManager)
    case .typeBasedAliasAnalysis:
      LLVMAddTypeBasedAliasAnalysisPass(passManager)
    case .scopedNoAliasAA:
      LLVMAddScopedNoAliasAAPass(passManager)
    case .basicAliasAnalysis:
      LLVMAddBasicAliasAnalysisPass(passManager)
    case .globalsAliasAnalysis:
      LLVMAddGlobalsAAWrapperPass(passManager)
    case .unifyFunctionExitNodes:
      LLVMAddUnifyFunctionExitNodesPass(passManager)
    case .alwaysInliner:
      LLVMAddAlwaysInlinerPass(passManager)
    case .argumentPromotion:
      LLVMAddArgumentPromotionPass(passManager)
    case .constantMerge:
      LLVMAddConstantMergePass(passManager)
    case .deadArgElimination:
      LLVMAddDeadArgEliminationPass(passManager)
    case .functionAttrs:
      LLVMAddFunctionAttrsPass(passManager)
    case .functionInlining:
      LLVMAddFunctionInliningPass(passManager)
    case .globalDCE:
      LLVMAddGlobalDCEPass(passManager)
    case .globalOptimizer:
      LLVMAddGlobalOptimizerPass(passManager)
    case .ipConstantPropagation:
        break
//      LLVMAddIPConstantPropagationPass(passManager)
    case .ipscc:
      LLVMAddIPSCCPPass(passManager)
    case .pruneEH:
      LLVMAddPruneEHPass(passManager)
    case .stripDeadPrototypes:
      LLVMAddStripDeadPrototypesPass(passManager)
    case .stripSymbols:
      LLVMAddStripSymbolsPass(passManager)
    case .loopVectorize:
      LLVMAddLoopVectorizePass(passManager)
    case .slpVectorize:
      LLVMAddSLPVectorizePass(passManager)
    case .internalizeAll(let preserveMain):
      LLVMAddInternalizePass(passManager, preserveMain == false ? 0 : 1)
    case .internalize(let pred):
      // The lifetime of this callback is must be manually managed to ensure
      // it remains alive across the execution of the given pass manager.

      // Create a callback context at +1
      let callbackContext = InternalizeCallbackContext(pred)
      // Stick it in the keepalive array, now at +2
      keepalive.append(callbackContext)
      // Pass it unmanaged at +2
      let contextPtr = Unmanaged<InternalizeCallbackContext>.passUnretained(callbackContext).toOpaque()
      LLVMAddInternalizePassWithMustPreservePredicate(passManager, contextPtr) { globalValue, callbackCtx in
        guard let globalValue = globalValue, let callbackCtx = callbackCtx else {
          fatalError("Global value and context must be non-nil")
        }

        let callback = Unmanaged<InternalizeCallbackContext>.fromOpaque(callbackCtx).takeUnretainedValue()
        return callback.block(realizeGlobalValue(globalValue)).llvm
      }
      // Context dropped, now at +1
      // When the keepalive array is dropped by the caller, it will drop to +0.
    case .scalarReplacementOfAggregates:
      LLVMAddScalarReplAggregatesPassWithThreshold(passManager, /*ignored*/ 0)
    }
  }
}

private func realizeGlobalValue(_ llvm: LLVMValueRef) -> IRGlobal {
  precondition(llvm.isAGlobalValue, "must be a global value")
  if llvm.isAFunction {
    return Function(llvm: llvm)
  } else if llvm.isAGlobalAlias {
    return Alias(llvm: llvm)
  } else if llvm.isAGlobalVariable {
    return Global(llvm: llvm)
  } else {
    fatalError("unrecognized global value")
  }
}

private class InternalizeCallbackContext {
  fileprivate let block: (IRGlobal) -> Bool

  fileprivate init(_ block: @escaping (IRGlobal) -> Bool) {
    self.block = block
  }
}

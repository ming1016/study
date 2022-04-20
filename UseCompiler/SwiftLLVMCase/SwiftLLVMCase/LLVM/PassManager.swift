//
//  PassManager.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A subset of supported LLVM IR optimizer passes.
public enum Pass {
  ///  This pass uses the SSA based Aggressive DCE algorithm.  This algorithm
  /// assumes instructions are dead until proven otherwise, which makes
  /// it more successful are removing non-obviously dead instructions.
  case aggressiveDCE
  /// This pass uses a bit-tracking DCE algorithm in order to remove
  /// computations of dead bits.
  case bitTrackingDCE
  /// Use assume intrinsics to set load/store alignments.
  case alignmentFromAssumptions
  /// Merge basic blocks, eliminate unreachable blocks, simplify terminator
  /// instructions, etc.
  case cfgSimplification
  /// This pass deletes stores that are post-dominated by must-aliased stores
  /// and are not loaded used between the stores.
  case deadStoreElimination
  /// Converts vector operations into scalar operations.
  case scalarizer
  /// This pass merges loads and stores in diamonds. Loads are hoisted into the
  /// header, while stores sink into the footer.
  case mergedLoadStoreMotion
  /// This pass performs global value numbering and redundant load elimination
  /// cotemporaneously.
  case gvn
  /// Transform induction variables in a program to all use a single canonical
  /// induction variable per loop.
  case indVarSimplify
  /// Combine instructions to form fewer, simple instructions. This pass does
  /// not modify the CFG, and has a tendency to make instructions dead, so a
  /// subsequent DCE pass is useful.
  ///
  /// This pass combines things like:
  /// ```asm
  /// %Y = add int 1, %X
  /// %Z = add int 1, %Y
  /// ```
  /// into:
  /// ```asm
  /// %Z = add int 2, %X
  /// ```
  case instructionCombining
  /// Working in conjunction with the linker, iterate through all functions and
  /// global values in the module and attempt to change their linkage from
  /// external to internal.
  ///
  /// To preserve the linkage of a global value, return `true` from the given
  /// callback.
  case internalize(mustPreserve: (IRGlobal) -> Bool)
  /// Working in conjunction with the linker, iterate through all functions and
  /// global values in the module and attempt to change their linkage from
  /// external to internal.
  ///
  /// When a function with the name "main" is encountered, if the value of
  /// `preserveMain` is `true`, "main" will not be internalized.
  case internalizeAll(preserveMain: Bool)
  /// Thread control through mult-pred/multi-succ blocks where some preds
  /// always go to some succ. Thresholds other than minus one override the
  /// internal BB duplication default threshold.
  case jumpThreading
  /// This pass is a loop invariant code motion and memory promotion pass.
  case licm
  /// This pass performs DCE of non-infinite loops that it can prove are dead.
  case loopDeletion
  /// This pass recognizes and replaces idioms in loops.
  case loopIdiom
  /// This pass is a simple loop rotating pass.
  case loopRotate
  /// This pass is a simple loop rerolling pass.
  case loopReroll
  /// This pass is a simple loop unrolling pass.
  case loopUnroll
  /// This pass is a simple loop unroll-and-jam pass.
  case loopUnrollAndJam
  /// This pass is a simple loop unswitching pass.
  case loopUnswitch
  /// This pass lowers atomic intrinsics to non-atomic form for use in a known
  /// non-preemptible environment.
  case lowerAtomic
  /// This pass performs optimizations related to eliminating `memcpy` calls
  /// and/or combining multiple stores into memset's.
  case memCpyOpt
  /// Tries to inline the fast path of library calls such as sqrt.
  case partiallyInlineLibCalls
  /// This pass converts SwitchInst instructions into a sequence of chained
  /// binary branch instructions.
  case lowerSwitch
  /// This pass is used to promote memory references to
  /// be register references. A simple example of the transformation performed
  /// by this pass is going from code like this:
  ///
  /// ```asm
  /// %X = alloca i32, i32 1
  /// store i32 42, i32 *%X
  /// %Y = load i32* %X
  /// ret i32 %Y
  /// ```
  ///
  /// To code like this:
  ///
  /// ```asm
  /// ret i32 42
  /// ```
  case promoteMemoryToRegister
  /// Adds DWARF discriminators to the IR.  Discriminators are
  /// used to decide what CFG path was taken inside sub-graphs whose instructions
  /// share the same line and column number information.
  case addDiscriminators
  /// This pass reassociates commutative expressions in an order that
  /// is designed to promote better constant propagation, GCSE, LICM, PRE, etc.
  ///
  /// For example:
  /// ```
  /// 4 + (x + 5)  ->  x + (4 + 5)
  /// ```
  case reassociate
  /// Sparse conditional constant propagation.
  case sccp
  /// This pass eliminates call instructions to the current function which occur
  /// immediately before return instructions.
  case tailCallElimination
  /// A worklist driven constant propagation pass.
  case constantPropagation
  /// This pass is used to demote registers to memory references. It basically
  /// undoes the `.promoteMemoryToRegister` pass to make CFG hacking easier.
  case demoteMemoryToRegister
  /// Propagate CFG-derived value information
  case correlatedValuePropagation
  /// This pass performs a simple and fast CSE pass over the dominator tree.
  case earlyCSE
  ///  Removes `llvm.expect` intrinsics and creates "block_weights" metadata.
  case lowerExpectIntrinsic
  /// Adds metadata to LLVM IR types and performs metadata-based
  /// Type-Based Alias Analysis (TBAA).
  ///
  /// TBAA requires that two pointers to objects of different types must never
  /// alias.  Because memory in LLVM is typeless, TBAA is performed using
  /// special metadata nodes describing aliasing relationships between types
  /// in the source language(s).
  ///
  /// To construct this metadata, see `MDBuilder`.
  case typeBasedAliasAnalysis
  /// Adds metadata to LLVM IR types and performs metadata-based scoped no-alias
  /// analysis.
  case scopedNoAliasAA
  /// LLVM's primary stateless and local alias analysis.
  ///
  /// Given a pointer value, walk the use-def chain to find out how that
  /// pointer is used.  The traversal terminates at global variables and
  /// aliases, stack allocations, and values of non-pointer types - referred
  /// to as "underlying objects". Analysis may reach multiple underlying object
  /// values because of branching control flow.  If the set of underlying
  /// objects for one pointer has a non-empty intersection with another, those
  /// two pointers are deemed `mayalias`.  Else, an empty intersection deems
  /// those pointers `noalias`.
  ///
  /// Basic Alias Analysis should generally be scheduled ahead of other
  /// AA passes.  This is because it is more conservative than other passes
  /// about declaring two pointers `mustalias`, and does so fairly efficiently.
  /// For example, loads through two members of a union with distinct types are
  /// declared by TBAA to be `noalias`, where BasicAA considers them
  /// `mustalias`.
  case basicAliasAnalysis
  /// Performs alias and mod/ref analysis for internal global values that
  /// do not have their address taken.
  ///
  /// Internal global variables that are only loaded from may be marked as
  /// constants.
  case globalsAliasAnalysis
  /// This pass is used to ensure that functions have at most one return
  /// instruction in them.  Additionally, it keeps track of which node is
  /// the new exit node of the CFG.
  case unifyFunctionExitNodes
  /// Runs the LLVM IR Verifier to sanity check the results of passes.
  case verifier
  /// A pass to inline and remove functions marked as "always_inline".
  case alwaysInliner
  /// This pass promotes "by reference" arguments to be passed by value if the
  /// number of elements passed is less than or equal to 3.
  case argumentPromotion
  /// This function returns a new pass that merges duplicate global constants
  /// together into a single constant that is shared. This is useful because
  /// some passes (ie TraceValues) insert a lot of string constants into the
  /// program, regardless of whether or not they duplicate an existing string.
  case constantMerge
  /// This pass removes arguments from functions which are not used by the body
  /// of the function.
  case deadArgElimination
  /// This pass walks SCCs of the call graph in RPO to deduce and propagate
  /// function attributes. Currently it only handles synthesizing `norecurse`
  /// attributes.
  case functionAttrs
  /// Uses a heuristic to inline direct function calls to small functions.
  case functionInlining
  /// This transform is designed to eliminate unreachable internal globals
  /// (functions or global variables)
  case globalDCE
  /// This function returns a new pass that optimizes non-address taken internal
  /// globals.
  case globalOptimizer
  /// This pass propagates constants from call sites into the bodies of
  /// functions.
  case ipConstantPropagation
  /// This pass propagates constants from call sites into the bodies of
  /// functions, and keeps track of whether basic blocks are executable in the
  /// process.
  case ipscc
  /// Return a new pass object which transforms invoke instructions into calls,
  /// if the callee can *not* unwind the stack.
  case pruneEH
  /// This transformation attempts to discovery `alloca` allocations of aggregates that can be
  /// broken down into component scalar values.
  case scalarReplacementOfAggregates
  /// This pass removes any function declarations (prototypes) that are not used.
  case stripDeadPrototypes
  /// These functions removes symbols from functions and modules without
  /// touching symbols for debugging information.
  case stripSymbols
  /// Performs a loop vectorization pass to widen instructions in loops to
  /// operate on multiple consecutive iterations.
  case loopVectorize
  /// This pass performs a superword-level parallelism pass to combine
  /// similar independent instructions into vector instructions.
  case slpVectorize
  /// An invalid pass that crashes when added to the pass manager.
  case invalid(reason: String)
}

extension Pass {
  @available(*, deprecated, message: "Pass has been removed")
  static let simplifyLibCalls: Pass = .invalid(reason: "Pass has been removed")
  @available(*, deprecated, message: "Use the scalarReplacementOfAggregates instead")
  static let scalarReplAggregates: Pass = .invalid(reason: "Pass has been renamed to 'scalarReplacementOfAggregates'")
  @available(*, deprecated, message: "Use the scalarReplacementOfAggregates instead")
  static let scalarReplAggregatesSSA: Pass = .invalid(reason: "Pass has been renamed to 'scalarReplacementOfAggregates'")
}

/// A `FunctionPassManager` is an object that collects a sequence of passes
/// which run over a particular IR construct, and runs each of them in sequence
/// over each such construct.
@available(*, deprecated, message: "Use the PassPipeliner instead")
public class FunctionPassManager {
  internal let llvm: LLVMPassManagerRef
  var alivePassObjects = [Any]()

  /// Creates a `FunctionPassManager` bound to the given module's IR.
  public init(module: Module) {
    llvm = LLVMCreateFunctionPassManagerForModule(module.llvm)!
    LLVMInitializeFunctionPassManager(llvm)
  }

  /// Adds the given passes to the pass manager.
  ///
  /// - parameter passes: A list of function passes to add to the pass manager's
  ///   list of passes to run.
  public func add(_ passes: Pass...) {
    for pass in passes {
      PassPipeliner.configurePass(pass, passManager: llvm, keepalive: &alivePassObjects)
    }
  }

  /// Runs all listed functions in the pass manager on the given function.
  ///
  /// - parameter function: The function to run listed passes on.
  public func run(on function: Function) {
    LLVMRunFunctionPassManager(llvm, function.asLLVM())
  }
}

/// A subset of supported LLVM IR optimizer passes.
@available(*, deprecated, renamed: "Pass")
public typealias FunctionPass = Pass

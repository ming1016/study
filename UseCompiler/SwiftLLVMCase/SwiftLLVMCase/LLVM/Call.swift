//
//  Call.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// Represents a simple function call.
public struct Call: IRInstruction {
  let llvm: LLVMValueRef

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return self.llvm
  }

  /// Retrieves the number of argument operands passed by this call.
  public var argumentCount: Int {
    return Int(LLVMGetNumArgOperands(self.llvm))
  }

  /// Accesses the calling convention for this function call.
  public var callingConvention: CallingConvention {
    get { return CallingConvention(llvm: LLVMCallConv(rawValue: LLVMGetInstructionCallConv(self.llvm))) }
    set { LLVMSetInstructionCallConv(self.llvm, newValue.llvm.rawValue) }
  }

  /// Returns whether this function call is a tail call.
  ///
  /// A tail call may not reference memory in the stack frame of the calling
  /// function.  Therefore, the callee may reuse the stack memory of the caller.
  ///
  /// This attribute requires support from the target architecture.
  public var isTailCall: Bool {
    get { return LLVMIsTailCall(self.llvm) != 0 }
    set { LLVMSetTailCall(self.llvm, newValue.llvm) }
  }

  /// Accesses the tail call marker associated with this call.
  ///
  /// The presence of the tail call marker affects the optimizer's decisions
  /// around tail call optimizations.  The presence of a `tail` or `mustTail`
  /// marker, either inserted by the user or by the optimizer, is a strong
  /// hint (or a requirement) that tail call optimizations occur.  The presence
  /// of `noTail` acts to block any tail call optimization.
  ///
  /// Tail call optimization is finicky and requires a number of complex
  /// invariants hold before a call is eligible for the optimization.
  /// Even then, it is not necessarily guaranteed by LLVM in all cases.
  public var tailCallKind: TailCallKind {
    get { return TailCallKind(llvm: LLVMGetTailCallKind(self.llvm)) }
    set { return LLVMSetTailCallKind(self.llvm, newValue.llvm) }
  }

  /// Retrieves the alignment of the parameter at the given index.
  ///
  /// This property is currently set-only due to limitations of the LLVM C API.
  ///
  /// - parameter i: The index of the parameter to retrieve.
  /// - parameter alignment: The alignment to apply to the parameter.
  public func setParameterAlignment(at i : Int, to alignment: Alignment) {
    LLVMSetInstrParamAlignment(self.llvm, UInt32(i), alignment.rawValue)
  }
}

/// Represents a function call that may transfer control to an exception handler.
public struct Invoke: IRInstruction {
  let llvm: LLVMValueRef

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return self.llvm
  }

  /// Accesses the destination block the flow of control will transfer to if an
  /// exception does not occur.
  public var normalDestination: BasicBlock {
    get { return BasicBlock(llvm: LLVMGetNormalDest(self.llvm)) }
    set { LLVMSetNormalDest(self.llvm, newValue.asLLVM()) }
  }

  /// Accesses the destination block that exception unwinding will jump to.
  public var unwindDestination: BasicBlock {
    get { return BasicBlock(llvm: LLVMGetUnwindDest(self.llvm)) }
    set { LLVMSetUnwindDest(self.llvm, newValue.asLLVM()) }
  }
}

extension Call {
  /// Optimization markers for tail call elimination.
  public enum TailCallKind {
    /// No optimization tail call marker is present.  The optimizer is free to
    /// infer one of the other tail call markers.
    case none
    /// Suggests that tail call optimization should be performed on this
    /// function.  Note that this is not a guarantee.
    ///
    /// `tail` calls may not access caller-provided allocas, and may not
    /// access varargs.
    ///
    /// Tail call optimization for calls marked tail is guaranteed to occur if
    /// the following conditions are met:
    ///
    ///   - Caller and callee both have the calling convention `fastcc`.
    ///   - The call is in tail position (ret immediately follows `call` and
    ///     `ret` uses value of call or is void).
    ///   - Tail call elimination is enabled in the target machine's
    ///     `TargetOptions` or is globally enabled in LLVM.
    ///   - Platform-specific constraints are met.
    case tail
    /// Requires the tail call optimization be performed in order for this call
    /// to proceed correctly.
    ///
    /// Tail calls guarantee the following invariants:
    ///
    ///   - The call will not cause unbounded stack growth if it is part of a
    ///     recursive cycle in the call graph.
    ///   - Arguments with the `inalloca` attribute are forwarded in place.
    ///   - If the musttail call appears in a function with the `thunk`
    ///     attribute and the caller and callee both have varargs, than any
    ///     unprototyped arguments in register or memory are forwarded to the
    ///     callee. Similarly, the return value of the callee is returned the
    ///     the caller’s caller, even if a `void` return type is in use.
    ///
    /// `mustTail` calls may not access caller-provided allocas, and may not
    /// access varargs.  Unlike `tail`s, they are also subject to the following
    /// restrictions:
    ///
    ///   - The call must immediately precede a `ret` instruction, or a pointer
    ///     `bitcast` followed by a `ret` instruction.
    ///   - The `ret` instruction must return the (possibly `bitcast`ed) value
    ///     produced by the `call`, or return `void`.
    ///   - The caller and callee prototypes must match. Pointer types of
    ///     parameters or return types may differ in pointee type, but not in
    ///     address space.
    ///   - The calling conventions of the caller and callee must match.
    ///   - All ABI-impacting function attributes, such as `sret`, `byval`,
    ///     `inreg`, `returned`, and `inalloca`, must match.
    ///   - The callee must be varargs iff the caller is varargs. Bitcasting a
    ///     non-varargs function to the appropriate varargs type is legal so
    ///     long as the non-varargs prefixes obey the other rules.
    case mustTail
    /// Prevents tail call optimizations from being performed or inferred.
    case noTail

    internal init(llvm: LLVMTailCallKind) {
      switch llvm {
      case LLVMTailCallKindNone: self = .none
      case LLVMTailCallKindTail: self = .tail
      case LLVMTailCallKindMustTail: self = .mustTail
      case LLVMTailCallKindNoTail: self = .noTail
      default: fatalError("unknown tail call kind \(llvm)")
      }
    }

    private static let tailCallKindMapping: [TailCallKind: LLVMTailCallKind] = [
      .none: LLVMTailCallKindNone,
      .tail: LLVMTailCallKindTail,
      .mustTail: LLVMTailCallKindMustTail,
      .noTail: LLVMTailCallKindNoTail,
    ]

    /// Retrieves the corresponding `LLVMTailCallKind`.
    public var llvm: LLVMTailCallKind {
      return TailCallKind.tailCallKindMapping[self]!
    }
  }
}


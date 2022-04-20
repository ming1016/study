//
//  X86MMXType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// `X86MMXType` represents a value held in an MMX register on an x86 machine.
///
/// The operations allowed on it are quite limited: parameters and return
/// values, load and store, and bitcast. User-specified MMX instructions are
/// represented as intrinsic or asm calls with arguments and/or results of this
/// type. There are no arrays, vectors or constants of this type.
public struct X86MMXType: IRType {

  /// Returns the context associated with this type.
  public let context: Context

  /// Creates an `X86MMXType`.
  ///
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(in context: Context = Context.global) {
    self.context = context
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return LLVMX86MMXTypeInContext(context.llvm)
  }
}

extension X86MMXType: Equatable {
  public static func == (lhs: X86MMXType, rhs: X86MMXType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

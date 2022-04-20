//
//  LabelType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// `LabelType` represents code labels.
public struct LabelType: IRType {

  /// Returns the context associated with this type.
  public let context: Context

  /// Creates a code label.
  ///
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(in context: Context = Context.global) {
      self.context = context
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
   return LLVMLabelTypeInContext(context.llvm)
  }
}

extension LabelType: Equatable {
  public static func == (lhs: LabelType, rhs: LabelType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

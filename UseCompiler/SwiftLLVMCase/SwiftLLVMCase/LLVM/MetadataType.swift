//
//  MetadataType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// The `MetadataType` type represents embedded metadata. No derived types may
/// be created from metadata except for function arguments.
public struct MetadataType: IRType {
  /// Returns the context associated with this type.
  public let context: Context

  /// Creates an embedded metadata type for the given LLVM type object.
  ///
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(in context: Context = Context.global) {
    self.context = context
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return LLVMMetadataTypeInContext(context.llvm)
  }
}

extension MetadataType: Equatable {
  public static func == (lhs: MetadataType, rhs: MetadataType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

//
//  TokenType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// `TokenType` is used when a value is associated with an instruction but all
/// uses of the value must not attempt to introspect or obscure it. As such, it
/// is not appropriate to have a `PHI` or `select` of type `TokenType`.
public struct TokenType: IRType {
  /// Returns the context associated with this type.
  public let context: Context

  /// Initializes a token type from the given LLVM type object.
  ///
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(in context: Context = Context.global) {
    self.context = context
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return LLVMTokenTypeInContext(context.llvm)
  }
}

extension TokenType: Equatable {
  public static func == (lhs: TokenType, rhs: TokenType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

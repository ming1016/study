//
//  FunctionType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// `FunctionType` represents a function's type signature.  It consists of a
/// return type and a list of formal parameter types. The return type of a
/// function type is a `void` type or first class type — except for `LabelType`
/// and `MetadataType`.
public struct FunctionType: IRType {
  /// The list of argument types.
  public let parameterTypes: [IRType]
  /// The return type of this function type.
  public let returnType: IRType
  /// Returns whether this function is variadic.
  public let isVariadic: Bool

  /// Creates a function type with the given argument types and return type.
  ///
  /// - parameter argTypes: A list of the argument types of the function type.
  /// - parameter returnType: The return type of the function type.
  /// - parameter isVarArg: Indicates whether this function type is variadic.
  ///   Defaults to `false`.
  /// - note: The context of this type is taken from it's `returnType`
  @available(*, deprecated, message: "Use the more concise initializer instead", renamed: "FunctionType.init(_:_:variadic:)")
  public init(argTypes: [IRType], returnType: IRType, isVarArg: Bool = false) {
    self.parameterTypes = argTypes
    self.returnType = returnType
    self.isVariadic = isVarArg
  }

  /// Creates a function type with the given argument types and return type.
  ///
  /// - parameter parameterTypes: A list of the argument types of the function
  ///   type.
  /// - parameter returnType: The return type of the function type.
  /// - parameter variadic: Indicates whether this function type is variadic.
  ///   Defaults to `false`.
  /// - note: The context of this type is taken from it's `returnType`
  public init(
    _ parameterTypes: [IRType],
    _ returnType: IRType,
    variadic: Bool = false
  ) {
    self.parameterTypes = parameterTypes
    self.returnType = returnType
    self.isVariadic = variadic
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    var argIRTypes = parameterTypes.map { $0.asLLVM() as Optional }
    return argIRTypes.withUnsafeMutableBufferPointer { buf in
      return LLVMFunctionType(returnType.asLLVM(),
                              buf.baseAddress,
                              UInt32(buf.count),
                              isVariadic.llvm)!
    }
  }
}

// MARK: Legacy Accessors

extension FunctionType {
  /// The list of argument types.
  @available(*, deprecated, message: "Use FunctionType.parameterTypes instead")
  public var argTypes: [IRType] {
    return self.parameterTypes
  }
  /// Returns whether this function is variadic.
  @available(*, deprecated, message: "Use FunctionType.isVariadic instead")
  public var isVarArg: Bool {
    return self.isVariadic
  }
}

extension FunctionType: Equatable {
  public static func == (lhs: FunctionType, rhs: FunctionType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

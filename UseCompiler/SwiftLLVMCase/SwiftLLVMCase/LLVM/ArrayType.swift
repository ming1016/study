//
//  ArrayType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// `ArrayType` is a very simple derived type that arranges elements
/// sequentially in memory. `ArrayType` requires a size (number of elements) and
/// an underlying data type.
public struct ArrayType: IRType {
  /// The type of elements in this array.
  public let elementType: IRType
  /// The number of elements in this array.
  public let count: Int

  /// Creates an array type from an underlying element type and count.
  /// - note: The context of this type is taken from it's `elementType`
  public init(elementType: IRType, count: Int) {
    self.elementType = elementType
    self.count = count
  }

  /// Creates a constant array value from a list of IR values of a common type.
  ///
  /// - parameter values: A list of IR values of the same type.
  /// - parameter type: The type of the provided IR values.
  ///
  /// - returns: A constant array value containing the given values.
  public static func constant(_ values: [IRValue], type: IRType) -> IRConstant {
    var vals = values.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return Constant<Struct>(llvm: LLVMConstArray(type.asLLVM(), buf.baseAddress, UInt32(buf.count)))
    }
  }

  /// Creates a constant, null terminated array value of UTF-8 bytes from
  /// string's `utf8` member.
  ///
  /// - parameter string: A string to create a null terminated array from.
  /// - parameter context: The context to create the string in.
  ///
  /// - returns: A null terminated constant array value containing
  ///   `string.utf8.count + 1` i8's.
  public static func constant(string: String, in context: Context = .global) -> IRConstant {
    let length = string.utf8.count
    return Constant<Struct>(llvm: LLVMConstStringInContext(context.llvm, string, UInt32(length), 0))
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return LLVMArrayType(elementType.asLLVM(), UInt32(count))
  }
}

extension ArrayType: Equatable {
  public static func == (lhs: ArrayType, rhs: ArrayType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

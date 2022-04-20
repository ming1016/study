//
//  VectorType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A `VectorType` is a simple derived type that represents a vector of
/// elements. `VectorType`s are used when multiple primitive data are operated
/// in parallel using a single instruction (SIMD). A vector type requires a size
/// (number of elements) and an underlying primitive data type.
public struct VectorType: IRType {
  /// Returns the type of elements in the vector.
  public let elementType: IRType
  /// Returns the number of elements in the vector.
  public let count: Int

  /// Creates a vector type of the given element type and size.
  ///
  /// - parameter elementType: The type of elements of this vector.
  /// - parameter count: The number of elements in this vector.
  /// - note: The context of this type is taken from it's `elementType`
  public init(elementType: IRType, count: Int) {
    self.elementType = elementType
    self.count = count
  }

  /// Creates a constant value of this vector type initialized with the given
  /// list of values.
  ///
  /// - precondition: values.count == vector.count
  /// - parameter values: A list of values of elements of this vector.
  ///
  /// - returns: A value representing a constant value of this vector type.
  public func constant(_ values: [IRValue]) -> Constant<Vector> {
    assert(numericCast(values.count) == LLVMGetVectorSize(asLLVM()),
           "The number of values must match the number of elements in the vector")
    var vals = values.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return Constant(llvm: LLVMConstVector(buf.baseAddress,
                                            UInt32(buf.count)))
    }
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return LLVMVectorType(elementType.asLLVM(), UInt32(count))
  }
}

extension VectorType: Equatable {
  public static func == (lhs: VectorType, rhs: VectorType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

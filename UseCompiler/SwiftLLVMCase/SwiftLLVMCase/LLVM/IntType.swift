//
//  IntType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// The `IntType` represents an integral value of a specified bit width.
///
/// The `IntType` is a very simple type that simply specifies an arbitrary bit
/// width for the integer type desired. Any bit width from 1 bit to (2^23)-1
/// (about 8 million) can be specified.
public struct IntType: IRType {
  /// Retrieves the bit width of this integer type.
  public let width: Int

  /// Returns the context associated with this type.
  public let context: Context

  /// Creates an integer type with the specified bit width.
  ///
  /// - parameter width: The width in bits of the integer type
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(width: Int, in context: Context = Context.global) {
    self.width = width
    self.context = context
  }

  /// Retrieves the `i1` type.
  public static let int1 = IntType(width: 1)
  /// Retrieves the `i8` type.
  public static let int8 = IntType(width: 8)
  /// Retrieves the `i16` type.
  public static let int16 = IntType(width: 16)
  /// Retrieves the `i32` type.
  public static let int32 = IntType(width: 32)
  /// Retrieves the `i64` type.
  public static let int64 = IntType(width: 64)
  /// Retrieves the `i128` type.
  public static let int128 = IntType(width: 128)

  /// Retrieves an integer value of this type's bit width consisting of all
  /// zero-bits.
  ///
  /// - returns: A value consisting of all zero-bits of this type's bit width.
  public func zero() -> IRConstant {
    return null()
  }

  /// Creates an unsigned integer constant value with the given Swift integer value.
  ///
  /// - parameter value: A Swift integer value.
  /// - parameter signExtend: Whether to sign-extend this value to fit this
  ///   type's bit width.  Defaults to `false`.
  ///
  /// - returns: A value representing an unsigned integer constant initialized
  ///   with the given Swift integer value.
  public func constant<IntTy: UnsignedInteger>(_ value: IntTy, signExtend: Bool = false) -> Constant<Unsigned> {
    return Constant(llvm: LLVMConstInt(asLLVM(),
                          UInt64(value),
                          signExtend.llvm))
  }

  /// Creates a signed integer constant value with the given Swift integer value.
  ///
  /// - parameter value: A Swift integer value.
  /// - parameter signExtend: Whether to sign-extend this value to fit this
  ///   type's bit width.  Defaults to `false`.
  ///
  /// - returns: A value representing a signed integer constant initialized with
  ///   the given Swift integer value.
  public func constant<IntTy: SignedInteger>(_ value: IntTy, signExtend: Bool = false) -> Constant<Signed> {
    return Constant(llvm: LLVMConstInt(asLLVM(),
                                       UInt64(bitPattern: Int64(value)),
                                       signExtend.llvm))
  }

  /// Creates a constant integer value of this type parsed from a string.
  ///
  /// - parameter value: A string value containing an integer.
  /// - parameter radix: The radix, or base, to use for converting text to an
  ///   integer value.  Defaults to 10.
  ///
  /// - returns: A value representing a constant initialized with the result of
  ///   parsing the string as a signed integer.
  public func constant(_ value: String, radix: Int = 10) -> Constant<Signed> {
    return value.withCString { cString in
      return Constant(llvm: LLVMConstIntOfStringAndSize(asLLVM(), cString, UInt32(value.count), UInt8(radix)))
    }
  }

  /// Retrieves an integer value of this type's bit width consisting of all
  /// one-bits.
  ///
  /// - returns: A value consisting of all one-bits of this type's bit width.
  public func allOnes() -> IRConstant {
    return Constant<Struct>(llvm: LLVMConstAllOnes(asLLVM()))
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return LLVMIntTypeInContext(context.llvm, UInt32(width))
  }
}

extension IntType: Equatable {
  public static func == (lhs: IntType, rhs: IntType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

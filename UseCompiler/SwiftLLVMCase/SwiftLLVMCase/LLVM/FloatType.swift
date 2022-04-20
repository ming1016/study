//
//  FloatType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// `FloatType` enumerates representations of a floating value of a particular
/// bit width and semantics.
public struct FloatType: IRType {

  /// The kind of floating point type this is
  public var kind: Kind

  /// Returns the context associated with this type.
  public let context: Context

  /// Creates a float type of a particular kind
  ///
  /// - parameter kind: The kind of floating point type to create
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(kind: Kind, in context: Context = Context.global) {
    self.kind = kind
    self.context = context
  }

  /// Enumerates the bitwidth and kind of supported floating point types.
  public enum Kind {
    /// 16-bit floating point value
    case half
    /// 32-bit floating point value
    case float
    /// 64-bit floating point value
    case double
    /// 80-bit floating point value (X87)
    case x86FP80
    /// 128-bit floating point value (112-bit mantissa)
    case fp128
    /// 128-bit floating point value (two 64-bits)
    case ppcFP128
  }

  /// 16-bit floating point value in the global context
  public static let half = FloatType(kind: .half)
  /// 32-bit floating point value in the global context
  public static let float = FloatType(kind: .float)
  /// 64-bit floating point value in the global context
  public static let double = FloatType(kind: .double)
  /// 80-bit floating point value (X87) in the global context
  public static let x86FP80 = FloatType(kind: .x86FP80)
  /// 128-bit floating point value (112-bit mantissa) in the global context
  public static let fp128 = FloatType(kind: .fp128)
  /// 128-bit floating point value (two 64-bits) in the global context
  public static let ppcFP128 = FloatType(kind: .ppcFP128)

  /// Creates a constant floating value of this type from a Swift `Double` value.
  ///
  /// - parameter value: A Swift double value.
  ///
  /// - returns: A value representing a floating point constant initialized
  ///   with the given Swift double value.
  public func constant(_ value: Double) -> Constant<Floating> {
    return Constant(llvm: LLVMConstReal(asLLVM(), value))
  }

  /// Creates a constant floating value of this type parsed from a string.
  ///
  /// - parameter value: A string value containing a float.
  ///
  /// - returns: A value representing a constant initialized with the result of
  ///   parsing the string as a floating point number.
  public func constant(_ value: String) -> Constant<Floating> {
    return value.withCString { cString in
      return Constant(llvm: LLVMConstRealOfStringAndSize(asLLVM(), cString, UInt32(value.count)))
    }
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    switch kind {
    case .half: return LLVMHalfTypeInContext(context.llvm)
    case .float: return LLVMFloatTypeInContext(context.llvm)
    case .double: return LLVMDoubleTypeInContext(context.llvm)
    case .x86FP80: return LLVMX86FP80TypeInContext(context.llvm)
    case .fp128: return LLVMFP128TypeInContext(context.llvm)
    case .ppcFP128: return LLVMPPCFP128TypeInContext(context.llvm)
    }
  }
}

extension FloatType: Equatable {
  public static func == (lhs: FloatType, rhs: FloatType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

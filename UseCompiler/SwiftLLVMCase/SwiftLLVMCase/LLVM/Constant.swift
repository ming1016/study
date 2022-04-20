//
//  Constant.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An `IRConstant` is an entity whose value doees not change during the
/// runtime of a program.  This includes global variables and functions, whose
/// addresses are constant, and constant expressions.
public protocol IRConstant: IRValue {}

extension IRConstant {
  /// Perform a GEP (Get Element Pointer) with this value as the base.
  ///
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func constGEP(indices: [IRConstant]) -> IRConstant {
    var idxs = indices.map { $0.asLLVM() as Optional }
    return idxs.withUnsafeMutableBufferPointer { buf in
      return Constant<Struct>(llvm: LLVMConstGEP(asLLVM(), buf.baseAddress, UInt32(buf.count)))
    }
  }

  /// Build a constant bitcast to convert the given value to a value of the
  /// given type by just copying the bit pattern.
  ///
  /// - parameter type: The destination type.
  ///
  /// - returns: A constant value representing the result of bitcasting this
  ///   constant value to fit the given type.
  public func bitCast(to type: IRType) -> IRConstant {
    return Constant<Struct>(llvm: LLVMConstBitCast(asLLVM(), type.asLLVM()))
  }
}

/// A protocol to which the phantom types for a constant's representation conform.
public protocol ConstantRepresentation {}
/// A protocol to which the phantom types for all numerical constants conform.
public protocol NumericalConstantRepresentation: ConstantRepresentation {}
/// A protocol to which the phantom types for integral constants conform.
public protocol IntegralConstantRepresentation: NumericalConstantRepresentation {}

/// Represents unsigned integral types and operations.
public enum Unsigned: IntegralConstantRepresentation {}
/// Represents signed integral types and operations.
public enum Signed: IntegralConstantRepresentation {}
/// Represents floating types and operations.
public enum Floating: NumericalConstantRepresentation {}
/// Represents struct types and operations.
public enum Struct: ConstantRepresentation {}
/// Represents vector types and operations.
public enum Vector: ConstantRepresentation {}

/// A `Constant` represents a value initialized to a constant.  Constant values
/// may be manipulated with standard Swift arithmetic operations and used with
/// standard IR Builder instructions like any other operand.  The difference
/// being any instructions acting solely on constants and any arithmetic
/// performed on constants is evaluated at compile-time only.
///
/// `Constant`s keep track of the values they represent at the type level to
/// disallow mixed-type arithmetic.  Use the `cast` family of operations to
/// safely convert constants to other representations.
public struct Constant<Repr: ConstantRepresentation>: IRConstant {
  internal let llvm: LLVMValueRef

  internal init(llvm: LLVMValueRef!) {
    self.llvm = llvm
  }

  /// Retrieves the underlying LLVM constant object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }
}


// MARK: Casting

extension Constant where Repr: IntegralConstantRepresentation {

  /// Creates a constant cast to a given integral type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   integral type.
  public func cast(to type: IntType) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstIntCast(llvm, type.asLLVM(), /*signed:*/ true.llvm))
  }

  /// Creates a constant cast to a given integral type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   integral type.
  public func cast(to type: IntType) -> Constant<Unsigned> {
    return Constant<Unsigned>(llvm: LLVMConstIntCast(llvm, type.asLLVM(), /*signed:*/ false.llvm))
  }
}

extension Constant where Repr == Unsigned {

  /// Creates a constant cast to a given floating type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   floating type.
  public func cast(to type: FloatType) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstUIToFP(llvm, type.asLLVM()))
  }
}

extension Constant where Repr == Signed {

  /// Creates a constant cast to a given integral type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   integral type.
  public func cast(to type: IntType) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstIntCast(llvm, type.asLLVM(), /*signed:*/ true.llvm))
  }

  /// Creates a constant cast to a given integral type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   integral type.
  public func cast(to type: IntType) -> Constant<Unsigned> {
    return Constant<Unsigned>(llvm: LLVMConstIntCast(llvm, type.asLLVM(), /*signed:*/ false.llvm))
  }

  /// Creates a constant cast to a given floating type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   floating type.
  public func cast(to type: FloatType) -> Constant<Floating> {
    let val = self.asLLVM()
    return Constant<Floating>(llvm: LLVMConstSIToFP(val, type.asLLVM()))
  }
}

extension Constant where Repr == Floating {

  /// Creates a constant cast to a given integral type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   integral type.
  public func cast(to type: IntType) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstFPToSI(llvm, type.asLLVM()))
  }

  /// Creates a constant cast to a given integral type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   integral type.
  public func cast(to type: IntType) -> Constant<Unsigned> {
    return Constant<Unsigned>(llvm: LLVMConstFPToUI(llvm, type.asLLVM()))
  }

  /// Creates a constant cast to a given floating type.
  ///
  /// - parameter type: The type to cast towards.
  ///
  /// - returns: A const value representing this value cast to the given
  ///   floating type.
  public func cast(to type: FloatType) -> Constant<Floating> {
    let val = self.asLLVM()
    return Constant<Floating>(llvm: LLVMConstFPCast(val, type.asLLVM()))
  }
}


// NOTE: These are here to improve the error message should a user attempt to cast a const struct

extension Constant where Repr == Struct {

  @available(*, unavailable, message: "You cannot cast an aggregate type. See the LLVM Reference manual's section on `bitcast`")
  public func cast<T: IntegralConstantRepresentation>(to type: IntType) -> Constant<T> {
    fatalError()
  }

  @available(*, unavailable, message: "You cannot cast an aggregate type. See the LLVM Reference manual's section on `bitcast`")
  public func cast(to type: FloatType) -> Constant<Floating> {
    fatalError()
  }
}

// MARK: Truncation

extension Constant where Repr == Signed {
  /// Creates a constant truncated to a given integral type.
  ///
  /// - parameter type: The type to truncate towards.
  ///
  /// - returns: A const value representing this value truncated to the given
  ///   integral type's bitwidth.
  public func truncate(to type: IntType) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstTrunc(llvm, type.asLLVM()))
  }
}

extension Constant where Repr == Unsigned {
  /// Creates a constant truncated to a given integral type.
  ///
  /// - parameter type: The type to truncate towards.
  ///
  /// - returns: A const value representing this value truncated to the given
  ///   integral type's bitwidth.
  public func truncate(to type: IntType) -> Constant<Unsigned> {
    return Constant<Unsigned>(llvm: LLVMConstTrunc(llvm, type.asLLVM()))
  }
}

extension Constant where Repr == Floating {
  /// Creates a constant truncated to a given floating type.
  ///
  /// - parameter type: The type to truncate towards.
  ///
  /// - returns: A const value representing this value truncated to the given
  ///   floating type's bitwidth.
  public func truncate(to type: FloatType) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFPTrunc(llvm, type.asLLVM()))
  }

  /// Creates a constant extended to a given floating type.
  ///
  /// - parameter type: The type to extend towards.
  ///
  /// - returns: A const value representing this value extended to the given
  ///   floating type's bitwidth.
  public func extend(to type: FloatType) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFPExt(llvm, type.asLLVM()))
  }
}

// MARK: Arithmetic Operations

// MARK: Negation

extension Constant {

  /// Creates a constant negate operation to negate a value.
  ///
  /// - parameter lhs: The operand to negate.
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the negation of the given constant.
  public static func negate(_ lhs: Constant<Signed>, overflowBehavior: OverflowBehavior = .default) -> Constant<Signed> {

    let lhsVal = lhs.asLLVM()
    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Signed>(llvm: LLVMConstNSWNeg(lhsVal))
    case .noUnsignedWrap:
      return Constant<Signed>(llvm: LLVMConstNUWNeg(lhsVal))
    case .default:
      return Constant<Signed>(llvm: LLVMConstNeg(lhsVal))
    }
  }

  /// Creates a constant negate operation to negate a value.
  ///
  /// - parameter lhs: The operand to negate.
  ///
  /// - returns: A constant value representing the negation of the given constant.
  public static func negate(_ lhs: Constant<Floating>) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFNeg(lhs.llvm))
  }
}

extension Constant where Repr == Signed {

  /// Creates a constant negate operation to negate a value.
  ///
  /// - returns: A constant value representing the negation of the given constant.
  public func negate() -> Constant {
    return Constant.negate(self)
  }
}

extension Constant where Repr == Floating {

  /// Creates a constant negate operation to negate a value.
  ///
  /// - returns: A constant value representing the negation of the given constant.
  public func negate() -> Constant {
    return Constant.negate(self)
  }
}

// MARK: Addition

extension Constant {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public static func add(_ lhs: Constant<Unsigned>, _ rhs: Constant<Unsigned>, overflowBehavior: OverflowBehavior = .default) -> Constant<Unsigned> {

    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Unsigned>(llvm: LLVMConstNSWAdd(lhs.llvm, rhs.llvm))
    case .noUnsignedWrap:
      return Constant<Unsigned>(llvm: LLVMConstNUWAdd(lhs.llvm, rhs.llvm))
    case .default:
      return Constant<Unsigned>(llvm: LLVMConstAdd(lhs.llvm, rhs.llvm))
    }
  }

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public static func add(_ lhs: Constant<Signed>, _ rhs: Constant<Signed>, overflowBehavior: OverflowBehavior = .default) -> Constant<Signed> {

    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Signed>(llvm: LLVMConstNSWAdd(lhs.llvm, rhs.llvm))
    case .noUnsignedWrap:
      return Constant<Signed>(llvm: LLVMConstNUWAdd(lhs.llvm, rhs.llvm))
    case .default:
      return Constant<Signed>(llvm: LLVMConstAdd(lhs.llvm, rhs.llvm))
    }
  }

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public static func add(_ lhs: Constant<Floating>, _ rhs: Constant<Floating>) -> Constant<Floating> {

    return Constant<Floating>(llvm: LLVMConstFAdd(lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Signed {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter rhs: The second summand value (the addend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public func adding(_ rhs: Constant, overflowBehavior: OverflowBehavior = .default) -> Constant {
    return Constant.add(self, rhs, overflowBehavior: overflowBehavior)
  }
}

extension Constant where Repr == Unsigned {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter rhs: The second summand value (the addend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public func adding(_ rhs: Constant, overflowBehavior: OverflowBehavior = .default) -> Constant {
    return Constant.add(self, rhs, overflowBehavior: overflowBehavior)
  }
}

extension Constant where Repr == Floating {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter rhs: The second summand value (the addend).
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public func adding(_ rhs: Constant) -> Constant {
    return Constant.add(self, rhs)
  }
}

// MARK: Subtraction

extension Constant {

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public static func subtract(_ lhs: Constant<Unsigned>, _ rhs: Constant<Unsigned>, overflowBehavior: OverflowBehavior = .default) -> Constant<Unsigned> {

    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Unsigned>(llvm: LLVMConstNSWSub(lhs.llvm, rhs.llvm))
    case .noUnsignedWrap:
      return Constant<Unsigned>(llvm: LLVMConstNUWSub(lhs.llvm, rhs.llvm))
    case .default:
      return Constant<Unsigned>(llvm: LLVMConstSub(lhs.llvm, rhs.llvm))
    }
  }

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public static func subtract(_ lhs: Constant<Signed>, _ rhs: Constant<Signed>, overflowBehavior: OverflowBehavior = .default) -> Constant<Signed> {

    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Signed>(llvm: LLVMConstNSWSub(lhs.llvm, rhs.llvm))
    case .noUnsignedWrap:
      return Constant<Signed>(llvm: LLVMConstNUWSub(lhs.llvm, rhs.llvm))
    case .default:
      return Constant<Signed>(llvm: LLVMConstSub(lhs.llvm, rhs.llvm))
    }
  }

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public static func subtract(_ lhs: Constant<Floating>, _ rhs: Constant<Floating>) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFSub(lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Unsigned {

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter rhs: The second value (the subtrahend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public func subtracting(_ rhs: Constant, overflowBehavior: OverflowBehavior = .default) -> Constant {
    return Constant.subtract(self, rhs, overflowBehavior: overflowBehavior)
  }
}

extension Constant where Repr == Signed {

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter rhs: The second value (the subtrahend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public func subtracting(_ rhs: Constant, overflowBehavior: OverflowBehavior = .default) -> Constant {
    return Constant.subtract(self, rhs, overflowBehavior: overflowBehavior)
  }
}

extension Constant where Repr == Floating {

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter rhs: The second value (the subtrahend).
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public func subtracting(_ rhs: Constant) -> Constant {
    return Constant.subtract(self, rhs)
  }
}

// MARK: Multiplication

extension Constant {

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the product of the two operands.
  public static func multiply(_ lhs: Constant<Unsigned>, _ rhs: Constant<Unsigned>, overflowBehavior: OverflowBehavior = .default) -> Constant<Unsigned> {

    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Unsigned>(llvm: LLVMConstNSWMul(lhs.llvm, rhs.llvm))
    case .noUnsignedWrap:
      return Constant<Unsigned>(llvm: LLVMConstNUWMul(lhs.llvm, rhs.llvm))
    case .default:
      return Constant<Unsigned>(llvm: LLVMConstMul(lhs.llvm, rhs.llvm))
    }
  }

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the product of the two operands.
  public static func multiply(_ lhs: Constant<Signed>, _ rhs: Constant<Signed>, overflowBehavior: OverflowBehavior = .default) -> Constant<Signed> {

    switch overflowBehavior {
    case .noSignedWrap:
      return Constant<Signed>(llvm: LLVMConstNSWMul(lhs.llvm, rhs.llvm))
    case .noUnsignedWrap:
      return Constant<Signed>(llvm: LLVMConstNUWMul(lhs.llvm, rhs.llvm))
    case .default:
      return Constant<Signed>(llvm: LLVMConstMul(lhs.llvm, rhs.llvm))
    }
  }

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  ///
  /// - returns: A constant value representing the product of the two operands.
  public static func multiply(_ lhs: Constant<Floating>, _ rhs: Constant<Floating>) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFMul(lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Unsigned {

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter rhs: The second factor value (the multiplicand).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the product of the two operands.
  public func multiplying(_ rhs: Constant, overflowBehavior: OverflowBehavior = .default) -> Constant {
    return Constant.multiply(self, rhs, overflowBehavior: overflowBehavior)
  }
}

extension Constant where Repr == Signed {

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter rhs: The second factor value (the multiplicand).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the resulting constant value.
  ///
  /// - returns: A constant value representing the product of the two operands.
  public func multiplying(_ rhs: Constant, overflowBehavior: OverflowBehavior = .default) -> Constant {
    return Constant.multiply(self, rhs, overflowBehavior: overflowBehavior)
  }
}

extension Constant where Repr == Floating {

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  ///
  /// - returns: A constant value representing the product of the two operands.
  public func multiplying(_ rhs: Constant) -> Constant {
    return Constant.multiply(self, rhs)
  }
}

// MARK: Divide

extension Constant {

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public static func divide(_ lhs: Constant<Unsigned>, _ rhs: Constant<Unsigned>) -> Constant<Unsigned> {
    return Constant<Unsigned>(llvm: LLVMConstUDiv(lhs.llvm, rhs.llvm))
  }

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public static func divide(_ lhs: Constant<Signed>, _ rhs: Constant<Signed>) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstSDiv(lhs.llvm, rhs.llvm))
  }

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public static func divide(_ lhs: Constant<Floating>, _ rhs: Constant<Floating>) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFDiv(lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Unsigned {

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public func dividing(by rhs: Constant) -> Constant {
    return Constant.divide(self, rhs)
  }
}

extension Constant where Repr == Signed {

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public func dividing(by rhs: Constant) -> Constant {
    return Constant.divide(self, rhs)
  }
}

extension Constant where Repr == Floating {

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public func dividing(by rhs: Constant) -> Constant {
    return Constant.divide(self, rhs)
  }
}

// MARK: Remainder

extension Constant {

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public static func remainder(_ lhs: Constant<Unsigned>, _ rhs: Constant<Unsigned>) -> Constant<Unsigned> {
    return Constant<Unsigned>(llvm: LLVMConstURem(lhs.llvm, rhs.llvm))
  }

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public static func remainder(_ lhs: Constant<Signed>, _ rhs: Constant<Signed>) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstSRem(lhs.llvm, rhs.llvm))
  }

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public static func remainder(_ lhs: Constant<Floating>, _ rhs: Constant<Floating>) -> Constant<Floating> {
    return Constant<Floating>(llvm: LLVMConstFRem(lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Unsigned {

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public func remainder(_ rhs: Constant) -> Constant {
    return Constant.remainder(self, rhs)
  }
}

extension Constant where Repr == Signed {

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public func remainder(_ rhs: Constant) -> Constant {
    return Constant.remainder(self, rhs)
  }
}

extension Constant where Repr == Floating {

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public func remainder(_ rhs: Constant) -> Constant {
    return Constant.remainder(self, rhs)
  }
}

// MARK: Comparison Operations

extension Constant where Repr: IntegralConstantRepresentation {

  /// A constant equality comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func equals(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.equal.llvm, lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Signed {

  /// A constant less-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func lessThan(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.unsignedLessThan.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant greater-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func greaterThan(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.signedGreaterThan.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant less-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func lessThanOrEqual(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.signedLessThanOrEqual.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant greater-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func greaterThanOrEqual(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.signedGreaterThanOrEqual.llvm, lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Unsigned {

  /// A constant less-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func lessThan(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.unsignedLessThan.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant greater-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func greaterThan(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.unsignedGreaterThan.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant less-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func lessThanOrEqual(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.unsignedLessThanOrEqual.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant greater-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func greaterThanOrEqual(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstICmp(IntPredicate.unsignedGreaterThanOrEqual.llvm, lhs.llvm, rhs.llvm))
  }
}

extension Constant where Repr == Floating {

  /// A constant equality comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func equals(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstFCmp(RealPredicate.orderedEqual.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant less-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func lessThan(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstFCmp(RealPredicate.orderedLessThan.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant greater-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func greaterThan(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstFCmp(RealPredicate.orderedGreaterThan.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant less-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func lessThanOrEqual(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstFCmp(RealPredicate.orderedLessThanOrEqual.llvm, lhs.llvm, rhs.llvm))
  }

  /// A constant greater-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func greaterThanOrEqual(_ lhs: Constant, _ rhs: Constant) -> Constant<Signed> {
    return Constant<Signed>(llvm: LLVMConstFCmp(RealPredicate.orderedGreaterThanOrEqual.llvm, lhs.llvm, rhs.llvm))
  }
}


// MARK: Logical Operations

extension Constant {

  /// A constant bitwise logical not with the given integral value as an operand.
  ///
  /// - parameter val: The value to negate.
  ///
  /// - returns: A constant value representing the logical negation of the given
  ///   operand.
  public static func not<T: IntegralConstantRepresentation>(_ lhs: Constant<T>) -> Constant<T> {
    return Constant<T>(llvm: LLVMConstNot(lhs.llvm))
  }

  /// A constant bitwise logical AND with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A constant value representing the logical OR of the values of
  ///   the two given operands.
  public static func and<T: IntegralConstantRepresentation>(_ lhs: Constant<T>, _ rhs: Constant<T>) -> Constant<T> {
    return Constant<T>(llvm: LLVMConstAnd(lhs.llvm, rhs.llvm))
  }

  /// A constant bitwise logical OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A constant value representing the logical OR of the values of
  ///   the two given operands.
  public static func or<T: IntegralConstantRepresentation>(_ lhs: Constant<T>, _ rhs: Constant<T>) -> Constant<T> {
    return Constant<T>(llvm: LLVMConstOr(lhs.llvm, rhs.llvm))
  }

  /// A constant bitwise logical exclusive OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the exclusive OR of the values of
  ///   the two given operands.
  public static func xor<T: IntegralConstantRepresentation>(_ lhs: Constant<T>, _ rhs: Constant<T>) -> Constant<T> {
    return Constant<T>(llvm: LLVMConstXor(lhs.llvm, rhs.llvm))
  }

  // MARK: Bitshifting Operations

  /// A constant left-shift of the first value by the second amount.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the value of the first operand
  ///   shifted left by the number of bits specified in the second operand.
  public static func leftShift<T: IntegralConstantRepresentation>(_ lhs: Constant<T>, _ rhs: Constant<T>) -> Constant<T> {
    return Constant<T>(llvm: LLVMConstShl(lhs.llvm, rhs.llvm))
  }

  /// A constant right-shift of the first value by the second amount.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter arithmetic: Should the shift be arithmetic or logical (defaults to true)
  ///
  /// - returns: A constant value representing the value of the first operand
  ///   shifted left by the number of bits specified in the second operand.
  public static func rightShift<T: IntegralConstantRepresentation>(_ lhs: Constant<T>, _ rhs: Constant<T>, arithmetic: Bool = true) -> Constant<T> {
    return Constant<T>(llvm: arithmetic ? LLVMConstAShr(lhs.llvm, rhs.llvm) : LLVMConstLShr(lhs.llvm, rhs.llvm))
  }

  // MARK: Conditional Operations

  /// A constant select using the given condition to select among two values.
  ///
  /// - parameter cond: The condition to evaluate.  It must have type `i1` or
  ///   be a vector of `i1`.
  /// - parameter then: The value to select if the given condition is true.
  /// - parameter else: The value to select if the given condition is false.
  ///
  /// - returns: A constant value representing the constant value selected for
  ///   by the condition.
  public static func select<T: IntegralConstantRepresentation, U>(_ cond: Constant<T>, then: Constant<U>, else: Constant<U>) -> Constant<U> {
    assert((cond.type as! IntType).width == 1)
    return Constant<U>(llvm: LLVMConstSelect(cond.llvm, then.llvm, `else`.llvm))
  }
}

// MARK: Constant Pointer To Integer

extension Constant where Repr: IntegralConstantRepresentation {
  /// Creates a constant pointer-to-integer operation to convert the given constant
  /// global pointer value to the given integer type.
  ///
  /// - parameter val: The pointer value.
  /// - parameter intType: The destination integer type.
  ///
  /// - returns: An constant value representing the constant value of the given
  ///   pointer converted to the given integer type.
  public static func pointerToInt(_ val: IRConstant, _ intType: IntType) -> Constant {
    precondition(val.isConstant, "May only convert global constant pointers to integers")
    return Constant<Repr>(llvm: LLVMConstPtrToInt(val.asLLVM(), intType.asLLVM()))
  }
}

// MARK: Struct Operations

extension Constant where Repr == Struct {

  /// Creates a constant operation retrieving the element at the index.
  ///
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  ///
  /// - returns: The value in the struct at the provided index.
  public func getElement(indices: [Int]) -> IRConstant {
    var indices = indices.map({ UInt32($0) })
    return indices.withUnsafeMutableBufferPointer { buf in
      return Constant<Struct>(llvm: LLVMConstExtractValue(asLLVM(), buf.baseAddress, UInt32(buf.count)))
    }
  }

  /// Build a constant `GEP` (Get Element Pointer) instruction with a resultant
  /// value that is undefined if the address is outside the actual underlying
  /// allocated object and not the address one-past-the-end.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func getElementPointer(indices: [IRConstant]) -> IRConstant {
    var indices = indices.map({ $0.asLLVM() as LLVMValueRef? })
    return indices.withUnsafeMutableBufferPointer { buf in
      return Constant<Struct>(llvm: LLVMConstGEP(asLLVM(), buf.baseAddress, UInt32(buf.count)))
    }
  }

  /// Build a GEP (Get Element Pointer) instruction.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func inBoundsGetElementPointer(indices: [IRConstant]) -> IRConstant {
    var indices = indices.map({ $0.asLLVM() as LLVMValueRef? })
    return indices.withUnsafeMutableBufferPointer { buf in
      return Constant<Struct>(llvm: LLVMConstInBoundsGEP(asLLVM(), buf.baseAddress, UInt32(buf.count)))
    }
  }
}

// MARK: Vector Operations

extension Constant where Repr == Vector {
  /// Builds a constant operation to construct a permutation of elements
  /// from the two given input vectors, returning a vector with the same element
  /// type as the inputs and length that is the same as the shuffle mask.
  ///
  /// - parameter vector1: The first constant vector to shuffle.
  /// - parameter vector2: The second constant vector to shuffle.
  /// - parameter mask: A constant vector of `i32` values that acts as a mask
  ///   for the shuffled vectors.
  ///
  /// - returns: A value representing a constant vector with the same element
  ///   type as the inputs and length that is the same as the shuffle mask.
  public static func buildShuffleVector(_ vector1: Constant, and vector2: Constant, mask: Constant) -> Constant {
    guard let maskTy = mask.type as? VectorType, maskTy.elementType is IntType else {
      fatalError("Vector shuffle mask's elements must be 32-bit integers")
    }
    return Constant(llvm: LLVMConstShuffleVector(vector1.asLLVM(), vector2.asLLVM(), mask.asLLVM()))
  }
}

// MARK: Swift Operators

extension Constant where Repr == Floating {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public static func +(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.adding(rhs)
  }

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public static func -(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.subtracting(rhs)
  }

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  ///
  /// - returns: A constant value representing the product of the two operands.
  public static func *(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.multiplying(rhs)
  }

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public static func /(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.dividing(by: rhs)
  }

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public static func %(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.remainder(rhs)
  }

  /// A constant equality comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func ==(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.equals(lhs, rhs)
  }

  /// A constant less-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func <(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.lessThan(lhs, rhs)
  }

  /// A constant greater-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func >(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.greaterThan(lhs, rhs)
  }

  /// A constant less-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func <=(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.lessThanOrEqual(lhs, rhs)
  }

  /// A constant greater-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func >=(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.greaterThanOrEqual(lhs, rhs)
  }
}

extension Constant where Repr == Signed {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public static func +(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.adding(rhs)
  }

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public static func -(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.subtracting(rhs)
  }

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  ///
  /// - returns: A constant value representing the product of the two operands.
  public static func *(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.multiplying(rhs)
  }

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public static func /(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.dividing(by: rhs)
  }

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public static func %(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.remainder(rhs)
  }

  /// A constant equality comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func ==(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.equals(lhs, rhs)
  }

  /// A constant less-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func <(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.lessThan(lhs, rhs)
  }

  /// A constant greater-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func >(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.greaterThan(lhs, rhs)
  }

  /// A constant less-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func <=(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.lessThanOrEqual(lhs, rhs)
  }

  /// A constant greater-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func >=(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.greaterThanOrEqual(lhs, rhs)
  }

  /// A constant bitwise logical OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the logical OR of the values of
  ///   the two given operands.
  public static func |(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.or(lhs, rhs)
  }

  /// A constant bitwise logical AND with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the logical OR of the values of
  ///   the two given operands.
  public static func &(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.and(lhs, rhs)
  }

  /// A constant left-shift of the first value by the second amount.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the value of the first operand
  ///   shifted left by the number of bits specified in the second operand.
  public static func <<(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.leftShift(lhs, rhs)
  }

  /// A constant right-shift of the first value by the second amount.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the value of the first operand
  ///   shifted left by the number of bits specified in the second operand.
  public static func >>(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.rightShift(lhs, rhs)
  }
}

extension Constant where Repr == Unsigned {

  /// Creates a constant add operation to add two homogenous constants together.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  ///
  /// - returns: A constant value representing the sum of the two operands.
  public static func +(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.adding(rhs)
  }

  /// Creates a constant sub operation to subtract two homogenous constants.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  ///
  /// - returns: A constant value representing the difference of the two operands.
  public static func -(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.subtracting(rhs)
  }

  /// Creates a constant multiply operation with the given values as operands.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  ///
  /// - returns: A constant value representing the product of the two operands.
  public static func *(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.multiplying(rhs)
  }

  /// A constant divide operation that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the quotient of the first and
  ///   second operands.
  public static func /(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.dividing(by: rhs)
  }

  /// A constant remainder operation that provides the remainder after divison
  /// of the first value by the second value.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  ///
  /// - returns: A constant value representing the remainder of division of the
  ///   first operand by the second operand.
  public static func %(lhs: Constant, rhs: Constant) -> Constant {
    return lhs.remainder(rhs)
  }

  /// A constant equality comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func ==(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.equals(lhs, rhs)
  }

  /// A constant less-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func <(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.lessThan(lhs, rhs)
  }

  /// A constant greater-than comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func >(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.greaterThan(lhs, rhs)
  }

  /// A constant less-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func <=(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.lessThanOrEqual(lhs, rhs)
  }

  /// A constant greater-than-or-equal comparison between two values.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  ///
  /// - returns: A constant integral value (i1) representing the result of the
  ///   comparision of the given operands.
  public static func >=(lhs: Constant, rhs: Constant) -> Constant<Signed> {
    return Constant.greaterThanOrEqual(lhs, rhs)
  }

  /// A constant bitwise logical OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the logical OR of the values of
  ///   the two given operands.
  public static func |(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.or(lhs, rhs)
  }

  /// A constant bitwise logical AND with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the logical OR of the values of
  ///   the two given operands.
  public static func &(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.and(lhs, rhs)
  }

  /// A constant left-shift of the first value by the second amount.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the value of the first operand
  ///   shifted left by the number of bits specified in the second operand.
  public static func <<(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.leftShift(lhs, rhs)
  }

  /// A constant right-shift of the first value by the second amount.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  ///
  /// - returns: A constant value representing the value of the first operand
  ///   shifted left by the number of bits specified in the second operand.
  public static func >>(lhs: Constant, rhs: Constant) -> Constant {
    return Constant.rightShift(lhs, rhs)
  }
}

extension Constant where Repr: IntegralConstantRepresentation {

  /// A constant bitwise logical not with the given integral value as an operand.
  ///
  /// - parameter val: The value to negate.
  ///
  /// - returns: A constant value representing the logical negation of the given
  ///   operand.
  public static prefix func !(_ lhs: Constant) -> Constant {
    return Constant(llvm: LLVMConstNot(lhs.llvm))
  }
}

// MARK: Undef

extension Constant where Repr: IntegralConstantRepresentation {
  /// Returns the special LLVM `undef` value for this type.
  ///
  /// The `undef` value can be used anywhere a constant is expected, and
  /// indicates that the user of the value may receive an unspecified
  /// bit-pattern.
  public static func undef(_ ty: IntType) -> Constant {
    return Constant<Repr>(llvm: ty.undef().asLLVM())
  }
}

extension Constant where Repr == Floating {
  /// Returns the special LLVM `undef` value for this type.
  ///
  /// The `undef` value can be used anywhere a constant is expected, and
  /// indicates that the user of the value may receive an unspecified
  /// bit-pattern.
  public static func undef(_ ty: FloatType) -> Constant {
    return Constant(llvm: ty.undef().asLLVM())
  }
}

extension Constant where Repr == Struct {
  /// Returns the special LLVM `undef` value for this type.
  ///
  /// The `undef` value can be used anywhere a constant is expected, and
  /// indicates that the user of the value may receive an unspecified
  /// bit-pattern.
  public static func undef(_ ty: StructType) -> Constant {
    return Constant(llvm: ty.undef().asLLVM())
  }
}

extension Constant where Repr == Vector {
  /// Returns the special LLVM `undef` value for this type.
  ///
  /// The `undef` value can be used anywhere a constant is expected, and
  /// indicates that the user of the value may receive an unspecified
  /// bit-pattern.
  public static func undef(_ ty: VectorType) -> Constant {
    return Constant(llvm: ty.undef().asLLVM())
  }
}

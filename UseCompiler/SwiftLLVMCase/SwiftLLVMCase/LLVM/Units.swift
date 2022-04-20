//
//  Units.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import Foundation

/// An alignment value, expressed in bytes.
public struct Alignment: Comparable, Hashable {
  /// Accesses the raw alignment value in bytes.
  ///
  /// - warning: This accessor allows breaking out of the Alignment abstraction
  ///   for raw alignment calculations.  It is therefore not recommended that
  ///   this accessor be used in user code.
  public let rawValue: UInt32

  /// A zero-byte alignment value.
  public static let zero = Alignment(0)
  /// An one-byte alignment value.
  public static let one = Alignment(1)

  /// Initializes and returns an alignment with the given value interpreted as
  /// a quantity of bytes.
  public init(_ value: UInt32) {
    self.rawValue = value
  }

  /// Returns true if this alignment value is zero bytes, else return false.
  public var isZero: Bool {
    return self.rawValue == 0
  }

  /// Returns the log-base-two value of this alignment as a 32-bit integer.
  ///
  /// An n-byte alignment contains log-base-two-many least-significant zeros.
  public func log2() -> UInt32 {
    guard !isZero else { return 0 }
    return 31 - UInt32(self.rawValue.leadingZeroBitCount)
  }

  /// Returns the log-base-two value of this alignment as a 64-bit integer.
  ///
  /// An n-byte alignment contains log-base-two-many least-significant zeros.
  public func log2() -> UInt64 {
    guard !isZero else { return 0 }
    // rawValue is only 32 bits
    return 31 - UInt64(self.rawValue.leadingZeroBitCount)
  }
  
  /// Returns the alignment of a pointer which points to the given number of
  /// bytes after a pointer with this alignment.
  public func alignment(at offset: Size) -> Alignment {
    assert(self.rawValue != 0, "called on object with zero alignment")

    // If the offset is zero, use the original alignment.
    var V = Int32(offset.rawValue)
    guard V != 0 else {
      return self
    }

    // Find the offset's largest power-of-two factor.
    V = V & -V

    // The alignment at the offset is then the min of the two values.
    guard V < self.rawValue else {
      return self
    }

    return Alignment(UInt32(V))
  }

  public static func == (lhs: Alignment, rhs: Alignment) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public static func < (lhs: Alignment, rhs: Alignment) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }
}

/// This is an opaque type for sizes expressed in aggregate bit units, usually 8
/// bits per unit.
///
/// Instances of this type represent a quantity as a multiple of a radix size
/// - e.g. the size of a `char` in bits on the target architecture. As an opaque
/// type, `Size` protects you from accidentally combining operations on
/// quantities in bit units and size units.
///
/// For portability, never assume that a target radix is 8 bits wide. Use
/// Size values wherever you calculate sizes and offsets.
public struct Size {
  /// Accesses the raw value unitless value of this size.
  ///
  /// - warning: This accessor breaks the `Size` abstraction by allowing access
  ///   to the raw value. The underlying value is unitless and hence any
  ///   reinterpretation may lead to incorrect results in calculations that
  ///   depend on precise bit and byte-level arithmetic.  This accessor should
  ///   not be used by user code in general.
  public let rawValue: UInt64

  /// A size carrying a value of zero.
  public static let zero = Size(0)
  /// A size carrying a value of one.
  public static let one = Size(1)

  /// Initializes and returns a size carrying the given value.
  public init(_ value: UInt64) {
    self.rawValue = value
  }

  /// Initializes and returns a size carrying the given value which represents
  /// a value in bits with a given radix.
  ///
  /// - parameter bitSize: A given number of bits.
  /// - parameter radix: The radix value. Defaults to 8 bits per size unit.
  public init(bits bitSize: UInt64, radix: UInt64 = 8) {
    precondition(radix > 0, "radix cannot be 0")
    self.rawValue = (bitSize + (radix - 1)) / radix
  }

  /// Returns the value of this size in bits according to a given radix.
  ///
  /// - parameter radix: The radix value. Defaults to 8 bits per size unit.
  /// - returns: A value in bits.
  public func valueInBits(radix: UInt64 = 8) -> UInt64 {
    return self.rawValue * radix
  }

  /// Returns true if this size value is a power of two, including if it is
  /// zero.  Returns false otherwise.
  public var isPowerOfTwo: Bool {
    return (self.rawValue != 0)
        && ((self.rawValue & (self.rawValue - 1)) == 0)
  }

  /// Computes a size with value rounded up to the next highest value that is
  /// a multiple of the given alignment value.
  ///
  /// - parameter alignment: The alignment value.  Must not be zero.
  /// - returns: A size representing the given value rounded up to the given
  ///   alignment value.
  public func roundUp(to alignment: Alignment) -> Size {
    precondition(!alignment.isZero, "Cannot round up with zero alignment!")
    let mask = UInt64(alignment.rawValue - 1)
    let value = self.rawValue + mask
    return Size(value & ~mask)
  }

  /// Returns the remainder of dividing the first size value
  /// by the second alignment value.  This has the effect of aligning the
  /// size value subtractively.
  public static func % (lhs: Size, rhs: Alignment) -> Size {
    return Size(lhs.rawValue % UInt64(rhs.rawValue))
  }
}

extension Size: UnsignedInteger {
  public init<T>(clamping source: T) where T : BinaryInteger {
    self.init(UInt64(clamping: source))
  }

  public init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
    self.init(UInt64(clamping: source))
  }

  public init?<T>(exactly source: T) where T : BinaryInteger {
    guard let val = UInt64(exactly: source) else {
      return nil
    }
    self.init(val)
  }

  public init(integerLiteral value: UInt64) {
    self.init(value)
  }

  public init?<T>(exactly source: T) where T : BinaryFloatingPoint {
    guard let val = UInt64(exactly: source) else {
      return nil
    }
    self.init(val)
  }

  public init<T>(_ source: T) where T : BinaryFloatingPoint {
    self.init(UInt64(source))
  }

  public init<T>(_ source: T) where T : BinaryInteger {
    self.init(UInt64(source))
  }

  public var words: UInt64.Words {
    return self.rawValue.words
  }

  public var bitWidth: Int {
    return self.rawValue.bitWidth
  }

  public var trailingZeroBitCount: Int {
    return self.rawValue.trailingZeroBitCount
  }

  public static func == (lhs: Size, rhs: Size) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public static func < (lhs: Size, rhs: Size) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }


  public func hash(into hasher: inout Hasher) {
    self.rawValue.hash(into: &hasher)
  }

  public static func + (lhs: Size, rhs: Size) -> Size {
    var lhs = lhs
    lhs += rhs
    return lhs
  }
  public static func += (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue + rhs.rawValue)
  }

  public static func - (lhs: Size, rhs: Size) -> Size {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }
  public static func -= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue - rhs.rawValue)
  }

  public static func * (lhs: Size, rhs: Size) -> Size {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }
  public static func *= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue * rhs.rawValue)
  }

  public static func / (lhs: Size, rhs: Size) -> Size {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }
  public static func /= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue / rhs.rawValue)
  }

  public static func % (lhs: Size, rhs: Size) -> Size {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }
  public static func %= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue % rhs.rawValue)
  }

  public static func &= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue & rhs.rawValue)
  }

  public static func |= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue | rhs.rawValue)
  }

  public static func ^= (lhs: inout Size, rhs: Size) {
    lhs = Size(lhs.rawValue ^ rhs.rawValue)
  }

  public static func >>= <RHS: BinaryInteger>(lhs: inout Size, rhs: RHS) {
    lhs = Size(lhs.rawValue >> rhs)
  }

  public static func <<= <RHS: BinaryInteger>(lhs: inout Size, rhs: RHS) {
    lhs = Size(lhs.rawValue << rhs)
  }

  public static prefix func ~ (x: Size) -> Size {
    return Size(~x.rawValue)
  }

  /// Returns true if the given size is a multiple of this size.
  public func isMultiple(of other: Size) -> Bool {
    return (self.rawValue % other.rawValue) == 0
  }

  public typealias IntegerLiteralType = UInt64
  public typealias Words = UInt64.Words
}

extension Size {
  /// Multiplies a size value by a raw unitless value and produces their product.
  public static func * (lhs: Size, rhs: UInt64) -> Size {
    var lhs = lhs
    lhs *= Size(rhs)
    return lhs
  }

  /// Multiplies a raw unitless value by a size value and produces their product.
  public static func * (lhs: UInt64, rhs: Size) -> Size {
    var lhs = Size(lhs)
    lhs *= rhs
    return lhs
  }

  /// Multiplies a size value by a raw unitless value and stores the result in
  /// the left-hand-side size variable.
  public static func *= (lhs: inout Size, rhs: UInt64) {
    lhs = Size(lhs.rawValue * rhs)
  }
}

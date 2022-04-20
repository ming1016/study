//
//  Arbitrary.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A value implementing arbitrary precision integer arithmetic.
///
/// `APInt` is a functional replacement for common case unsigned integer type
/// like `UInt` or `UInt64`, but also allows non-byte-width
/// integer sizes and large integer value types such as 3-bits, 15-bits, or more
/// than 64-bits of precision. `APInt` provides a variety of arithmetic
/// operators and methods to manipulate integer values of any bit-width. It
/// supports both the typical integer arithmetic and comparison operations as
/// well as bitwise manipulation.
public struct APInt: IRConstant {
  /// The underlying word size.
  public typealias Word = UInt64

  private enum Impl {
    case single(Word)
    case many([Word])
  }

  private var value: Impl

  /// The bitwidth of this integer.
  public private(set) var bitWidth: Int

  fileprivate init(raw values: [Word], _ bits: Int) {
    self.value = .many(values)
    self.bitWidth = bits
  }

  private mutating func clearUnusedBits() {
    // Compute how many bits are used in the final word
    let wordBits = ((bitWidth - 1) % bitsPerWord) + 1

    // Mask out the high bits.
    let mask = Word.max >> (bitsPerWord - wordBits)
    switch self.value {
    case let .single(val):
      self.value = .single(val & mask)
    case var .many(vals):
      vals[vals.endIndex - 1] &= mask
      self.value = .many(vals)
    }
  }

  public func asLLVM() -> LLVMValueRef {
    let type = IntType(width: self.bitWidth, in: .global)
    switch self.value {
    case let .single(val):
      return type.constant(val).asLLVM()
    case let .many(vals):
      let cnt = vals.count
      return vals.withUnsafeBufferPointer { (words) -> LLVMValueRef in
        LLVMConstIntOfArbitraryPrecision(type.asLLVM(), UInt32(cnt), words.baseAddress)
      }
    }
  }
}

// Mark: Value Constructors

extension APInt {
  /// Creates and initializes a new `APInt` with a bitwidth of one and a value
  /// of zero.
  public init() {
    self.bitWidth = 1
    self.value = .single(0)
  }

  /// Creates and initializes a new `APInt` with a given bit width, value, and
  /// signedness.
  ///
  /// - Parameters:
  ///   - numBits: The bit width of the integer.
  ///   - value: The value of the integer.
  ///   - signed: If `true`, treat the most significant bit at the given bit
  ///             width as a sign bit.  Defaults to `false`.
  public init(width numBits: Int, value: UInt64, signed: Bool = false) {
    precondition(numBits > 0)
    self.bitWidth = numBits
    if numBits <= bitsPerWord {
      self.value = .single(value)
    } else {
      let numWords = requiredWords(for: numBits)
      var values = [Word](repeating: 0, count: numWords)
      values[0] = value
      if signed && Int64(bitPattern: value) < 0 {
        for i in 1..<numWords {
          values[i] = Word.max
        }
      }
      self.value = .many(values)
    }
    self.clearUnusedBits()
  }

  /// Creates and initializes a new `APInt` with a given bit width and an
  /// array of word values.
  ///
  /// - Parameters:
  ///   - numBits: The bit width of the integer.
  ///   - values: An array of words to form the value of the integer.
  public init(width numBits: Int, values: [Word]) {
    precondition(numBits > 0)
    self.bitWidth = numBits
    if numBits <= bitsPerWord {
      self.value = .single(values[0])
    } else {
      let numWords = requiredWords(for: numBits)
      var dst = [Word](repeating: 0, count: numWords)
      for i in 0..<min(values.count, numWords) {
        dst[i] = values[i]
      }
    }
    self.value = .many(values)
    self.clearUnusedBits()
  }
}

// MARK: Comparisons

extension APInt: Comparable {
  public static func == (lhs: APInt, rhs: APInt) -> Bool {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      return vall == valr
    case let (.many(vall), .many(valr)):
      return vall == valr
    default:
      fatalError("Representation mismatch")
    }
  }

  public static func < (lhs: APInt, rhs: APInt) -> Bool {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      return vall < valr
    case let (.many(vall), .many(valr)):
      for i in (0..<vall.count).reversed() {
        guard vall[i] != valr[i] else {
          continue
        }
        return vall[i] < valr[i]
      }
      return false
    default:
      fatalError("Representation mismatch")
    }
  }
}

// MARK: Arithmetic Operations

extension APInt: Numeric {
  public typealias Magnitude = APInt
  public typealias IntegerLiteralType = UInt64

  public init(integerLiteral value: UInt64) {
    self.init(width: bitsPerWord, value: value)
  }

  public init?<T>(exactly source: T) where T : BinaryInteger {
    guard let val = UInt64(exactly: source) else {
      return nil
    }
    self.init(integerLiteral: val)
  }

  /// Returns the result of performing a bitwise AND operation on the two
  /// given values.
  public static func & (lhs: APInt, rhs: APInt) -> APInt {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  /// Stores the result of performing a bitwise AND operation on the two given
  /// values in the left-hand-side variable.
  public static func &= (lhs: inout APInt, rhs: APInt) {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      lhs.value = .single(vall & valr)
    case let (.many(vall), .many(valr)):
      var dst = [APInt.Word](vall)
      for i in 0..<vall.count {
        dst[i] &= valr[i]
      }
      lhs.value = .many(dst)
    default:
      fatalError("Representation mismatch")
    }
  }

  /// Returns the result of performing a bitwise OR operation on the two
  /// given values.
  public static func | (lhs: APInt, rhs: APInt) -> APInt {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  /// Stores the result of performing a bitwise OR operation on the two given
  /// values in the left-hand-side variable.
  public static func |= (lhs: inout APInt, rhs: APInt) {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      lhs.value = .single(vall | valr)
    case let (.many(vall), .many(valr)):
      var dst = [APInt.Word](vall)
      for i in 0..<vall.count {
        dst[i] |= valr[i]
      }
      lhs.value = .many(dst)
    default:
      fatalError("Representation mismatch")
    }
  }

  /// Returns the result of performing a bitwise XOR operation on the two
  /// given values.
  public static func ^ (lhs: APInt, rhs: APInt) -> APInt {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  /// Stores the result of performing a bitwise XOR operation on the two given
  /// values in the left-hand-side variable.
  public static func ^= (lhs: inout APInt, rhs: APInt) {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      lhs.value = .single(vall ^ valr)
    case let (.many(vall), .many(valr)):
      var dst = [APInt.Word](vall)
      for i in 0..<vall.count {
        dst[i] ^= valr[i]
      }
      lhs.value = .many(dst)
    default:
      fatalError("Representation mismatch")
    }
  }

  public static func + (lhs: APInt, rhs: APInt) -> APInt {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  public static func += (lhs: inout APInt, rhs: APInt) {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      lhs.value = .single(vall + valr)
      lhs.clearUnusedBits()
    case let (.many(vall), .many(valr)):
      var dst = [APInt.Word](vall)
      var carry: UInt64 = 0
      for i in 0..<vall.count {
        let l = dst[i]
        if carry != 0 {
          dst[i] += valr[i] + 1
          carry = (dst[i] <= l) ? 1 : 0
        } else {
          dst[i] += valr[i]
          carry = (dst[i] < l) ? 1 : 0
        }
      }
      lhs.value = .many(dst)
      lhs.clearUnusedBits()
    default:
      fatalError("Representation mismatch")
    }
  }

  public static func - (lhs: APInt, rhs: APInt) -> APInt {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  public static func -= (lhs: inout APInt, rhs: APInt) {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      lhs.value = .single(vall - valr)
      lhs.clearUnusedBits()
    case let (.many(vall), .many(valr)):
      var dst = [APInt.Word](vall)
      var carry: UInt64 = 0
      for i in 0..<vall.count {
        let l = dst[i]
        if carry != 0 {
          dst[i] -= valr[i] + 1
          carry = (dst[i] >= l) ? 1 : 0
        } else {
          dst[i] -= valr[i]
          carry = (dst[i] > l) ? 1 : 0
        }
      }
      lhs.value = .many(dst)
      lhs.clearUnusedBits()
    default:
      fatalError("Representation mismatch")
    }
  }

  public var magnitude: APInt {
    return self
  }

  public static func * (lhs: APInt, rhs: APInt) -> APInt {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  public static func *= (lhs: inout APInt, rhs: APInt) {
    precondition(lhs.bitWidth == rhs.bitWidth)
    switch (lhs.value, rhs.value) {
    case let (.single(vall), .single(valr)):
      lhs.value = .single(vall * valr)
      lhs.clearUnusedBits()
    case let (.many(vall), .many(valr)):
      let numWords = vall.count
      var dst = [APInt.Word](repeating: 0, count: numWords)

      var carry: APInt.Word = 0
      for i in 0..<numWords {
        let multiplier = valr[i]
        let srcParts = numWords
        let dstParts = numWords - i

        assert(dst[i] <= vall[i] || dst[i] >= vall[i] + UInt64(srcParts))
        assert(dstParts <= srcParts + 1)

        let n = min(dstParts, srcParts)

        for i in 0..<n {
          var low: APInt.Word = 0
          var mid: APInt.Word = 0
          var high: APInt.Word = 0
          let srcPart: APInt.Word = vall[i]

          if multiplier == 0 || srcPart == 0 {
            low = carry
            high = 0
          } else {
            low = lowHalf(srcPart) * lowHalf(multiplier)
            high = highHalf(srcPart) * highHalf(multiplier)

            mid = lowHalf(srcPart) * highHalf(multiplier)
            high += highHalf(mid)
            mid <<= bitsPerWord / 2
            if low + mid < low {
              high += 1
            }
            low += mid

            mid = highHalf(srcPart) * lowHalf(multiplier)
            high += highHalf(mid)
            mid <<= bitsPerWord / 2
            if low + mid < low {
              high += 1
            }
            low += mid

            // Now add carry.
            if low + carry < low {
              high += 1
            }
            low += carry
          }

          // And now dst[i], and store the new low part there.
          if low + dst[i] < low {
            high += 1
          }
          dst[i] += low

          carry = high

          if srcParts < dstParts {
            // Full multiplication, there is no overflow.
            assert(srcParts + 1 == dstParts)
            dst[srcParts] = carry
          }
        }
      }
      // Did we overflow?
      assert(carry == 0)

      lhs.value = .many(dst)
      lhs.clearUnusedBits()
    default:
      fatalError("Representation mismatch")
    }
  }

  /// Returns the result of shifting a value’s binary representation the
  /// specified number of digits to the left.
  public static func << (lhs: APInt, amount: UInt64) -> APInt {
    var lhs = lhs
    lhs <<= amount
    return lhs
  }

  /// Stores the result of shifting a value’s binary representation the
  /// specified number of digits to the left in the left-hand-side variable.
  public static func <<= (lhs: inout APInt, amount: UInt64) {
    precondition(amount <= lhs.bitWidth)
    switch lhs.value {
    case let .single(val):
      if amount == lhs.bitWidth {
        lhs.value = .single(0)
      } else {
        lhs.value = .single(val << amount)
      }
    case let .many(vall):
      guard amount > 0 else {
        return
      }

      var dst = [APInt.Word](vall)
      let numWords = vall.count

      let (interPartShift, bitShift) = Int(amount).quotientAndRemainder(dividingBy: bitsPerWord)
      let wordShift = min(interPartShift, numWords)

      // Fastpath for moving by whole words.
      if bitShift == 0 {
        for (src, dest) in (wordShift..<(numWords-wordShift)).enumerated() {
          dst[src] = dst[dest]
        }
      } else {
        for i in (wordShift..<numWords).reversed() {
          dst[i] = dst[i - wordShift] << amount
          if i > wordShift {
            dst[i] = dst[i - wordShift - 1] >> (bitsPerWord - bitShift)
          }
        }
      }

      // Fill in the remainder with 0s.
      for i in 0..<wordShift {
        dst[i] = 0
      }
      lhs.value = .many(dst)
      lhs.clearUnusedBits()
    }
  }


  /// Logically shift the value right by the given amount.
  ///
  /// - Parameter amount: The amount to shift right by.
  /// - Returns: An integer of the same bit width that has been logically
  ///            right shifted.
  public func logicallyShiftedRight(by amount: UInt64) -> APInt {
    var lhs = self
    lhs.logicallyShiftRight(by: amount)
    return lhs
  }

  /// Logically shift the value right by the given amount.
  ///
  /// - Parameter amount: The amount to shift right by.
  public mutating func logicallyShiftRight(by amount: UInt64) {
    assert(amount <= self.bitWidth)
    switch self.value {
    case let .single(val):
      if amount == self.bitWidth {
        self.value = .single(0)
      } else {
        self.value = .single(val >> amount)
      }
    case let .many(vals):
      guard amount > 0 else {
        return
      }

      var dst = [APInt.Word](vals)

      let (interPartShift, bitShift) = Int(amount).quotientAndRemainder(dividingBy: bitsPerWord)
      let wordShift = min(interPartShift, vals.count)


      let wordsToMove = dst.count - wordShift
      // Fastpath for moving by whole words.
      if bitShift == 0 {
        for (src, dest) in (wordShift..<wordsToMove).enumerated() {
          dst[src] = dst[dest]
        }
      } else {
        for i in 0..<wordsToMove {
          dst[i] = dst[i + wordShift] >> bitShift
          if i + 1 != wordsToMove {
            dst[i] |= dst[i + wordShift + 1] << (bitsPerWord - bitShift)
          }
        }
      }

      // Fill in the remainder with 0s.
      for i in wordsToMove..<dst.count {
        dst[i] = 0
      }
      self.value = .many(dst)
    }
  }
}

extension APInt {
  /// Attempts to return the value of this integer as a 64-bit unsigned integer
  /// that has been zero-extended.  If the value cannot be represented
  /// faithfully in 64 bits, the result is `nil`.
  public var zeroExtendedValue: UInt64? {
    switch self.value {
    case let .single(val):
      return val
    case let .many(vals):
      guard (self.bitWidth - self.leadingZeroBitCount) <= 64 else {
        return nil
      }
      return vals[0]
    }
  }

  /// Attempts to return the value of this integer as a 64-bit signed integer
  /// that has been sign-extended.  If the value cannot be rerprresented
  /// faithfully in 64 bits, the result is `nil`.
  public var signExtendedValue: Int64? {
    switch self.value {
    case let .single(val):
      return Int64(bitPattern: val << (64 - self.bitWidth)) >> (64 - self.bitWidth)
    case let .many(vals):
      guard (self.bitWidth - self.leadingZeroBitCount) <= 64 else {
        return nil
      }
      return Int64(bitPattern: vals[0])
    }
  }
}

/// MARK: Bit-Level Information

extension APInt {
  /// Returns `true` if the most significant bit of this value is set.
  ///
  /// Note: This may return `true` even if you did not explicitly construct
  ///       a signed `APInt`.
  public var isNegative: Bool {
    switch self.value {
    case let .single(val):
      let msb = UInt64(1) << (bitsPerWord - (64 - self.bitWidth + 1))
      return (val & msb) == 1
    case let .many(vals):
      let msb = UInt64(1) << (bitsPerWord - (64 - self.bitWidth + 1))
      return (vals[vals.endIndex - 1] & msb) == 1
    }
  }

  /// Returns `true` if all bits are ones.
  public var areAllBitsSet: Bool {
    switch self.value {
    case let .single(val):
      return val == (Word.max >> (bitsPerWord - bitWidth))
    case let .many(vals):
      var oneCount = 0
      var i = 0
      let numWords = requiredWords(for: self.bitWidth)
      while i < numWords && vals[i] == Word.max {
        defer { i += 1 }
        oneCount += bitsPerWord
      }
      if i < numWords {
        // Add the trailing 1 bit count
        oneCount += (~vals[i]).leadingZeroBitCount
      }
      assert(oneCount <= self.bitWidth)
      return oneCount == self.bitWidth
    }
  }

  /// The number of leading zeros in this value’s binary representation.
  public var leadingZeroBitCount: Int {
    switch self.value {
    case let .single(val):
      let unusedBits = bitsPerWord - self.bitWidth
      return val.leadingZeroBitCount - unusedBits
    case let .many(vals):
      var count = 0
      for v in vals.reversed() {
        guard v == 0 else {
          count += v.leadingZeroBitCount
          break
        }
        count += bitsPerWord
      }
      // Adjust for unused bits in the most significant word (they are zero).
      let mod = self.bitWidth % bitsPerWord
      count -= mod > 0 ? bitsPerWord - mod : 0
      return count
    }
  }


  /// The number of leading ones in this value’s binary representation.
  public var leadingNonZeroBitCount: Int {
    switch self.value {
    case let .single(val):
      return (~(val << (bitsPerWord - self.bitWidth))).leadingZeroBitCount
    case let .many(vals):
      var highWordBits = self.bitWidth % bitsPerWord
      var shift: Int
      if highWordBits == 0 {
        highWordBits = bitsPerWord
        shift = 0
      } else {
        shift = bitsPerWord - highWordBits
      }
      let tail = requiredWords(for: self.bitWidth) - 1
      var count = (~(vals[tail] << shift)).leadingZeroBitCount
      if count == highWordBits {
        for j in (0..<tail).reversed() {
          if vals[j] == .max {
            count += bitsPerWord
          } else {
            count += (~vals[j]).leadingZeroBitCount
            break
          }
        }
      }
      return count
    }
  }

  /// The number of trailing zeros in this value’s binary representation.
  public var trailingZeroBitCount: Int {
    switch self.value {
    case let .single(val):
      return min(val.trailingZeroBitCount, self.bitWidth)
    case let.many(vals):
      var count = 0
      var i = 0
      while i < vals.count && vals[i] == 0 {
        defer { i += 1 }
        count += bitsPerWord
      }
      if i < vals.count {
        count += vals[i].trailingZeroBitCount
      }
      return min(count, self.bitWidth)
    }
  }

  /// The number of trailing ones in this value’s binary representation.
  public var trailingNonZeroBitCount: Int {
    switch self.value {
    case let .single(val):
      return (~val).trailingZeroBitCount
    case let .many(vals):
      var count = 0
      var i = 0
      while i < vals.count && vals[i] == .max {
        defer { i += 1 }
        count += bitsPerWord
      }
      if i < vals.count {
        count += (~vals[i]).trailingZeroBitCount
      }
      return count
    }
  }

  /// The number of bits equal to 1 in this value’s binary representation.
  public var nonzeroBitCount: Int {
    switch self.value {
    case let .single(val):
      return val.nonzeroBitCount
    case let .many(vals):
      var count = 0
      for val in vals {
        count += val.nonzeroBitCount
      }
      return count
    }
  }
}

// MARK: Bit Twiddling Operations

extension APInt {
  /// Sets all bits to one in this value's binary representation.
  public mutating func setAllBits() {
    switch self.value {
    case .single(_):
      self.value = .single(.max)
    case .many(_):
      self.value = .many([APInt.Word](repeating: .max, count: requiredWords(for: self.bitWidth)))
    }
    self.clearUnusedBits()
  }

  /// Sets the bit at the given position to one.
  ///
  /// - Parameters:
  ///   - position: The position of the bit to set.
  public mutating func setBit(at position: Int) {
    precondition(0 <= position)
    precondition(position < self.bitWidth)
    let mask: Word = (1 as Word) << UInt64(position % bitsPerWord)
    switch self.value {
    case let .single(val):
      self.value = .single(val | mask)
    case var .many(vals):
      vals[position % bitsPerWord] |= mask
      self.value = .many(vals)
    }
  }

  /// Sets the sign bit to one in this value's binary representation.
  public mutating func setSignBit() {
    self.setBit(at: self.bitWidth - 1)
  }

  /// Sets all bits in the given range to one in this value's binary
  /// representation.
  ///
  /// - Parameters:
  ///   - range: The range of bits to flip.
  public mutating func setBits(_ range: ClosedRange<Int>) {
    precondition(range.upperBound <= self.bitWidth)
    precondition(range.lowerBound <= self.bitWidth)
    precondition(range.lowerBound <= range.upperBound)
    guard range.lowerBound != range.upperBound else {
      return
    }

    var mask: Word = Word.max >> (bitsPerWord - (range.upperBound - range.lowerBound))
    mask <<= range.lowerBound
    switch self.value {
    case let .single(val):
      self.value = .single(val | mask)
    case var .many(vals) where range.lowerBound < bitsPerWord && range.upperBound <= bitsPerWord:
      vals[0] |= mask
      self.value = .many(vals)
    case var .many(vals):
      let (loWord, loShift) = range.lowerBound.quotientAndRemainder(dividingBy: bitsPerWord)
      let (hiWord, hiShift) = range.upperBound.quotientAndRemainder(dividingBy: bitsPerWord)

      // If hiBit is not aligned, we need a high mask.
      var loMask = Word.max << loShift
      if hiShift != 0 {
        let hiMask = Word.max >> (bitsPerWord - hiShift)
        if hiWord == loWord {
          loMask &= hiMask
        } else {
          vals[hiWord] |= hiMask
        }
      }
      vals[loWord] |= loMask

      // Fill any words between loWord and hiWord with all ones.
      if loWord < hiWord {
        for word in (loWord + 1)..<hiWord {
          vals[word] = .max
        }
      }

      self.value = .many(vals)
    }
  }

  /// Sets all bits in the given range to one in this value's binary
  /// representation.
  ///
  /// - Parameters:
  ///   - range: The range of bits to flip.
  public mutating func setBits(_ range: Range<Int>) {
    self.setBits(range.lowerBound...range.upperBound - 1)
  }

  /// Sets all bits in the given range to one in this value's binary
  /// representation.
  ///
  /// - Parameters:
  ///   - range: The range of bits to flip.
  public mutating func setBits(_ range: PartialRangeUpTo<Int>) {
    self.setBits(0...range.upperBound - 1)
  }

  /// Sets all bits in the given range to one in this value's binary
  /// representation.
  ///
  /// - Parameters:
  ///   - range: The range of bits to flip.
  public mutating func setBits(_ range: PartialRangeThrough<Int>) {
    self.setBits(0...range.upperBound)
  }

  /// Sets all bits in the given range to one in this value's binary
  /// representation.
  ///
  /// - Parameters:
  ///   - range: The range of bits to flip.
  public mutating func setBits(_ range: PartialRangeFrom<Int>) {
    self.setBits(range.lowerBound...self.bitWidth)
  }

  /// Clears all bits to one in this value's binary representation.
  public mutating func clearAllBits() {
    switch self.value {
    case .single(_):
      self.value = .single(0)
    case .many(_):
      self.value = .many([Word](repeating: 0, count: requiredWords(for: self.bitWidth)))
    }
  }

  /// Sets the bit at the given position to zero.
  ///
  /// - Parameters:
  ///   - position: The position of the bit to zero.
  public mutating func clearBit(_ position: Int) {
    precondition(0 <= position)
    precondition(position < self.bitWidth)
    let mask: Word = ~((1 as Word) << UInt64(position % bitsPerWord))
    switch self.value {
    case let .single(val):
      self.value = .single(val | mask)
    case var .many(vals):
      vals[position % bitsPerWord] |= mask
      self.value = .many(vals)
    }
  }

  /// Clears the sign bit in this value's binary representation.
  public mutating func clearSignBit() {
    self.clearBit(self.bitWidth - 1)
  }
}

/// MARK: Resizing Operations

extension APInt {
  /// Truncates the integer to a given bit width.
  ///
  /// - Parameter width: The new width to truncate towards.  This width cannot
  ///                    exceed the current width of the integer.
  /// - Returns: An integer of the given bit width that has been truncated.
  public func truncate(to width: Int) -> APInt {
    precondition(width < self.bitWidth)
    precondition(width > 0)

    if width <= bitsPerWord {
      switch self.value {
      case let .single(val):
        return APInt(width: width, value: val)
      case let .many(vals):
        return APInt(width: width, values: vals)
      }
    }

    switch self.value {
    case let .single(val):
      return APInt(width: width, value: val)
    case let .many(vals):
      let numWords = requiredWords(for: self.bitWidth)
      var dst = [APInt.Word](repeating: 0, count: numWords)

      // Copy full words.
      for i in 0..<(width / bitsPerWord) {
        dst[i] = vals[i]
      }

      // Truncate and copy any partial word.
      let bits = (0 - width) % bitsPerWord
      if bits != 0 {
        let partWidth = width / bitsPerWord
        dst[partWidth - 1] = (vals[partWidth - 1] << bits) >> bits
      }
      return APInt(raw: dst, width)
    }
  }

  /// Zero extends the integer to a given bit width.
  ///
  /// - Parameter width: The width to zero-extend the integer to.  This value
  ///                    may not be smaller than the current width of the
  ///                    integer.
  /// - Returns: An integer of the given bit width that has been zero-extended.
  public func zeroExtend(to width: Int) -> APInt {
    precondition(width > self.bitWidth)

    switch self.value {
    case let .single(val) where width <= bitsPerWord:
      return APInt(width: width, value: val)
    case let .single(val):
      var dst = [APInt.Word](repeating: 0, count: requiredWords(for: width))
      dst[0] = val
      return APInt(raw: dst, width)
    case let .many(vals):
      var dst = [APInt.Word](repeating: 0, count: requiredWords(for: width))
      for i in 0..<vals.count {
        dst[i] = vals[i]
      }
      return APInt(raw: dst, width)
    }
  }


  /// Sign extends the integer to a given bit width.
  ///
  /// - Parameter width: The width to sign-extend the integer to.  This value
  ///                    may not be smaller than the current width of the
  ///                    integer.
  /// - Returns: An integer of the given bit width that has been zero-extended.
  public func signExtend(to width: Int) -> APInt {
    precondition(width > self.bitWidth)

    switch self.value {
    case let .single(val) where width <= bitsPerWord:
      let ext = Int64(truncatingIfNeeded: (val << (64 - self.bitWidth))) >> (64 - self.bitWidth)
      return APInt(width: width, value: UInt64(bitPattern: ext))
    case let .single(val):
      var dst = [APInt.Word](repeating: 0, count: requiredWords(for: width))
      let b = ((self.bitWidth - 1) % bitsPerWord) + 1
      let ext = Int64(truncatingIfNeeded: (val << (64 - b))) >> (64 - b)
      dst[0] = UInt64(bitPattern: ext)

      for i in 0..<dst.count {
        dst[i] = self.isNegative ? UInt64(bitPattern: -1) : 0
      }
      var int = APInt(raw: dst, width)
      int.clearUnusedBits()
      return int
    case let .many(vals):
      var dst = [APInt.Word](repeating: 0, count: requiredWords(for: width))
      for i in 0..<vals.count {
        dst[i] = vals[i]
      }
      let x = dst[vals.count - 1]
      let b = ((self.bitWidth - 1) % bitsPerWord) + 1
      let ext = Int64(truncatingIfNeeded: (x << (64 - b))) >> (64 - b)
      dst[vals.count - 1] = UInt64(bitPattern: ext)

      for i in vals.count..<(dst.count - vals.count) {
        dst[i] = self.isNegative ? UInt64(bitPattern: -1) : 0
      }
      var int = APInt(raw: dst, width)
      int.clearUnusedBits()
      return int
    }
  }

  /// Zero extends or truncates the integer to the given width.
  ///
  /// If the given bit width exceeds the current bit width, the value is
  /// zero-extended.  Else if the given bit width is less than the current
  /// bit width, the value is truncated.
  ///
  /// If the given bit width matches the current bit width, this operation is
  /// a no-op.
  ///
  /// - Parameter width: The width to zero extend or truncate to.
  /// - Returns: An integer that has been zero extended or truncated to fit
  ///            the given bit width.
  public func zeroExtendOrTruncate(to width: Int) -> APInt {
    if self.bitWidth < width {
      return self.zeroExtend(to: width)
    }
    if self.bitWidth > width {
      return self.truncate(to: width)
    }
    return self
  }

  /// Sign extends or truncates the integer to the given width.
  ///
  /// If the given bit width exceeds the current bit width, the value is
  /// sign-extended.  Else if the given bit width is less than the current
  /// bit width, the value is truncated.
  ///
  /// If the given bit width matches the current bit width, this operation is
  /// a no-op.
  ///
  /// - Parameter width: The width to sign extend or truncate to.
  /// - Returns: An integer that has been sign extended or truncated to fit
  ///            the given bit width.
  public func signExtendOrTruncate(to width: Int) -> APInt {
    if self.bitWidth < width {
      return self.signExtend(to: width)
    }
    if self.bitWidth > width {
      return self.truncate(to: width)
    }
    return self
  }

  /// Toggle every bit in this integer to its opposite value.
  public mutating func flipAll() {
    switch self.value {
    case let .single(val):
      self.value = .single(val ^ Word.max)
      self.clearUnusedBits()
    case let .many(vals):
      var dst = [APInt.Word](vals)
      for i in 0..<dst.count {
        dst[i] = ~dst[i]
      }
      self.value = .many(dst)
      self.clearUnusedBits()
    }
  }

  /// Computes the complement integer value.
  ///
  /// - Parameter val: The integer value.
  /// - Returns: An integer with the value of the bitwise complement.
  public static prefix func ~ (val: APInt) -> APInt {
    var cpy = val
    cpy.flipAll()
    return cpy
  }
}

private let wordSize = MemoryLayout<UInt64>.size
private let bitsPerWord = MemoryLayout<UInt64>.size * CChar.bitWidth

private func lowHalf(_ part: APInt.Word) -> APInt.Word {
  return part & APInt.Word.max >> (bitsPerWord - (bitsPerWord / 2))
}

private func highHalf(_ part: APInt.Word) -> APInt.Word {
  return part >> (bitsPerWord / 2)
}

private func requiredWords(for bitWidth: Int) -> Int {
  return (bitWidth + bitsPerWord - 1) / bitsPerWord
}

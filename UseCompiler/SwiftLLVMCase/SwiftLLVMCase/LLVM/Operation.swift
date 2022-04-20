//
//  Operation.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// Species the behavior that should occur on overflow during mathematical
/// operations.
public enum OverflowBehavior {
  /// The result value of the operator is the mathematical result modulo `2^n`,
  /// where `n` is the bit width of the result.
  case `default`
  /// The result value of the operator is a poison value if signed overflow
  /// occurs.
  case noSignedWrap
  /// The result value of the operator is a poison value if unsigned overflow
  /// occurs.
  case noUnsignedWrap
}

/// The condition codes available for integer comparison instructions.
public enum IntPredicate {
  /// Yields `true` if the operands are equal, false otherwise without sign
  /// interpretation.
  case equal
  /// Yields `true` if the operands are unequal, false otherwise without sign
  /// interpretation.
  case notEqual

  /// Interprets the operands as unsigned values and yields true if the first is
  /// greater than the second.
  case unsignedGreaterThan
  /// Interprets the operands as unsigned values and yields true if the first is
  /// greater than or equal to the second.
  case unsignedGreaterThanOrEqual
  /// Interprets the operands as unsigned values and yields true if the first is
  /// less than the second.
  case unsignedLessThan
  /// Interprets the operands as unsigned values and yields true if the first is
  /// less than or equal to the second.
  case unsignedLessThanOrEqual

  /// Interprets the operands as signed values and yields true if the first is
  /// greater than the second.
  case signedGreaterThan
  /// Interprets the operands as signed values and yields true if the first is
  /// greater than or equal to the second.
  case signedGreaterThanOrEqual
  /// Interprets the operands as signed values and yields true if the first is
  /// less than the second.
  case signedLessThan
  /// Interprets the operands as signed values and yields true if the first is
  /// less than or equal to the second.
  case signedLessThanOrEqual

  private static let predicateMapping: [IntPredicate: LLVMIntPredicate] = [
    .equal: LLVMIntEQ, .notEqual: LLVMIntNE, .unsignedGreaterThan: LLVMIntUGT,
    .unsignedGreaterThanOrEqual: LLVMIntUGE, .unsignedLessThan: LLVMIntULT,
    .unsignedLessThanOrEqual: LLVMIntULE, .signedGreaterThan: LLVMIntSGT,
    .signedGreaterThanOrEqual: LLVMIntSGE, .signedLessThan: LLVMIntSLT,
    .signedLessThanOrEqual: LLVMIntSLE,
  ]

  /// Retrieves the corresponding `LLVMIntPredicate`.
  var llvm: LLVMIntPredicate {
    return IntPredicate.predicateMapping[self]!
  }
}

/// The condition codes available for floating comparison instructions.
public enum RealPredicate {
  /// No comparison, always returns `false`.
  case `false`
  /// Ordered and equal.
  case orderedEqual
  /// Ordered greater than.
  case orderedGreaterThan
  /// Ordered greater than or equal.
  case orderedGreaterThanOrEqual
  /// Ordered less than.
  case orderedLessThan
  /// Ordered less than or equal.
  case orderedLessThanOrEqual
  /// Ordered and not equal.
  case orderedNotEqual
  /// Ordered (no nans).
  case ordered
  /// Unordered (either nans).
  case unordered
  /// Unordered or equal.
  case unorderedEqual
  /// Unordered or greater than.
  case unorderedGreaterThan
  /// Unordered or greater than or equal.
  case unorderedGreaterThanOrEqual
  /// Unordered or less than.
  case unorderedLessThan
  /// Unordered or less than or equal.
  case unorderedLessThanOrEqual
  /// Unordered or not equal.
  case unorderedNotEqual
  /// No comparison, always returns `true`.
  case `true`

  private static let predicateMapping: [RealPredicate: LLVMRealPredicate] = [
    .false: LLVMRealPredicateFalse, .orderedEqual: LLVMRealOEQ,
    .orderedGreaterThan: LLVMRealOGT, .orderedGreaterThanOrEqual: LLVMRealOGE,
    .orderedLessThan: LLVMRealOLT, .orderedLessThanOrEqual: LLVMRealOLE,
    .orderedNotEqual: LLVMRealONE, .ordered: LLVMRealORD, .unordered: LLVMRealUNO,
    .unorderedEqual: LLVMRealUEQ, .unorderedGreaterThan: LLVMRealUGT,
    .unorderedGreaterThanOrEqual: LLVMRealUGE, .unorderedLessThan: LLVMRealULT,
    .unorderedLessThanOrEqual: LLVMRealULE, .unorderedNotEqual: LLVMRealUNE,
    .true: LLVMRealPredicateTrue,
  ]

  /// Retrieves the corresponding `LLVMRealPredicate`.
  var llvm: LLVMRealPredicate {
    return RealPredicate.predicateMapping[self]!
  }
}

/// `AtomicOrdering` enumerates available memory ordering semantics.
///
/// Atomic instructions (`cmpxchg`, `atomicrmw`, `fence`, `atomic load`, and
/// `atomic store`) take ordering parameters that determine which other atomic
/// instructions on the same address they synchronize with. These semantics are
/// borrowed from Java and C++0x, but are somewhat more colloquial. If these
/// descriptions aren’t precise enough, check those specs (see spec references
/// in the atomics guide). fence instructions treat these orderings somewhat
/// differently since they don’t take an address. See that instruction’s
/// documentation for details.
public enum AtomicOrdering: Comparable {
  /// A load or store which is not atomic
  case notAtomic
  /// Lowest level of atomicity, guarantees somewhat sane results, lock free.
  ///
  /// The set of values that can be read is governed by the happens-before
  /// partial order. A value cannot be read unless some operation wrote it. This
  /// is intended to provide a guarantee strong enough to model Java’s
  /// non-volatile shared variables. This ordering cannot be specified for
  /// read-modify-write operations; it is not strong enough to make them atomic
  /// in any interesting way.
  case unordered
  /// Guarantees that if you take all the operations affecting a specific
  /// address, a consistent ordering exists.
  ///
  /// In addition to the guarantees of unordered, there is a single total order
  /// for modifications by monotonic operations on each address. All
  /// modification orders must be compatible with the happens-before order.
  /// There is no guarantee that the modification orders can be combined to a
  /// global total order for the whole program (and this often will not be
  /// possible). The read in an atomic read-modify-write operation (cmpxchg and
  /// atomicrmw) reads the value in the modification order immediately before
  /// the value it writes. If one atomic read happens before another atomic read
  /// of the same address, the later read must see the same value or a later
  /// value in the address’s modification order. This disallows reordering of
  /// monotonic (or stronger) operations on the same address. If an address is
  /// written monotonic-ally by one thread, and other threads monotonic-ally
  /// read that address repeatedly, the other threads must eventually see the
  /// write. This corresponds to the C++0x/C1x memory_order_relaxed.
  case monotonic
  /// Acquire provides a barrier of the sort necessary to acquire a lock to
  /// access other memory with normal loads and stores.
  ///
  /// In addition to the guarantees of monotonic, a synchronizes-with edge may
  /// be formed with a release operation. This is intended to model C++’s
  /// `memory_order_acquire`.
  case acquire
  /// Release is similar to Acquire, but with a barrier of the sort necessary to
  /// release a lock.
  ///
  /// In addition to the guarantees of monotonic, if this operation writes a
  /// value which is subsequently read by an acquire operation, it
  /// synchronizes-with that operation. (This isn’t a complete description; see
  /// the C++0x definition of a release sequence.) This corresponds to the
  /// C++0x/C1x memory_order_release.
  case release
  /// provides both an Acquire and a Release barrier (for fences and operations
  /// which both read and write memory).
  ///
  /// This corresponds to the C++0x/C1x memory_order_acq_rel.
  case acquireRelease
  /// Provides Acquire semantics for loads and Release semantics for stores.
  ///
  /// In addition to the guarantees of acq_rel (acquire for an operation that
  /// only reads, release for an operation that only writes), there is a global
  /// total order on all sequentially-consistent operations on all addresses,
  /// which is consistent with the happens-before partial order and with the
  /// modification orders of all the affected addresses. Each
  /// sequentially-consistent read sees the last preceding write to the same
  /// address in this global order. This corresponds to the C++0x/C1x
  /// `memory_order_seq_cst` and Java volatile.
  case sequentiallyConsistent

  private static let orderingMapping: [AtomicOrdering: LLVMAtomicOrdering] = [
    .notAtomic: LLVMAtomicOrderingNotAtomic,
    .unordered: LLVMAtomicOrderingUnordered,
    .monotonic: LLVMAtomicOrderingMonotonic,
    .acquire: LLVMAtomicOrderingAcquire,
    .release: LLVMAtomicOrderingRelease,
    .acquireRelease: LLVMAtomicOrderingAcquireRelease,
    .sequentiallyConsistent: LLVMAtomicOrderingSequentiallyConsistent,
  ]

  /// Returns whether the left atomic ordering is strictly weaker than the
  /// right atomic order.
  public static func <(lhs: AtomicOrdering, rhs: AtomicOrdering) -> Bool {
    return lhs.llvm.rawValue < rhs.llvm.rawValue
  }

  /// Retrieves the corresponding `LLVMAtomicOrdering`.
  var llvm: LLVMAtomicOrdering {
    return AtomicOrdering.orderingMapping[self]!
  }
}

/// `AtomicReadModifyWriteOperation` enumerates the kinds of supported atomic
/// read-write-modify operations.
public enum AtomicReadModifyWriteOperation {
  /// Set the new value and return the one old
  ///
  /// ```
  /// *ptr = val
  /// ```
  case xchg
  /// Add a value and return the old one
  ///
  /// ```
  /// *ptr = *ptr + val
  /// ```
  case add
  /// Subtract a value and return the old one
  ///
  /// ```
  /// *ptr = *ptr - val
  /// ```
  case sub
  /// And a value and return the old one
  ///
  /// ```
  /// *ptr = *ptr & val
  /// ```
  case and
  /// Not-And a value and return the old one
  ///
  /// ```
  /// *ptr = ~(*ptr & val)
  /// ```
  case nand
  /// OR a value and return the old one
  ///
  /// ```
  /// *ptr = *ptr | val
  /// ```
  case or
  /// Xor a value and return the old one
  ///
  /// ```
  /// *ptr = *ptr ^ val
  /// ```
  case xor
  /// Sets the value if it's greater than the original using a signed comparison
  /// and return the old one.
  ///
  /// ```
  /// // Using a signed comparison
  /// *ptr = *ptr > val ? *ptr : val
  /// ```
  case max
  /// Sets the value if it's Smaller than the original using a signed comparison
  /// and return the old one.
  ///
  /// ```
  /// // Using a signed comparison
  /// *ptr = *ptr < val ? *ptr : val
  /// ```
  case min
  /// Sets the value if it's greater than the original using an unsigned
  /// comparison and return the old one.
  ///
  /// ```
  /// // Using an unsigned comparison
  /// *ptr = *ptr > val ? *ptr : val
  /// ```
  case umax
  /// Sets the value if it's greater than the original using an unsigned
  /// comparison and return the old one.
  ///
  /// ```
  /// // Using an unsigned comparison
  /// *ptr = *ptr < val ? *ptr : val
  /// ```
  case umin

  private static let atomicRMWMapping: [AtomicReadModifyWriteOperation: LLVMAtomicRMWBinOp] = [
    .xchg: LLVMAtomicRMWBinOpXchg, .add: LLVMAtomicRMWBinOpAdd,
    .sub: LLVMAtomicRMWBinOpSub, .and: LLVMAtomicRMWBinOpAnd,
    .nand: LLVMAtomicRMWBinOpNand, .or: LLVMAtomicRMWBinOpOr,
    .xor: LLVMAtomicRMWBinOpXor, .max: LLVMAtomicRMWBinOpMax,
    .min: LLVMAtomicRMWBinOpMin, .umax: LLVMAtomicRMWBinOpUMax,
    .umin: LLVMAtomicRMWBinOpUMin,
  ]

  /// Retrieves the corresponding `LLVMAtomicRMWBinOp`.
  var llvm: LLVMAtomicRMWBinOp {
    return AtomicReadModifyWriteOperation.atomicRMWMapping[self]!
  }
}

/// Enumerates the dialects of inline assembly LLVM's parsers can handle.
public enum InlineAssemblyDialect {
  /// The dialect of assembly created at Bell Labs by AT&T.
  ///
  /// AT&T syntax differs from Intel syntax in a number of ways.  Notably:
  ///
  /// - The source operand is before the destination operand
  /// - Immediate operands are prefixed by a dollar-sign (`$`)
  /// - Register operands are preceded by a percent-sign (`%`)
  /// - The size of memory operands is determined from the last character of the
  ///   the opcode name.  Valid suffixes include `b` for "byte" (8-bit),
  ///   `w` for "word" (16-bit), `l` for "long-word" (32-bit), and `q` for
  ///   "quad-word" (64-bit) memory references
  case att
  /// The dialect of assembly created at Intel.
  ///
  /// Intel syntax differs from AT&T syntax in a number of ways.  Notably:
  ///
  /// - The destination operand is before the source operand
  /// - Immediate and register operands have no prefix.
  /// - Memory operands are annotated with their sizes. Valid annotations
  ///   include `byte ptr` (8-bit), `word ptr` (16-bit), `dword ptr` (32-bit) and
  ///   `qword ptr` (64-bit).
  case intel

  private static let dialectMapping: [InlineAssemblyDialect: LLVMInlineAsmDialect] = [
    .att: LLVMInlineAsmDialectATT,
    .intel: LLVMInlineAsmDialectIntel,
  ]

  /// Retrieves the corresponding `LLVMInlineAsmDialect`.
  var llvm: LLVMInlineAsmDialect {
    return InlineAssemblyDialect.dialectMapping[self]!
  }
}

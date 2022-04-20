//
//  AddressSpace.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An address space is an identifier for a target-specific range of address values.  An address space is a
/// fundamental part of the type of a pointer value and the type of operations that manipulate memory.
///
/// LLVM affords a default address space (numbered zero) and places a number of assumptions on pointer
/// values within that address space:
/// - The pointer must have a fixed integral value
/// - The null pointer has a bit-value of 0
///
/// These assumptions are not guaranteed to hold in any other address space.  In particular, a target may
/// allow pointers in non-default address spaces to have *non-integral* types.  Non-integral pointer types
/// represent pointers that have an unspecified bitwise representation; that is, the integral representation may
/// be target dependent or have an unstable value.  Further, outside of the default address space, it is not
/// always the case that the `null` pointer value, especially as returned by
/// `IRType.constPointerNull()` has a bit value of 0.  e.g. A non-default address space may use
/// an offset-based or segment-based addressing mode in which 0 is a valid, addressable pointer value.
///
/// Target-Level Address Space Overrides
/// ====================================
///
/// A target may choose to override the default address space for code, data, and local allocations through the
/// data layout string.  This has multiple uses.  For example, the address space of an `alloca` is *only*
/// configurable via the data layout string, because it is a target-dependent property.  There are also
/// use-cases for overriding language standards e.g. the C standard requires the address-of operator applied
/// to values on the stack to result in a pointer in the default address space. However, many OpenCL-based
/// targets consider the stack to be a private region, and place such pointers in a non-default address space.
///
/// Care must be taken when interacting with these non-standard targets.  The IR printer currently does not
/// print anything when the default address space is attached to an instruction or value, and values will still
/// report being assigned to that space.  However, these values are still subject to the backend's interpretation
/// of the data layout string overrides and as such may not always reside in the default address space when
/// it comes time to codegen them.
///
/// Restrictions
/// ============
///
/// There are currently a number of artificial restrictions on values and operations that have non-default
/// address spaces:
/// - A `bitcast` between two pointer values residing in different address spaces, even if those two
///   values have the same size, is always an illegal operation.  Use an `addrspacecast` instead or
///   always use `IRBuilder.buildPointerCast(of:to:name:)` to get the correct operation.
/// - The so-called "null pointer" has a bit value that may differ from address space to address space.  This
///   exposes bugs in optimizer passes and lowerings that did not consider this possibility.
/// - A pointer value may not necessarily "round-trip" when converted between address spaces, even if
///   annotated `nonnull` and `dereferenceable`.  This is especially true of non-integral pointer types.
/// - Though the zero address space is the default, many backends and some errant passes interpret this to
///   mean a "lack of address space" and may miscompile code with pointers in mixed address spaces.
/// - A number of intriniscs that operate on memory currently do not support a non-default address space.
/// - The address space is ultimately an integer value and in theory an address space identifier may take on
///   any value.  In practice, LLVM guarantees only 24 bits of precision, though higher address space
///   identifiers may succeed in being properly represented.
public struct AddressSpace: Equatable {
  let rawValue: Int
  
  /// LLVM's default address space.
  public static let zero = AddressSpace(0)
  
  /// Creates and initializes an address space with the given identifier.
  /// - Parameter identifier: The raw, integral address space identifier.
  public init(_ identifier: Int) {
    self.rawValue = identifier
  }
}


//
//  Intrinsic.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm
import Foundation

/// An `Intrinsic` represents an intrinsic known to LLVM.
///
/// Intrinsic functions have well known names and semantics and are required to
/// follow certain restrictions. Overall, these intrinsics represent an
/// extension mechanism for the LLVM language that does not require changing all
/// of the transformations in LLVM when adding to the language (or the bitcode
/// reader/writer, the parser, etc…).
///
/// Intrinsic function names must all start with an `llvm.` prefix. This prefix
/// is reserved in LLVM for intrinsic names; thus, function names may not begin
/// with this prefix. Intrinsic functions must always be external functions: you
/// cannot define the body of intrinsic functions. Intrinsic functions may only
/// be used in call or invoke instructions: it is illegal to take the address of
/// an intrinsic function.
///
/// Some intrinsic functions can be overloaded, i.e., the intrinsic represents a
/// family of functions that perform the same operation but on different data
/// types. Because LLVM can represent over 8 million different integer types,
/// overloading is used commonly to allow an intrinsic function to operate on
/// any integer type. One or more of the argument types or the result type can
/// be overloaded to accept any integer type. Argument types may also be defined
/// as exactly matching a previous argument’s type or the result type. This
/// allows an intrinsic function which accepts multiple arguments, but needs all
/// of them to be of the same type, to only be overloaded with respect to a
/// single argument or the result.
///
/// Overloaded intrinsics will have the names of its overloaded argument types
/// encoded into its function name, each preceded by a period. Only those types
/// which are overloaded result in a name suffix. Arguments whose type is
/// matched against another type do not. For example, the llvm.ctpop function
/// can take an integer of any width and returns an integer of exactly the same
/// integer width. This leads to a family of functions such as
/// `i8 @llvm.ctpop.i8(i8 %val)` and `i29 @llvm.ctpop.i29(i29 %val)`. Only one
/// type, the return type, is overloaded, and only one type suffix is required.
/// Because the argument’s type is matched against the return type, it does not
/// require its own name suffix.
///
/// Dynamic Member Lookup For Intrinsics
/// ====================================
///
/// This library provides a dynamic member lookup facility for retrieving
/// intrinsic selectors.  For any LLVM intrinsic selector of the form
/// `llvm.foo.bar.baz`, the name of the corresponding dynamic member is that
/// name with any dots replaced by underscores.
///
/// For example:
///
///     llvm.foo.bar.baz -> Intrinsic.ID.llvm_foo_bar_baz
///     llvm.stacksave -> Intrinsic.ID.llvm_stacksave
///     llvm.x86.xsave64 -> Intrinsic.ID.llvm_x86_xsave64
///
/// Any existing underscores do not need to be replaced, e.g.
/// `llvm.va_copy` becomes `Intrinsic.ID.llvm_va_copy`.
///
/// For overloaded intrinsics, the non-overloaded prefix excluding the explicit
/// type parameters is used and normalized according to the convention above.
///
/// For example:
///
///     llvm.sinf64 -> Intrinsic.ID.llvm_sin
///     llvm.memcpy.p0i8.p0i8.i32 -> Intrinsic.ID.llvm_memcpy
///     llvm.bswap.v4i32 -> Intrinsic.ID.llvm_bswap
public class Intrinsic: Function {
  /// A wrapper type for an intrinsic selector.
  public struct Selector {
    let index: UInt32
    fileprivate init(_ index: UInt32) { self.index = index }
  }

  /// This type provides a dynamic member lookup facility for LLVM intrinsics.
  ///
  /// It is not possible to create a `DynamicIntrinsicResolver` in user code.
  /// One is provided by `Intrinsic.ID`.
  @dynamicMemberLookup public struct DynamicIntrinsicResolver {
    private let exceptionalSet: Set<String>

    fileprivate init() {
      // LLVM naming conventions for intrinsics is really not consistent at all
      // (see llvm.ssa_copy).  We need to gather a table of all the intrinsics
      // that have underscores in their names so we don't naively replace them
      // with dots later.
      //
      // Luckily, no intrinsics that use underscores in their name also use
      // dots. If this changes in the future, we need to be smarter here.
      var table = Set<String>()
      table.reserveCapacity(16)
      for idx in 1..<LLVMSwiftCountIntrinsics() {
        guard let value = LLVMSwiftGetIntrinsicAtIndex(idx) else { fatalError() }
        guard strchr(value, Int32(UInt8(ascii: "_"))) != nil else {
          continue
        }
        table.insert(String(cString: value))
      }
      self.exceptionalSet = table
    }

    /// Performs a dynamic lookup for the normalized form of an intrinsic
    /// selector.
    ///
    /// For any LLVM intrinsic selector of the form `llvm.foo.bar.baz`, the name
    /// of the corresponding dynamic member is that name with any dots replaced
    /// by underscores.
    ///
    /// For example:
    ///
    ///     llvm.foo.bar.baz -> Intrinsic.ID.llvm_foo_bar_baz
    ///     llvm.stacksave -> Intrinsic.ID.llvm_stacksave
    ///     llvm.x86.xsave64 -> Intrinsic.ID.llvm_x86_xsave64
    ///
    /// Any existing underscores do not need to be replaced, e.g.
    /// `llvm.va_copy` becomes `Intrinsic.ID.llvm_va_copy`.
    ///
    /// For overloaded intrinsics, the non-overloaded prefix excluding the
    /// explicit type parameters is used and normalized according to the
    /// convention above.
    ///
    /// For example:
    ///
    ///     llvm.sinf64 -> Intrinsic.ID.llvm_sin
    ///     llvm.memcpy.p0i8.p0i8.i32 -> Intrinsic.ID.llvm_memcpy
    ///     llvm.bswap.v4i32 -> Intrinsic.ID.llvm_bswap
    ///
    /// - Parameter selector: The LLVMSwift form of an intrinsic selector.
    public subscript(dynamicMember selector: String) -> Selector {
      precondition(selector.starts(with: "llvm_"))

      let prefix = "llvm."
      let suffix = selector.dropFirst("llvm_".count)
      let finalSelector: String
      if self.exceptionalSet.contains(prefix + suffix) {
        // If the exceptions set contains an entry for this selector, then it
        // has an underscore and no dots so we can just concatenate prefix and
        // suffix.
        finalSelector = prefix + suffix
      } else {
        // Else, naively replace all the underscores with dots.
        finalSelector = selector.replacingOccurrences(of: "_", with: ".")
      }

      let index = LLVMLookupIntrinsicID(finalSelector, finalSelector.count)
      assert(index > 0, "Member does not correspond to an LLVM intrinsic")
      return Selector(index)
    }
  }

  /// The default dynamic intrinsic resolver.
  public static let ID = DynamicIntrinsicResolver()

  /// Retrieves the name of this intrinsic if it is not overloaded.
  public var name: String {
    precondition(!self.isOverloaded,
                 "Cannot retrieve the full name of an overloaded intrinsic")
    var count = 0
    guard let ptr = LLVMIntrinsicGetName(self.identifier, &count) else {
      return ""
    }
    return String(cString: ptr)
  }

  /// Retrieves the name of this intrinsic if it is overloaded, resolving it
  /// with the given parameter types.
  public func overloadedName(for parameterTypes: [IRType]) -> String {
    precondition(self.isOverloaded,
                 "Cannot retrieve the overloaded name of a non-overloaded intrinsic")
    var argIRTypes = parameterTypes.map { $0.asLLVM() as Optional }
    return argIRTypes.withUnsafeMutableBufferPointer { buf -> String in
      var count = 0
      guard let ptr = LLVMIntrinsicCopyOverloadedName(self.identifier, buf.baseAddress, parameterTypes.count, &count) else {
        return ""
      }
      defer { free(UnsafeMutableRawPointer(mutating: ptr)) }
      return String(cString: ptr)
    }
  }

  /// Retrieves the type of this intrinsic if it is not overloaded.
  public var type: IRType {
    precondition(!self.isOverloaded,
                 "Cannot retrieve type of overloaded intrinsic")
    return convertType(LLVMTypeOf(asLLVM()))
  }

  /// Resolves the type of an overloaded intrinsic using the given parameter
  /// types.
  ///
  /// - Parameters:
  ///   - context: The context in which to create the type.
  ///   - parameterTypes: The type of the parameters to the intrinsic.
  /// - Returns: The type of the intrinsic function with its overloaded
  ///   parameter types resolved.
  public func overloadedType(in context: Context = .global, with parameterTypes: [IRType]) -> IRType {
    var argIRTypes = parameterTypes.map { $0.asLLVM() as Optional }
    return argIRTypes.withUnsafeMutableBufferPointer { buf -> IRType in
      guard let ty = LLVMIntrinsicGetType(context.llvm, self.identifier, buf.baseAddress, parameterTypes.count) else {
        fatalError("Could not retrieve type of intrinsic")
      }
      return convertType(ty)
    }
  }

  /// Retrieves if this intrinsic is overloaded.
  public var isOverloaded: Bool {
    return LLVMIntrinsicIsOverloaded(self.identifier) != 0
  }

  /// Retrieves the ID number of this intrinsic function.
  public var identifier: UInt32 {
    return LLVMGetIntrinsicID(self.llvm)
  }
}


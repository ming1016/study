//
//  Alias.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm


/// An `Alias` represents a global alias in an LLVM module - a new symbol and
/// corresponding metadata for an existing global value.
///
/// An `Alias`, unlike a function or global variable declaration, does not
/// create any new data in the resulting object file.  It is merely a new name
/// for an existing symbol or constant.  The aliased value (the aliasee) must
/// be either another global value like a function, global variable, or even
/// another alias, or it must be a constant expression.
///
/// Linkers make no guarantees that aliases will be preserved in the final
/// object file.  Aliases where the address is known to be relevant should be
/// marked with the appropriate `UnnamedAddressKind` value.  If this value is
/// not `none`, the alias is guaranteed to have the same address as the aliasee.
/// Else, the alias is guaranteed to point to the same content as the aliasee,
/// but may reside at a different address.
///
/// If the aliasee is a constant value, LLVM places additional restrictions on
/// its content in order to maintain compatibility with the expected behavior of
/// most linkers:
///
/// - The constant expression may not involve aliases with weak linkage.  Such
///   weak aliases cannot be guaranteed to be stable in the final object file.
/// - The constant expression may not involve global values requiring a
///   relocation such as a global function or global variable declared but not
///   defined within its module.
public struct Alias: IRGlobal {
  internal let llvm: LLVMValueRef

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }

  /// The target value of this alias.
  ///
  /// The aliasee is required to be another global value or constant
  public var aliasee: IRValue {
    get { return LLVMAliasGetAliasee(llvm) }
    set { LLVMAliasSetAliasee(llvm, newValue.asLLVM()) }
  }

  /// Retrieves the previous alias in the module, if there is one.
  public func previous() -> Alias? {
    guard let previous = LLVMGetPreviousGlobalAlias(llvm) else { return nil }
    return Alias(llvm: previous)
  }

  /// Retrieves the next alias in the module, if there is one.
  public func next() -> Alias? {
    guard let next = LLVMGetNextGlobalAlias(llvm) else { return nil }
    return Alias(llvm: next)
  }
}


//
//  IRGlobal.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An `IRGlobal` is a value, alias, or function that exists at the top level of
/// an LLVM module.
public protocol IRGlobal: IRConstant {}

extension IRGlobal {
  /// Retrieves the "value type" of this global value.
  ///
  /// The formal type of a global value is always a pointer type.  The value
  /// type, in contrast, is the type of the value the global points to.
  public var valueType: IRType {
    return convertType(LLVMGlobalGetValueType(asLLVM()))
  }

  /// Retrieves the alignment of this value.
  public var alignment: Alignment {
    get { return Alignment(LLVMGetAlignment(asLLVM())) }
    set { LLVMSetAlignment(asLLVM(), newValue.rawValue) }
  }
  
  /// Retrieves the linkage information for this global.
  public var linkage: Linkage {
    get { return Linkage(llvm: LLVMGetLinkage(asLLVM())) }
    set { LLVMSetLinkage(asLLVM(), newValue.llvm) }
  }

  /// Retrieves the visibility style for this global.
  public var visibility: Visibility {
    get { return Visibility(llvm: LLVMGetVisibility(asLLVM())) }
    set { LLVMSetVisibility(asLLVM(), newValue.llvm) }
  }

  /// Retrieves the storage class for this global declaration.  For use with
  /// Portable Executable files.
  public var storageClass: StorageClass {
    get { return StorageClass(llvm: LLVMGetDLLStorageClass(asLLVM())) }
    set { LLVMSetDLLStorageClass(asLLVM(), newValue.llvm) }
  }

  /// Retrieves an indicator for the significance of a global value's address.
  public var unnamedAddressKind: UnnamedAddressKind {
    get { return UnnamedAddressKind(llvm: LLVMGetUnnamedAddress(asLLVM()))  }
    set { LLVMSetUnnamedAddress(asLLVM(), newValue.llvm) }
  }

  /// Retrieves the COMDAT section for this global, if it exists.
  public var comdat: Comdat? {
    get { return LLVMGetComdat(asLLVM()).map(Comdat.init(llvm:))  }
    set { LLVMSetComdat(asLLVM(), newValue?.llvm) }
  }

  /// Retrieves the section associated with the symbol that will eventually be
  /// emitted for this global value.
  ///
  /// - Note: Global `Alias` values may or may not be resolvable to any
  ///   particular section given the state of the IR in an arbitrary module. A
  ///   return value of the empty string indicates a failed section lookup.
  public var section: String {
    get {
      guard let sname = LLVMGetSection(asLLVM()) else { return "" }
      return String(cString: sname)
    }
    set { LLVMSetSection(asLLVM(), newValue) }
  }

  /// Retrieves a global unique identifier for this global value.
  ///
  /// This is a 64 bits hash that is used by PGO and ThinLTO to have a compact
  /// unique way to identify a symbol.
  public var guid: UInt64 {
    return LLVMGlobalGetGUID(self.asLLVM())
  }

  /// Removes this global value from the module and deallocates it.
  ///
  /// - note: To ensure correct removal of the global value, you must invalidate
  ///         any references to it - usually by performing an
  ///         "Replace All Uses With" (RAUW) operation.
  ///
  /// - warning: The native Swift object wrapping this global becomes a dangling
  ///            reference once this function has been invoked.  It is
  ///            recommended that all references to it be dropped immediately.
  public func eraseFromParent() {
    LLVMDeleteGlobal(self.asLLVM())
  }
}

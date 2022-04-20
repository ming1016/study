//
//  Linkage.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// `Visibility` enumerates available visibility styles.
public enum Visibility {
  /// On targets that use the ELF object file format, default visibility means
  /// that the declaration is visible to other modules and, in shared libraries,
  /// means that the declared entity may be overridden. On Darwin, default
  /// visibility means that the declaration is visible to other modules. Default
  /// visibility corresponds to "external linkage" in the language.
  case `default`
  /// Two declarations of an object with hidden visibility refer to the same
  /// object if they are in the same shared object. Usually, hidden visibility
  /// indicates that the symbol will not be placed into the dynamic symbol
  /// table, so no other module (executable or shared library) can reference it
  /// directly.
  case hidden
  /// On ELF, protected visibility indicates that the symbol will be placed in
  /// the dynamic symbol table, but that references within the defining module
  /// will bind to the local symbol. That is, the symbol cannot be overridden by
  /// another module.
  case protected

  static let visibilityMapping: [Visibility: LLVMVisibility] = [
    .default: LLVMDefaultVisibility,
    .hidden: LLVMHiddenVisibility,
    .protected: LLVMProtectedVisibility,
  ]

  internal init(llvm: LLVMVisibility) {
    switch llvm {
    case LLVMDefaultVisibility: self = .default
    case LLVMHiddenVisibility: self = .hidden
    case LLVMProtectedVisibility: self = .protected
    default: fatalError("unknown visibility type \(llvm)")
    }
  }

  /// Retrieves the corresponding `LLVMLinkage`.
  public var llvm: LLVMVisibility {
    return Visibility.visibilityMapping[self]!
  }
}

/// `Linkage` enumerates the supported kinds of linkage for global values.  All
/// global variables and functions have a linkage.
public enum Linkage {
  /// Externally visible function.  This is the default linkage.
  ///
  /// If none of the other linkages are specified, the global is externally
  /// visible, meaning that it participates in linkage and can be used to
  /// resolve external symbol references.
  case external
  /// Available for inspection, not emission.
  ///
  /// Globals with "available_externally" linkage are never emitted into the
  /// object file corresponding to the LLVM module. From the linker’s
  /// perspective, an available_externally global is equivalent to an external
  /// declaration. They exist to allow inlining and other optimizations to take
  /// place given knowledge of the definition of the global, which is known to
  /// be somewhere outside the module. Globals with available_externally linkage
  /// are allowed to be discarded at will, and allow inlining and other
  /// optimizations. This linkage type is only allowed on definitions, not
  /// declarations.
  case availableExternally
  /// Keep one copy of function when linking.
  ///
  /// Globals with "linkonce" linkage are merged with other globals of the same
  /// name when linkage occurs. This can be used to implement some forms of
  /// inline functions, templates, or other code which must be generated in each
  /// translation unit that uses it, but where the body may be overridden with a
  /// more definitive definition later. Unreferenced linkonce globals are
  /// allowed to be discarded. Note that linkonce linkage does not actually
  /// allow the optimizer to inline the body of this function into callers
  /// because it doesn’t know if this definition of the function is the
  /// definitive definition within the program or whether it will be overridden
  /// by a stronger definition.
  case linkOnceAny
  /// Keep one copy of function when linking but enable inlining and
  /// other optimizations.
  ///
  /// Some languages allow differing globals to be merged, such as two functions
  /// with different semantics. Other languages, such as C++, ensure that only
  /// equivalent globals are ever merged (the "one definition rule" — "ODR").
  /// Such languages can use the linkonce_odr and weak_odr linkage types to
  /// indicate that the global will only be merged with equivalent globals.
  /// These linkage types are otherwise the same as their non-odr versions.
  case linkOnceODR
  /// Keep one copy of function when linking (weak).
  ///
  /// "weak" linkage has the same merging semantics as linkonce linkage, except
  /// that unreferenced globals with weak linkage may not be discarded. This is
  /// used for globals that are declared "weak" in C source code.
  case weakAny
  /// Keep one copy of function when linking but apply "One Definition Rule"
  /// semantics.
  ///
  /// Some languages allow differing globals to be merged, such as two functions
  /// with different semantics. Other languages, such as C++, ensure that only
  /// equivalent globals are ever merged (the "one definition rule" — "ODR").
  /// Such languages can use the linkonce_odr and weak_odr linkage types to
  /// indicate that the global will only be merged with equivalent globals.
  /// These linkage types are otherwise the same as their non-odr versions.
  case weakODR
  /// Special purpose, only applies to global arrays.
  ///
  /// "appending" linkage may only be applied to global variables of pointer to
  /// array type. When two global variables with appending linkage are linked
  /// together, the two global arrays are appended together. This is the LLVM,
  /// typesafe, equivalent of having the system linker append together
  /// "sections" with identical names when .o files are linked.
  ///
  /// Unfortunately this doesn’t correspond to any feature in .o files, so it
  /// can only be used for variables like llvm.global_ctors which llvm
  /// interprets specially.
  case appending
  /// Rename collisions when linking (static functions).
  ///
  /// Similar to private, but the value shows as a local symbol
  /// (`STB_LOCAL` in the case of ELF) in the object file. This corresponds to
  /// the notion of the `static` keyword in C.
  case `internal`
  /// Like `.internal`, but omit from symbol table.
  ///
  /// Global values with "private" linkage are only directly accessible by
  /// objects in the current module. In particular, linking code into a module
  /// with an private global value may cause the private to be renamed as
  /// necessary to avoid collisions. Because the symbol is private to the
  /// module, all references can be updated. This doesn’t show up in any symbol
  /// table in the object file.
  case `private`
  /// Keep one copy of the function when linking, but apply ELF semantics.
  ///
  /// The semantics of this linkage follow the ELF object file model: the symbol
  /// is weak until linked, if not linked, the symbol becomes null instead of
  /// being an undefined reference.
  case externalWeak
  /// Tentative definitions.
  ///
  /// "common" linkage is most similar to "weak" linkage, but they are used for
  /// tentative definitions in C, such as "int X;" at global scope. Symbols with
  /// "common" linkage are merged in the same way as weak symbols, and they may
  /// not be deleted if unreferenced. common symbols may not have an explicit
  /// section, must have a zero initializer, and may not be marked ‘constant‘.
  /// Functions and aliases may not have common linkage.
  case common

  private static let linkageMapping: [Linkage: LLVMLinkage] = [
    .external: LLVMExternalLinkage,
    .availableExternally: LLVMAvailableExternallyLinkage,
    .linkOnceAny: LLVMLinkOnceAnyLinkage, .linkOnceODR: LLVMLinkOnceODRLinkage,
    .weakAny: LLVMWeakAnyLinkage, .weakODR: LLVMWeakODRLinkage,
    .appending: LLVMAppendingLinkage, .`internal`: LLVMInternalLinkage,
    .`private`: LLVMPrivateLinkage, .externalWeak: LLVMExternalWeakLinkage,
    .common: LLVMCommonLinkage,
  ]

  internal init(llvm: LLVMLinkage) {
    switch llvm {
    case LLVMExternalLinkage: self = .external
    case LLVMAvailableExternallyLinkage: self = .availableExternally
    case LLVMLinkOnceAnyLinkage: self = .linkOnceAny
    case LLVMLinkOnceODRLinkage: self = .linkOnceODR
    case LLVMWeakAnyLinkage: self = .weakAny
    case LLVMWeakODRLinkage: self = .weakODR
    case LLVMAppendingLinkage: self = .appending
    case LLVMInternalLinkage: self = .internal
    case LLVMPrivateLinkage: self = .private
    case LLVMExternalWeakLinkage: self = .externalWeak
    case LLVMCommonLinkage: self = .common
    default: fatalError("unknown linkage type \(llvm)")
    }
  }

  /// Retrieves the corresponding `LLVMLinkage`.
  public var llvm: LLVMLinkage {
    return Linkage.linkageMapping[self]!
  }
}

/// `StorageClass` enumerates the storage classes for globals in a Portable
/// Executable file.
public enum StorageClass {
  /// The default storage class for declarations is neither imported nor
  /// exported to/from a DLL.
  case `default`
  /// The storage class that guarantees the existence of a function in a DLL.
  ///
  /// Using this attribute can produce tighter code because the compiler may
  /// skip emitting a thunk and instead directly jump to a particular address.
  case dllImport
  /// The storage class for symbols that should be exposed outside of this DLL.
  ///
  /// This storage class augments the use of a `.DEF` file, but cannot
  /// completely replace them.
  case dllExport

  private static let storageMapping: [StorageClass: LLVMDLLStorageClass] = [
    .`default`: LLVMDefaultStorageClass,
    .dllImport: LLVMDLLImportStorageClass,
    .dllExport: LLVMDLLExportStorageClass,
  ]

  internal init(llvm: LLVMDLLStorageClass) {
    switch llvm {
    case LLVMDefaultStorageClass: self = .`default`
    case LLVMDLLImportStorageClass: self = .dllImport
    case LLVMDLLExportStorageClass: self = .dllExport
    default: fatalError("unknown DLL storage class \(llvm)")
    }
  }

  /// Retrieves the corresponding `LLVMDLLStorageClass`.
  public var llvm: LLVMDLLStorageClass {
    return StorageClass.storageMapping[self]!
  }
}

/// Enumerates values representing whether or not this global value's address
/// is significant in this module or the program at large.  A global value's
/// address is considered significant if it is referenced by any module in the
/// final program.
///
/// This attribute is intended to be used only by the code generator and LTO to
/// allow the linker to decide whether the global needs to be in the symbol
/// table.  Constant global values with unnamed addresses and identical
/// initializers may be merged by LLVM.  Note that a global value with an
/// unnamed address may be merged with a global value with a significant address
/// resulting in a global value with a significant address.
public enum UnnamedAddressKind {
  /// Indicates that the address of this global value is significant
  /// in this module.
  case none

  /// Indicates that the address of this global value is not significant to the
  /// current module but it may or may not be significant to another module;
  /// only the content of the value is known to be significant within the
  /// current module.
  case local

  /// Indicates that the address of this global value is not significant to the
  /// current module or any other module; only the content of the value
  /// is significant globally.
  case global

  private static let unnamedAddressMapping: [UnnamedAddressKind: LLVMUnnamedAddr] = [
    .none: LLVMNoUnnamedAddr,
    .local: LLVMLocalUnnamedAddr,
    .global: LLVMGlobalUnnamedAddr,
  ]

  internal init(llvm: LLVMUnnamedAddr) {
    switch llvm {
    case LLVMNoUnnamedAddr: self = .none
    case LLVMLocalUnnamedAddr: self = .local
    case LLVMGlobalUnnamedAddr: self = .global
    default: fatalError("unknown unnamed address kind \(llvm)")
    }
  }

  internal var llvm: LLVMUnnamedAddr {
    return UnnamedAddressKind.unnamedAddressMapping[self]!
  }
}

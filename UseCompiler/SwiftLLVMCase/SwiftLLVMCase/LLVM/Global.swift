//
//  Global.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A `Global` represents a region of memory allocated at compile time instead
/// of at runtime.  A global variable must either have an initializer, or make
/// reference to an external definition that has an initializer.
public final class Global: IRGlobal {
  internal let llvm: LLVMValueRef

  internal init(llvm: LLVMValueRef) {
    self.llvm = llvm
  }

  /// Returns whether this global variable has no initializer because it makes
  /// reference to an initialized value in another translation unit.
  public var isExternallyInitialized: Bool {
    get { return LLVMIsExternallyInitialized(llvm) != 0 }
    set { LLVMSetExternallyInitialized(llvm, newValue.llvm) }
  }

  /// Retrieves the initializer for this global variable, if it exists.
  public var initializer: IRValue? {
    get { return LLVMGetInitializer(asLLVM()) }
    set { LLVMSetInitializer(asLLVM(), newValue!.asLLVM()) }
  }

  /// Returns whether this global variable is a constant, whether or not the
  /// final definition of the global is not.
  public var isGlobalConstant: Bool {
    get { return LLVMIsGlobalConstant(asLLVM()) != 0 }
    set { LLVMSetGlobalConstant(asLLVM(), newValue.llvm) }
  }

  /// Returns whether this global variable is thread-local.  That is, returns
  /// if this variable is not shared by multiple threads.
  public var isThreadLocal: Bool {
    get { return LLVMIsThreadLocal(asLLVM()) != 0 }
    set { LLVMSetThreadLocal(asLLVM(), newValue.llvm) }
  }

  /// Accesses the model of reference for this global variable if it is
  /// thread-local.
  public var threadLocalModel: ThreadLocalModel {
    get { return ThreadLocalModel(llvm: LLVMGetThreadLocalMode(asLLVM())) }
    set { LLVMSetThreadLocalMode(asLLVM(), newValue.llvm) }
  }

  /// Retrieves the previous global in the module, if there is one.
  public func previous() -> Global? {
    guard let previous = LLVMGetPreviousGlobal(llvm) else { return nil }
    return Global(llvm: previous)
  }

  /// Retrieves the next global in the module, if there is one.
  public func next() -> Global? {
    guard let next = LLVMGetNextGlobal(llvm) else { return nil }
    return Global(llvm: next)
  }

  /// Deletes the global variable from its containing module.
  /// - note: This does not remove references to this global from the
  ///         module. Ensure you have removed all instructions that reference
  ///         this global before deleting it.
  public func delete() {
    LLVMDeleteGlobal(llvm)
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }
}

/// Enumerates the supported models of reference of thread-local variables.
///
/// These models are listed from the most general, but least optimized, to the
/// fastest, but most restrictive in general, as architectural differences
/// play a role in determining the access patterns for thread-local storage.
///
/// In general, support for thread-local storage in statically-linked
/// applications is limited: some platforms may not even define the behavior of
/// TLS in such cases.  This is usually not an issue as statically-linked code
/// only ever has one TLS block, the offset of the variables within that block
/// is known, and support for additional dynamic loading of code in
/// statically-linked code is limited.
///
/// Computing the thread-specific address of a TLS variable is usually a dynamic
/// process that relies on an ABI-defined function call (usually
/// `__tls_get_addr`) to do the heavy lifting.
///
/// TLS access models fall into two classes: static and dynamic.  Regardless of
/// the actual model used, the dynamic linker must process all relocations
/// for thread-local variables whenever the module is loaded.  Some models,
/// therefore, provide for a decrease in the overall number of relocations at
/// a cost of restrictions on which modules can access variables.
public enum ThreadLocalModel {
  /// The variable is not thread local and hence has no associated model.
  case notThreadLocal
  /// Allows reference of all thread-local variables, from either a shared
  /// object or a dynamic executable. This model also supports the deferred
  /// allocation of a block of thread-local storage when the block is first
  /// referenced from a specific thread.  Note that the linker is free to
  /// optimize accesses using this model to one of the more specific models
  /// below which may ultimately defeat lazy allocation of the TLS storagee
  /// block.
  ///
  /// The code generated for this model does not assume that any information
  /// about the module or variable offsets is known at link-time.  Instead, the
  /// exact value of these variables is computed by the dynamic linker at
  /// runtime and passeed to `__tls_get_addr` in an architecture-specific way.
  ///
  /// If possible, this model should be avoided if one of the more specific
  /// models applies out of concern for code size and application startup
  /// performance.
  case generalDynamic
  /// This model is an optimization of the `generalDynamic` model. The compiler
  /// might determine that a variable is bound locally, or protected, within the
  /// object being built. In this case, the compiler instructs the linker
  /// to statically bind the dynamic offset of the variable and use this model.
  ///
  /// This model provides a performance benefit over the General Dynamic model.
  /// Only one call to `__tls_get_addr` is required per function, to determine
  /// the starting address of the variable within the TLS block for its
  /// parent module.  Additional accesses can add an offset to this address
  /// value for repeated accesses.
  ///
  /// The optimization available over the `generalDynamic` model is defeated if
  /// a variable is only ever accessed once, as its access would incur the
  /// same `__tls_get_addr` call and the additional overhead of the offset
  /// calculation.
  ///
  /// The linker cannot, in general, optimize from the general dynamic model
  /// to the local dynamic model.
  case localDynamic
  /// This model can only reference thread-local variables which are available
  /// as part of the initial static thread-local template. This template is
  /// composed of all thread-local storage blocks that are available at process
  /// startup, plus a small backup reservation.
  ///
  /// In this model, the thread pointer-relative offset for a given variable `x`
  /// is stored in the GOT entry for x.
  ///
  /// This model can reference a limited number of thread-local variables from
  /// shared libraries loaded after initial process startup, such as by means of
  /// lazy loading, filters, or `dlopen()`. This access is satisfied from a
  /// fixed backup reservation. This reservation can only provide storage for
  /// uninitialized thread-local data items. For maximum flexibility, shared
  /// objects should reference thread-local variables using a dynamic model of
  /// thread-local storage.
  case initialExec
  /// This model is an optimization of the `localDynamic` model.
  ///
  /// This model can only reference thread-local variables which are part of the
  /// thread-local storage block of the dynamic executable. The linker
  /// calculates the thread pointer-relative offsets statically, without the
  /// need for dynamic relocations, or the extra reference to the GOT. This
  /// model can not be used to reference variables outside of the dynamic
  /// executable.
  case localExec

  internal init(llvm: LLVMThreadLocalMode) {
    switch llvm {
    case LLVMNotThreadLocal: self = .notThreadLocal
    case LLVMGeneralDynamicTLSModel: self = .generalDynamic
    case LLVMLocalDynamicTLSModel: self = .localDynamic
    case LLVMInitialExecTLSModel: self = .initialExec
    case LLVMLocalExecTLSModel: self = .localExec
    default: fatalError("unknown thread local mode \(llvm)")
    }
  }

  static let modeMapping: [ThreadLocalModel: LLVMThreadLocalMode] = [
    .notThreadLocal: LLVMNotThreadLocal,
    .generalDynamic: LLVMGeneralDynamicTLSModel,
    .localDynamic: LLVMLocalDynamicTLSModel,
    .initialExec: LLVMInitialExecTLSModel,
    .localExec: LLVMLocalExecTLSModel,
  ]

  /// Retrieves the corresponding `LLVMThreadLocalMode`.
  public var llvm: LLVMThreadLocalMode {
    return ThreadLocalModel.modeMapping[self]!
  }
}

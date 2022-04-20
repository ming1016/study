//
//  Context.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A `Context` is an LLVM compilation session environment.
///
/// A `Context` is a container for the global state of an execution of the
/// LLVM environment and tooling.  It contains independent copies of global and
/// module-level entities like types, metadata attachments, and constants.
///
/// An LLVM context is needed for interacting with LLVM in a concurrent
/// environment. Because a context maintains state independent of any other
/// context, it is recommended that each thread of execution be assigned a unique
/// context.  LLVM's core infrastructure and API provides no locking guarantees
/// and no atomicity guarantees.
public class Context {
  internal let llvm: LLVMContextRef
  private let ownsContext: Bool

  /// Retrieves the global context instance.
  ///
  /// The global context is an particularly convenient instance managed by LLVM
  /// itself.  It is the default context provided for any operations that
  /// require it.
  ///
  /// - WARNING: Failure to specify the correct context in concurrent
  ///   environments can lead to data corruption.  In general, it is always
  ///   recommended that each thread of execution attempting to access the LLVM
  ///   API have its own `Context` instance, rather than rely on this global
  ///   context.
  public static let global = Context(llvm: LLVMGetGlobalContext()!)

  /// Creates a new `Context` object.
  public init() {
    llvm = LLVMContextCreate()
    ownsContext = true
  }

  /// Creates a `Context` object from an `LLVMContextRef` object.
  public init(llvm: LLVMContextRef, ownsContext: Bool = false) {
    self.llvm = llvm
    self.ownsContext = ownsContext
  }

  /// Returns whether the given context is set to discard all value names.
  ///
  /// If true, only the names of GlobalValue objects will be available in
  /// the IR.  This can be used to save memory and processing time, especially
  /// in release environments.
  public var discardValueNames: Bool {
    get { return LLVMContextShouldDiscardValueNames(self.llvm) != 0 }
    set { LLVMContextSetDiscardValueNames(self.llvm, newValue.llvm) }
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    guard self.ownsContext else {
      return
    }
    LLVMContextDispose(self.llvm)
  }
}

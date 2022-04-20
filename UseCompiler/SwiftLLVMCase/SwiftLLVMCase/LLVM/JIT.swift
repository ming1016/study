//
//  JIT.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

///// JITError represents the different kinds of errors the JIT compiler can
///// throw.
//public enum JITError: Error, CustomStringConvertible {
//  /// A generic error thrown by the JIT during exceptional circumstances.
//  ///
//  /// In general, it is not safe to catch and continue after this exception has
//  /// been thrown.
//  case generic(String)
//
//  public var description: String {
//    switch self {
//    case let .generic(desc):
//      return desc
//    }
//  }
//}
//
///// A `JIT` is a Just-In-Time compiler that will compile and execute LLVM IR
///// that has been generated in a `Module`. It can execute arbitrary functions
///// and return the value the function generated, allowing you to write
///// interactive programs that will run as soon as they are compiled.
/////
///// The JIT is fundamentally lazy, and allows control over when and how symbols
///// are resolved.
//public final class JIT {
//  /// A type that represents an address, either symbolically within the JIT or
//  /// physically in the execution environment.
//  public struct TargetAddress: Comparable {
//    fileprivate var llvm: LLVMOrcTargetAddress
//
//    /// Creates a target address value of `0`.
//    public init() {
//      self.llvm = 0
//    }
//
//    /// Creates a target address from a raw address value.
//    public init(raw: LLVMOrcTargetAddress) {
//      self.llvm = raw
//    }
//
//    public static func == (lhs: TargetAddress, rhs: TargetAddress) -> Bool {
//      return lhs.llvm == rhs.llvm
//    }
//
//    public static func < (lhs: TargetAddress, rhs: TargetAddress) -> Bool {
//      return lhs.llvm < rhs.llvm
//    }
//  }
//
//  /// Represents a handle to a module owned by the JIT stack.
//  public struct ModuleHandle {
//    fileprivate var llvm: LLVMOrcModuleHandle
//  }
//
//  /// The underlying LLVMExecutionEngineRef backing this JIT.
//  internal let llvm: LLVMOrcJITStackRef
//  private let ownsContext: Bool
//
//  internal init(llvm: LLVMOrcJITStackRef, ownsContext: Bool) {
//    self.llvm = llvm
//    self.ownsContext = ownsContext
//  }
//
//  /// Create and initialize a `JIT` with this target machine's representation.
//  public convenience init(machine: TargetMachine) {
//    // The JIT stack takes ownership of the target machine.
//    machine.ownsContext = false
//    self.init(llvm: LLVMOrcCreateInstance(machine.llvm), ownsContext: true)
//  }
//
//  /// Deinitialize this value and dispose of its resources.
//  deinit {
//    guard self.ownsContext else {
//      return
//    }
//    _ = LLVMOrcDisposeInstance(self.llvm)
//  }
//
//  // MARK: Symbols
//
//  /// Mangles the given symbol name according to the data layout of the JIT's
//  /// target machine.
//  ///
//  /// - parameter symbol: The symbol name to mangle.
//  /// - returns: A mangled representation of the given symbol name.
//  public func mangle(symbol: String) -> String {
//    var mangledResult: UnsafeMutablePointer<Int8>? = nil
//    LLVMOrcGetMangledSymbol(self.llvm, &mangledResult, symbol)
//    guard let result = mangledResult else {
//      fatalError("Mangled name should never be nil!")
//    }
//    defer { LLVMOrcDisposeMangledSymbol(mangledResult) }
//    return String(cString: result)
//  }
//
//  /// Computes the address of the given symbol, optionally restricting the
//  /// search for its address to a particular module.  If this symbol does not
//  /// exist, an address of `0` is returned.
//  ///
//  /// - parameter symbol: The symbol name to search for.
//  /// - parameter module: An optional value describing the module in which to
//  ///   restrict the search, if any.
//  /// - returns: The address of the symbol, or 0 if it does not exist.
//  public func address(of symbol: String, in module: ModuleHandle? = nil) throws -> TargetAddress {
//    var retAddr: LLVMOrcTargetAddress = 0
//    if let targetModule = module {
//      try checkForJITError(LLVMOrcGetSymbolAddressIn(self.llvm, &retAddr, targetModule.llvm, symbol))
//    } else {
//      try checkForJITError(LLVMOrcGetSymbolAddress(self.llvm, &retAddr, symbol))
//    }
//    return TargetAddress(raw: retAddr)
//  }
//
//  // MARK: Lazy Compilation
//
//  /// Registers a lazy compile callback that can be used to get the target
//  /// address of a trampoline function.  When that trampoline address is
//  /// called, the given compilation callback is fired.
//  ///
//  /// Normally, the trampoline function is a known stub that has been previously
//  /// registered with the JIT.  The callback then computes the address of a
//  /// known entry point and sets the address of the stub to it. See
//  /// `JIT.createIndirectStub` to create a stub function and
//  /// `JIT.setIndirectStubPointer` to set the address of a stub.
//  ///
//  /// - parameter callback: A callback that returns the actual address of the
//  ///   trampoline function.
//  /// - returns: The target address representing a stub.  Calling this stub
//  ///   forces the given compilation callback to fire.
//  public func registerLazyCompile(_ callback: @escaping (JIT) -> TargetAddress) throws -> TargetAddress {
//    var addr: LLVMOrcTargetAddress = 0
//    let callbackContext = ORCLazyCompileCallbackContext(callback)
//    let contextPtr = Unmanaged<ORCLazyCompileCallbackContext>.passRetained(callbackContext).toOpaque()
//    try checkForJITError(LLVMOrcCreateLazyCompileCallback(self.llvm, &addr, lazyCompileBlockTrampoline, contextPtr))
//    return TargetAddress(raw: addr)
//  }
//
//  // MARK: Stubs
//
//  /// Creates a new named indirect stub pointing to the given target address.
//  ///
//  /// An indirect stub may be resolved to a different address at any time by
//  /// invoking `JIT.setIndirectStubPointer`.
//  ///
//  /// - parameter name: The name of the indirect stub.
//  /// - parameter address: The address of the indirect stub.
//  public func createIndirectStub(named name: String, address: TargetAddress) throws {
//    try checkForJITError(LLVMOrcCreateIndirectStub(self.llvm, name, address.llvm))
//  }
//
//  /// Resets the address of an indirect stub.
//  ///
//  /// - warning: The indirect stub must be registered with a call to
//  ///   `JIT.createIndirectStub`.  Failure to do so will result in undefined
//  ///   behavior.
//  ///
//  /// - parameter name: The name of an indirect stub.
//  /// - parameter address: The address to set the indirect stub to point to.
//  public func setIndirectStubPointer(named name: String, address: TargetAddress) throws {
//    try checkForJITError(LLVMOrcSetIndirectStubPointer(self.llvm, name, address.llvm))
//  }
//
//  // MARK: Adding Code to the JIT
//
//  /// Adds the IR from a given module to the JIT, consuming it in the process.
//  ///
//  /// Despite the name of this function, the callback to compile the symbols in
//  /// the module is not necessarily called immediately.  It is called at least
//  /// when a given symbol's address is requested, either by the JIT or by
//  /// the user e.g. `JIT.address(of:)`.
//  ///
//  /// The callback function is required to compute the address of the given
//  /// symbol.  The symbols are passed in mangled form.  Use
//  /// `JIT.mangle(symbol:)` to request the mangled name of a symbol.
//  ///
//  /// - warning: The JIT invalidates the underlying reference to the provided
//  ///   module.  Further references to the module are thus dangling pointers and
//  ///   may be a source of subtle memory bugs.  This will be addressed in a
//  ///   future revision of LLVM.
//  ///
//  /// - parameter module: The module to compile.
//  /// - parameter callback: A function that is called by the JIT to compute the
//  ///   address of symbols.
//  public func addEagerlyCompiledIR(_ module: Module, _ callback: @escaping (String) -> TargetAddress) throws -> ModuleHandle {
//    var handle: LLVMOrcModuleHandle = 0
//    let callbackContext = ORCSymbolCallbackContext(callback)
//    let contextPtr = Unmanaged<ORCSymbolCallbackContext>.passRetained(callbackContext).toOpaque()
//    // The JIT stack takes ownership of the given module.
//    module.ownsContext = false
//    try checkForJITError(LLVMOrcAddEagerlyCompiledIR(self.llvm, &handle, module.llvm, symbolBlockTrampoline, contextPtr))
//    return ModuleHandle(llvm: handle)
//  }
//
//  /// Adds the IR from a given module to the JIT, consuming it in the process.
//  ///
//  /// This function differs from `JIT.addEagerlyCompiledIR` in that the callback
//  /// to request the address of symbols is only executed when that symbol is
//  /// called, either in user code or by the JIT.
//  ///
//  /// The callback function is required to compute the address of the given
//  /// symbol.  The symbols are passed in mangled form.  Use
//  /// `JIT.mangle(symbol:)` to request the mangled name of a symbol.
//  ///
//  /// - warning: The JIT invalidates the underlying reference to the provided
//  ///   module.  Further references to the module are thus dangling pointers and
//  ///   may be a source of subtle memory bugs.  This will be addressed in a
//  ///   future revision of LLVM.
//  ///
//  /// - parameter module: The module to compile.
//  /// - parameter callback: A function that is called by the JIT to compute the
//  ///   address of symbols.
//  public func addLazilyCompiledIR(_ module: Module, _ callback: @escaping (String) -> TargetAddress) throws -> ModuleHandle {
//    var handle: LLVMOrcModuleHandle = 0
//    let callbackContext = ORCSymbolCallbackContext(callback)
//    let contextPtr = Unmanaged<ORCSymbolCallbackContext>.passRetained(callbackContext).toOpaque()
//    // The JIT stack takes ownership of the given module.
//    module.ownsContext = false
//    try checkForJITError(LLVMOrcAddLazilyCompiledIR(self.llvm, &handle, module.llvm, symbolBlockTrampoline, contextPtr))
//    return ModuleHandle(llvm: handle)
//  }
//
//  /// Adds the executable code from an object file to ths JIT, consuming it in
//  /// the process.
//  ///
//  /// The callback function is required to compute the address of the given
//  /// symbol.  The symbols are passed in mangled form.  Use
//  /// `JIT.mangle(symbol:)` to request the mangled name of a symbol.
//  ///
//  /// - warning: The JIT invalidates the underlying reference to the provided
//  ///   memory buffer.  Further references to the buffer are thus dangling
//  ///   pointers and may be a source of subtle memory bugs.  This will be
//  ///   addressed in a future revision of LLVM.
//  ///
//  /// - parameter buffer: A buffer containing an object file.
//  /// - parameter callback: A function that is called by the JIT to compute the
//  ///   address of symbols.
//  public func addObjectFile(_ buffer: MemoryBuffer, _ callback: @escaping (String) -> TargetAddress) throws -> ModuleHandle {
//    var handle: LLVMOrcModuleHandle = 0
//    let callbackContext = ORCSymbolCallbackContext(callback)
//    let contextPtr = Unmanaged<ORCSymbolCallbackContext>.passRetained(callbackContext).toOpaque()
//    // The JIT stack takes ownership of the given buffer.
//    buffer.ownsContext = false
//    try checkForJITError(LLVMOrcAddObjectFile(self.llvm, &handle, buffer.llvm, symbolBlockTrampoline, contextPtr))
//    return ModuleHandle(llvm: handle)
//  }
//
//  /// Remove previously-added code from the JIT.
//  ///
//  /// - warning: Removing a module handle consumes the handle.  Further use of
//  ///   the handle will then result in undefined behavior.
//  ///
//  /// - parameter handle: A handle to previously-added module.
//  public func removeModule(_ handle: ModuleHandle) throws {
//    try checkForJITError(LLVMOrcRemoveModule(self.llvm, handle.llvm))
//  }
//
//  private func checkForJITError(_ orcError: LLVMErrorRef!) throws {
//    guard let err = orcError else {
//      return
//    }
//
//    switch LLVMGetErrorTypeId(err)! {
//    case LLVMGetStringErrorTypeId():
//      guard let msg = LLVMGetErrorMessage(err) else {
//        fatalError("Couldn't get the error message?")
//      }
//      throw JITError.generic(String(cString: msg))
//    default:
//      guard let msg = LLVMOrcGetErrorMsg(self.llvm) else {
//        fatalError("Couldn't get the error message?")
//      }
//      throw JITError.generic(String(cString: msg))
//    }
//  }
//}
//
//private let lazyCompileBlockTrampoline : LLVMOrcLazyCompileCallbackFn = { (callbackJIT, callbackCtx) in
//  guard let jit = callbackJIT, let ctx = callbackCtx else {
//    fatalError("Internal JIT callback and context must be non-nil")
//  }
//
//  let tempJIT = JIT(llvm: jit, ownsContext: false)
//  let callback = Unmanaged<ORCLazyCompileCallbackContext>.fromOpaque(ctx).takeUnretainedValue()
//  return callback.block(tempJIT).llvm
//}
//
//private let symbolBlockTrampoline : LLVMOrcSymbolResolverFn = { (callbackName, callbackCtx) in
//  guard let cname = callbackName, let ctx = callbackCtx else {
//    fatalError("Internal JIT name and context must be non-nil")
//  }
//
//  let name = String(cString: cname)
//  let callback = Unmanaged<ORCSymbolCallbackContext>.fromOpaque(ctx).takeUnretainedValue()
//  return callback.block(name).llvm
//}
//
//private class ORCLazyCompileCallbackContext {
//  fileprivate let block: (JIT) -> JIT.TargetAddress
//
//  fileprivate init(_ block: @escaping (JIT) -> JIT.TargetAddress) {
//    self.block = block
//  }
//}
//
//private class ORCSymbolCallbackContext {
//  fileprivate let block: (String) -> JIT.TargetAddress
//
//  fileprivate init(_ block: @escaping (String) -> JIT.TargetAddress) {
//    self.block = block
//  }
//}

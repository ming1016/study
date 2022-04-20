//
//  Module.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A `Module` represents the top-level structure of an LLVM program. An LLVM
/// module is effectively a translation unit or a collection of translation
/// units merged together.
///
/// LLVM programs are composed of `Module`s consisting of functions, global
/// variables, symbol table entries, and metadata. Modules may be combined
/// together with the LLVM linker, which merges function (and global variable)
/// definitions, resolves forward declarations, and merges symbol table entries.
///
/// Creating a Module
/// ==================
///
/// A module can be created using `init(name:context:)`.
/// Note that the default target triple is bare metal and there is no default data layout.
/// If you require these to be specified (e.g. to increase the correctness of default alignment values),
/// be sure to set them yourself.
///
///     if let machine = try? TargetMachine() {
///         module.targetTriple = machine.triple
///         module.dataLayout = machine.dataLayout
///     }
///
/// Verifying a Module
/// ==================
///
/// A module naturally grows to encompass a large amount of data during code
/// generation.  To verify that the module is well-formed and suitable for
/// submission to later phases of LLVM, call `Module.verify()`.  If the module
/// does not pass verification, an error describing the cause will be thrown.
///
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     let main = builder.addFunction("main",
///                                    type: FunctionType([], VoidType()))
///     let entry = main.appendBasicBlock(named: "entry")
///     builder.positionAtEnd(of: entry)
///     builder.buildRet(main.address(of: entry)!)
///
///     try module.verify()
///     // The following error is thrown:
///     //   module did not pass verification: blockaddress may not be used with the entry block!
///     //   Found return instr that returns non-void in Function of void return type!
///
/// The built-in verifier attempts to be correct at the cost of completeness.
/// For strictest checking, invoke the `lli` tool on any IR that is generated.
///
/// Threading Considerations
/// ========================
///
/// A module value is associated with exactly one LLVM context.  That context,
/// and its creating thread, must be used to access and mutate this module as
/// LLVM provides no locking or atomicity guarantees.
///
/// Printing The Contents of a Module
/// =================================
///
/// The contents of a module are mostly machine-independent.  It is often useful
/// while debugging to view this machine-independent IR.  A module responds to
/// `Module.dump()` by printing this representation to standard output.  To
/// dump the module to a file, use `Module.print(to:)`.  In general, a module
/// must be associated with a `TargetMachine` and a target environment for its
/// contents to be fully useful for export to later file formats such as object
/// files or bitcode.  See `TargetMachine.emitToFile(module:type:path)` for more
/// details.
///
/// Module Flags
/// ============
///
/// To convey information about a module to LLVM's various subsystems, a module
/// may have flags attached.  These flags are keyed by global strings, and
/// attached as metadata to the module with the privileged `llvm.module.flags`
/// metadata identifier.  Certain flags have hard-coded meanings in LLVM such as
/// the Objective-C garbage collection flags or the linker options flags.  Most
/// other flags are stripped from any resulting object files.
public final class Module: CustomStringConvertible {
  internal let llvm: LLVMModuleRef
  internal var ownsContext: Bool = true

  /// Returns the context associated with this module.
  public let context: Context


  /// Creates a `Module` with the given name.
  ///
  /// - parameter name: The name of the module.
  /// - parameter context: The context to associate this module with.  If no
  ///   context is provided, the global context is assumed.
  public init(name: String, context: Context = .global) {

    // Ensure the LLVM initializer is called when the first module is created
    initializeLLVM()

    self.llvm = LLVMModuleCreateWithNameInContext(name, context.llvm)
    self.context = context
  }


  /// Deinitialize this value and dispose of its resources.
  deinit {
    guard self.ownsContext else {
      return
    }
    LLVMDisposeModule(llvm)
  }

  /// Obtain the target triple for this module.
  public var targetTriple: Triple {
    get {
      guard let id = LLVMGetTarget(llvm) else { return Triple("") }
      return Triple(String(cString: id))
    }
    set { LLVMSetTarget(llvm, newValue.data) }
  }

  /// Obtain the data layout for this module.
  public var dataLayout: TargetData {
    get { return TargetData(llvm: LLVMGetModuleDataLayout(llvm)) }
    set { LLVMSetModuleDataLayout(llvm, newValue.llvm) }
  }

  /// Returns a string describing the data layout associated with this module.
  public var dataLayoutString: String {
    get {
      guard let id = LLVMGetDataLayoutStr(llvm) else { return "" }
      return String(cString: id)
    }
    set { LLVMSetDataLayout(llvm, newValue) }
  }

  /// The identifier of this module.
  public var name: String {
    get {
      var count = 0
      guard let id = LLVMGetModuleIdentifier(llvm, &count) else { return "" }
      return String(cString: id)
    }
    set {
      LLVMSetModuleIdentifier(llvm, newValue, newValue.utf8.count)
    }
  }
  
  /// The source filename of this module.
  ///
  /// The source filename appears at the top of an IR module:
  ///
  ///     source_filename = "/path/to/source.c"
  ///
  /// Local functions used in profile data prepend the source file name to the local function name.
  ///
  /// If not otherwise set, `name` is used.
  public var sourceFileName: String {
    get {
      var count = 0
      guard let fn = LLVMGetSourceFileName(llvm, &count) else { return "" }
      return String(cString: fn)
    }
    set {
      LLVMSetSourceFileName(llvm, newValue, newValue.utf8.count)
    }
  }
  
  /// Retrieves the inline assembly for this module, if any.
  public var inlineAssembly: String {
    get {
      var length: Int = 0
      guard let id = LLVMGetModuleInlineAsm(llvm, &length) else { return "" }
      return String(cString: id)
    }
    set {
      LLVMSetModuleInlineAsm2(llvm, newValue, newValue.utf8.count)
    }
  }

  /// Retrieves the sequence of functions that make up this module.
  public var functions: AnySequence<Function> {
    var current = firstFunction
    return AnySequence<Function> {
      return AnyIterator<Function> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Retrieves the first function in this module, if there are any functions.
  public var firstFunction: Function? {
    guard let fn = LLVMGetFirstFunction(llvm) else { return nil }
    return Function(llvm: fn)
  }

  /// Retrieves the last function in this module, if there are any functions.
  public var lastFunction: Function? {
    guard let fn = LLVMGetLastFunction(llvm) else { return nil }
    return Function(llvm: fn)
  }

  /// Retrieves the first global in this module, if there are any globals.
  public var firstGlobal: Global? {
    guard let fn = LLVMGetFirstGlobal(llvm) else { return nil }
    return Global(llvm: fn)
  }

  /// Retrieves the last global in this module, if there are any globals.
  public var lastGlobal: Global? {
    guard let fn = LLVMGetLastGlobal(llvm) else { return nil }
    return Global(llvm: fn)
  }

  /// Retrieves the sequence of functions that make up this module.
  public var globals: AnySequence<Global> {
    var current = firstGlobal
    return AnySequence<Global> {
      return AnyIterator<Global> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Retrieves the first alias in this module, if there are any aliases.
  public var firstAlias: Alias? {
    guard let fn = LLVMGetFirstGlobalAlias(llvm) else { return nil }
    return Alias(llvm: fn)
  }

  /// Retrieves the last alias in this module, if there are any aliases.
  public var lastAlias: Alias? {
    guard let fn = LLVMGetLastGlobalAlias(llvm) else { return nil }
    return Alias(llvm: fn)
  }

  /// Retrieves the sequence of aliases that make up this module.
  public var aliases: AnySequence<Alias> {
    var current = firstAlias
    return AnySequence<Alias> {
      return AnyIterator<Alias> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Retrieves the first alias in this module, if there are any aliases.
  public var firstNamedMetadata: NamedMetadata? {
    guard let fn = LLVMGetFirstNamedMetadata(llvm) else { return nil }
    return NamedMetadata(module: self, llvm: fn)
  }

  /// Retrieves the last alias in this module, if there are any aliases.
  public var lastNamedMetadata: NamedMetadata? {
    guard let fn = LLVMGetLastNamedMetadata(llvm) else { return nil }
    return NamedMetadata(module: self, llvm: fn)
  }

  /// Retrieves the sequence of aliases that make up this module.
  public var namedMetadata: AnySequence<NamedMetadata> {
    var current = firstNamedMetadata
    return AnySequence<NamedMetadata> {
      return AnyIterator<NamedMetadata> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// The current debug metadata version number.
  public static var debugMetadataVersion: UInt32 {
    return LLVMDebugMetadataVersion();
  }

  /// The version of debug metadata that's present in this module.
  public var debugMetadataVersion: UInt32 {
    return LLVMGetModuleDebugMetadataVersion(self.llvm)
  }
}

// MARK: Module Printing

extension Module {
  /// Print a representation of a module to a file at the given path.
  ///
  /// If the provided path is not suitable for writing, this function will throw
  /// `ModuleError.couldNotPrint`.
  ///
  /// - parameter path: The path to write the module's representation to.
  public func print(to path: String) throws {
    var err: UnsafeMutablePointer<Int8>?
    path.withCString { cString in
      let mutable = strdup(cString)
      LLVMPrintModuleToFile(llvm, mutable, &err)
      free(mutable)
    }
    if let err = err {
      defer { LLVMDisposeMessage(err) }
      throw ModuleError.couldNotPrint(path: path, error: String(cString: err))
    }
  }

  /// Dump a representation of this module to stderr.
  public func dump() {
    LLVMDumpModule(llvm)
  }

  /// The full text IR of this module
  public var description: String {
    let cStr = LLVMPrintModuleToString(llvm)!
    defer { LLVMDisposeMessage(cStr) }
    return String(cString: cStr)
  }
}

// MARK: Module Emission

extension Module {
  /// Writes the bitcode of elements in this module to a file at the given path.
  ///
  /// If the provided path is not suitable for writing, this function will throw
  /// `ModuleError.couldNotEmitBitCode`.
  ///
  /// - parameter path: The path to write the module's representation to.
  public func emitBitCode(to path: String) throws {
    let status = path.withCString { cString -> Int32 in
      let mutable = strdup(cString)
      defer { free(mutable) }
      return LLVMWriteBitcodeToFile(llvm, mutable)
    }

    if status != 0 {
      throw ModuleError.couldNotEmitBitCode(path: path)
    }
  }
}

// MARK: Module Actions

extension Module {
  /// Verifies that this module is valid, taking the specified action if not.
  /// If this module did not pass verification, a description of any invalid
  /// constructs is provided with the thrown
  /// `ModuleError.didNotPassVerification` error.
  public func verify() throws {
    var message: UnsafeMutablePointer<Int8>?
    let status = Int(LLVMVerifyModule(llvm, LLVMReturnStatusAction, &message))
    if let message = message, status == 1 {
      defer { LLVMDisposeMessage(message) }
      throw ModuleError.didNotPassVerification(String(cString: message))
    }
  }

  /// Links the given module with this module.  If the link succeeds, this
  /// module will the composite of the two input modules.
  ///
  /// The result of this function is `true` if the link succeeds, or `false`
  /// otherwise.
  ///
  /// - parameter other: The module to link with this module.
  public func link(_ other: Module) -> Bool {
    // First clone the other module; `LLVMLinkModules2` consumes the source
    // module via a move and that module still owns its ModuleRef.
    let otherClone = LLVMCloneModule(other.llvm)
    // N.B. Returns `true` on error.
    return LLVMLinkModules2(self.llvm, otherClone) == 0
  }


  /// Strip debug info in the module if it exists.
  ///
  /// To do this, we remove all calls to the debugger intrinsics and any named
  /// metadata for debugging. We also remove debug locations for instructions.
  /// Return true if module is modified.
  public func stripDebugInfo() -> Bool {
    return LLVMStripModuleDebugInfo(self.llvm) != 0
  }
}

// MARK: Global Declarations

extension Module {
  /// Searches for and retrieves a global variable with the given name in this
  /// module if that name references an existing global variable.
  ///
  /// - parameter name: The name of the global to reference.
  ///
  /// - returns: A value representing the referenced global if it exists.
  public func global(named name: String) -> Global? {
    guard let ref = LLVMGetNamedGlobal(llvm, name) else { return nil }
    return Global(llvm: ref)
  }

  /// Searches for and retrieves a type with the given name in this module if
  /// that name references an existing type.
  ///
  /// - parameter name: The name of the type to create.
  ///
  /// - returns: A representation of the newly created type with the given name
  ///   or nil if such a representation could not be created.
  public func type(named name: String) -> IRType? {
    guard let type = LLVMGetTypeByName(llvm, name) else { return nil }
    return convertType(type)
  }

  /// Searches for and retrieves a function with the given name in this module
  /// if that name references an existing function.
  ///
  /// - parameter name: The name of the function to create.
  ///
  /// - returns: A representation of a function with the given
  ///   name or nil if such a representation could not be created.
  public func function(named name: String) -> Function? {
    guard let fn = LLVMGetNamedFunction(llvm, name) else { return nil }
    return Function(llvm: fn)
  }

  /// Searches for and retrieves an intrinsic with the given name in this module
  /// if that name references an intrinsic.
  ///
  /// - Parameters:
  ///   - name: The name of the intrinsic to search for.
  ///   - parameters: The type of the parameters of the intrinsic to resolve any
  ///     ambiguity caused by overloads.
  /// - returns: A representation of an intrinsic with the given name or nil
  ///   if such an intrinsic could not be found.
  public func intrinsic(named name: String, parameters: [IRType] = []) -> Intrinsic? {
    guard let intrinsic = self.function(named: name) else {
      return nil
    }

    let index = LLVMGetIntrinsicID(intrinsic.asLLVM())
    guard index != 0 else { return nil }

    guard LLVMIntrinsicIsOverloaded(index) != 0 else {
      return Intrinsic(llvm: intrinsic.asLLVM())
    }

    var argIRTypes = parameters.map { $0.asLLVM() as Optional }
    return argIRTypes.withUnsafeMutableBufferPointer { buf -> Intrinsic in
      guard let value = LLVMGetIntrinsicDeclaration(self.llvm, index, buf.baseAddress, parameters.count) else {
        fatalError("Could not retrieve type of intrinsic")
      }
      return Intrinsic(llvm: value)
    }
  }

  /// Searches for and retrieves an intrinsic with the given selector in this
  /// module if that selector references an intrinsic.
  ///
  /// Unlike `Module.intrinsic(named:parameters:)`, the intrinsic function need
  /// not be declared.  If the module contains a declaration of the intrinsic
  /// function, it will be returned.  Else, a declaration for the intrinsic
  /// will be created and appended to this module.
  ///
  /// LLVMSwift intrinsic selector syntax differs from the LLVM naming
  /// conventions for intrinsics in one crucial way: all dots are replaced by
  /// underscores.
  ///
  /// For example:
  ///
  ///     llvm.foo.bar.baz -> Intrinsic.ID.llvm_foo_bar_baz
  ///     llvm.sin -> Intrinsic.ID.llvm_sin
  ///     llvm.stacksave -> Intrinsic.ID.llvm_stacksave
  ///     llvm.x86.xsave64 -> Intrinsic.ID.llvm_x86_xsave64
  ///
  /// - Parameters:
  ///   - selector: The selector of the intrinsic to search for.
  ///   - parameters: The type of the parameters of the intrinsic to resolve any
  ///     ambiguity caused by overloads.
  /// - returns: A representation of an intrinsic with the given name or nil
  ///   if such an intrinsic could not be found.
  public func intrinsic(_ selector: Intrinsic.Selector, parameters: [IRType] = []) -> Intrinsic? {
    var argIRTypes = parameters.map { $0.asLLVM() as Optional }
    return argIRTypes.withUnsafeMutableBufferPointer { buf -> Intrinsic in
      guard let value = LLVMGetIntrinsicDeclaration(self.llvm, selector.index, buf.baseAddress, parameters.count) else {
        fatalError("Could not retrieve type of intrinsic")
      }
      return Intrinsic(llvm: value)
    }
  }


  /// Searches for and retrieves an alias with the given name in this module
  /// if that name references an existing alias.
  ///
  /// - parameter name: The name of the alias to search for.
  ///
  /// - returns: A representation of an alias with the given
  ///   name or nil if no such named alias exists.
  public func alias(named name: String) -> Alias? {
    guard let alias = LLVMGetNamedGlobalAlias(llvm, name, name.count) else { return nil }
    return Alias(llvm: alias)
  }

  /// Searches for and retrieves a comdat section with the given name in this
  /// module.  If none is found, one with that name is created and returned.
  ///
  /// - parameter name: The name of the comdat section to create.
  ///
  /// - returns: A representation of the newly created comdat section with the
  ///   given name.
  public func comdat(named name: String) -> Comdat {
    guard let comdat = LLVMGetOrInsertComdat(llvm, name) else { fatalError() }
    return Comdat(llvm: comdat)
  }

  /// Searches for and retrieves module-level named metadata with the given name
  /// in this module.  If none is found, one with that name is created and
  /// returned.
  ///
  /// - parameter name: The name of the comdat section to create.
  ///
  /// - returns: A representation of the newly created metadata with the
  ///   given name.
  public func metadata(named name: String) -> NamedMetadata {
    return NamedMetadata(module: self, llvm: LLVMGetOrInsertNamedMetadata(self.llvm, name, name.count))
  }

  /// Build a named function body with the given type.
  ///
  /// - parameter name: The name of the newly defined function.
  /// - parameter type: The type of the newly defined function.
  ///
  /// - returns: A value representing the newly inserted function definition.
  public func addFunction(_ name: String, type: FunctionType) -> Function {
    return Function(llvm: LLVMAddFunction(self.llvm, name, type.asLLVM()))
  }

  /// Build a named global of the given type.
  ///
  /// - parameter name: The name of the newly inserted global value.
  /// - parameter type: The type of the newly inserted global value.
  /// - parameter addressSpace: The optional address space where the global
  ///   variable resides.
  ///
  /// - returns: A value representing the newly inserted global variable.
  public func addGlobal(_ name: String, type: IRType, addressSpace: AddressSpace = .zero) -> Global {
    guard let val = LLVMAddGlobalInAddressSpace(llvm, type.asLLVM(), name, UInt32(addressSpace.rawValue)) else {
      fatalError()
    }
    return Global(llvm: val)
  }

  /// Build a named global of the given type.
  ///
  /// - parameter name: The name of the newly inserted global value.
  /// - parameter initializer: The initial value for the global variable.
  /// - parameter addressSpace: The optional address space where the global
  ///   variable resides.
  ///
  /// - returns: A value representing the newly inserted global variable.
  public func addGlobal(_ name: String, initializer: IRValue, addressSpace: AddressSpace = .zero) -> Global {
    let global = addGlobal(name, type: initializer.type)
    global.initializer = initializer
    return global
  }

  /// Build a named global string consisting of an array of `i8` type filled in
  /// with the nul terminated string value.
  ///
  /// - parameter name: The name of the newly inserted global string value.
  /// - parameter value: The character contents of the newly inserted global.
  ///
  /// - returns: A value representing the newly inserted global string variable.
  public func addGlobalString(name: String, value: String) -> Global {
    let length = value.utf8.count

    var global = addGlobal(name, type:
      ArrayType(elementType: IntType.int8, count: length + 1))

    global.alignment = Alignment(1)
    global.initializer = value

    return global
  }

  /// Build a named alias to a global value or a constant expression.
  ///
  /// Aliases, unlike function or variables, don’t create any new data. They are
  /// just a new symbol and metadata for an existing position.
  ///
  /// - parameter name: The name of the newly inserted alias.
  /// - parameter aliasee: The value or constant to alias.
  /// - parameter type: The type of the aliased value or expression.
  ///
  /// - returns: A value representing the newly created alias.
  public func addAlias(name: String, to aliasee: IRGlobal, type: IRType) -> Alias {
    return Alias(llvm: LLVMAddAlias(llvm, type.asLLVM(), aliasee.asLLVM(), name))
  }

  /// Append to the module-scope inline assembly blocks.
  ///
  /// A trailing newline is added if the given string doesn't have one.
  ///
  /// - parameter asm: The inline assembly expression template string.
  public func appendInlineAssembly(_ asm: String) {
    LLVMAppendModuleInlineAsm(llvm, asm, asm.count)
  }
}

// MARK: Module Flags

extension Module {
  /// Represents flags that describe information about the module for use by
  /// an external entity e.g. the dynamic linker.
  ///
  /// - Warning: Module flags are not a general runtime metadata infrastructure,
  ///   and may be stripped by LLVM.  As of the current release, LLVM hardcodes
  ///   support for object-file emission of module flags related to
  ///   Objective-C.
  public class Flags {
    /// Enumerates the supported behaviors for resolving collisions when two
    /// module flags share the same key.  These collisions can occur when the
    /// different flags are inserted under the same key, or when modules
    /// containing flags under the same key are merged.
    public enum Behavior {
      /// Emits an error if two values disagree, otherwise the resulting value
      /// is that of the operands.
      case error
      /// Emits a warning if two values disagree. The result value will be the
      /// operand for the flag from the first module being linked.
      case warning
      /// Adds a requirement that another module flag be present and have a
      /// specified value after linking is performed. The value must be a
      /// metadata pair, where the first element of the pair is the ID of the
      /// module flag to be restricted, and the second element of the pair is
      /// the value the module flag should be restricted to. This behavior can
      /// be used to restrict the allowable results (via triggering of an error)
      /// of linking IDs with the **Override** behavior.
      case require
      /// Uses the specified value, regardless of the behavior or value of the
      /// other module. If both modules specify **Override**, but the values
      /// differ, an error will be emitted.
      case override
      /// Appends the two values, which are required to be metadata nodes.
      case append
      /// Appends the two values, which are required to be metadata
      /// nodes. However, duplicate entries in the second list are dropped
      /// during the append operation.
      case appendUnique

      fileprivate init(raw: LLVMModuleFlagBehavior) {
        switch raw {
        case LLVMModuleFlagBehaviorError:
          self = .error
        case LLVMModuleFlagBehaviorWarning:
          self = .warning
        case LLVMModuleFlagBehaviorRequire:
          self = .require
        case LLVMModuleFlagBehaviorOverride:
          self = .override
        case LLVMModuleFlagBehaviorAppend:
          self = .append
        case LLVMModuleFlagBehaviorAppendUnique:
          self = .appendUnique
        default:
          fatalError("Unknown behavior kind")
        }
      }

      fileprivate static let behaviorMapping: [Behavior: LLVMModuleFlagBehavior] = [
        .error: LLVMModuleFlagBehaviorError,
        .warning: LLVMModuleFlagBehaviorWarning,
        .require: LLVMModuleFlagBehaviorRequire,
        .override: LLVMModuleFlagBehaviorOverride,
        .append: LLVMModuleFlagBehaviorAppend,
        .appendUnique: LLVMModuleFlagBehaviorAppendUnique,
      ]
    }

    /// Represents an entry in the module flags structure.
    public struct Entry {
      fileprivate let base: Flags
      fileprivate let index: UInt32

      /// The conflict behavior of this flag.
      public var behavior: Behavior {
        let raw = LLVMModuleFlagEntriesGetFlagBehavior(self.base.llvm, self.index)
        return Behavior(raw: raw)
      }

      /// The key this flag was inserted with.
      public var key: String {
        var count = 0
        guard let key = LLVMModuleFlagEntriesGetKey(self.base.llvm, self.index, &count) else { return "" }
        return String(cString: key)
      }

      /// The metadata value associated with this flag.
      public var metadata: IRMetadata {
        return AnyMetadata(llvm: LLVMModuleFlagEntriesGetMetadata(self.base.llvm, self.index))
      }
    }

    private let llvm: OpaquePointer?
    private let bounds: Int
    fileprivate init(llvm: OpaquePointer?, bounds: Int) {
      self.llvm = llvm
      self.bounds = bounds
    }

    /// Deinitialize this value and dispose of its resources.
    deinit {
      guard let ptr = llvm else { return }
      LLVMDisposeModuleFlagsMetadata(ptr)
    }

    /// Retrieves a flag at the given index.
    ///
    /// - Parameter index: The index to retrieve.
    ///
    /// - Returns: An entry describing the flag at the given index.
    public subscript(_ index: Int) -> Entry {
      precondition(index >= 0 && index < self.bounds, "Index out of bounds")
      return Entry(base: self, index: UInt32(index))
    }

    /// Returns the number of module flag metadata entries.
    public var count: Int {
      return self.bounds
    }
  }

  /// Add a module-level flag to the module-level flags metadata.
  ///
  /// - Parameters:
  ///   - name: The key for this flag.
  ///   - value: The metadata node to insert as the value for this flag.
  ///   - behavior: The resolution strategy to apply should the key for this
  ///     flag conflict with an existing flag.
  public func addFlag(named name: String, value: IRMetadata, behavior: Flags.Behavior) {
    let raw = Flags.Behavior.behaviorMapping[behavior]!
    LLVMAddModuleFlag(llvm, raw, name, name.count, value.asMetadata())
  }

  /// A convenience for inserting constant values as module-level flags.
  ///
  /// - Parameters:
  ///   - name: The key for this flag.
  ///   - value: The constant value to insert as the metadata for this flag.
  ///   - behavior: The resolution strategy to apply should the key for this
  ///     flag conflict with an existing flag.
  public func addFlag(named name: String, constant: IRConstant, behavior: Flags.Behavior) {
    let raw = Flags.Behavior.behaviorMapping[behavior]!
    LLVMAddModuleFlag(llvm, raw, name, name.count, LLVMValueAsMetadata(constant.asLLVM()))
  }

  /// Retrieves the module-level flags, if they exist.
  public var flags: Flags? {
    var len = 0
    guard let raw = LLVMCopyModuleFlagsMetadata(llvm, &len) else { return nil }
    return Flags(llvm: raw, bounds: len)
  }
}

// MARK: Module Errors

/// Represents the possible errors that can be thrown while interacting with a
/// `Module` object.
public enum ModuleError: Error, CustomStringConvertible {
  /// Thrown when a module does not pass the module verification process.
  /// Includes the reason the module did not pass verification.
  case didNotPassVerification(String)
  /// Thrown when a module cannot be printed at a given path.  Provides the
  /// erroneous path and a deeper reason why printing to that path failed.
  case couldNotPrint(path: String, error: String)
  /// Thrown when a module cannot emit bitcode because it contains erroneous
  /// declarations.
  case couldNotEmitBitCode(path: String)

  public var description: String {
    switch self {
    case .didNotPassVerification(let message):
      return "module did not pass verification: \(message)"
    case .couldNotPrint(let path, let error):
      return "could not print to file \(path): \(error)"
    case .couldNotEmitBitCode(let path):
      return "could not emit bitcode to file \(path) for an unknown reason"
    }
  }
}

extension Bool {
  internal var llvm: LLVMBool {
    return self ? 1 : 0
  }
}

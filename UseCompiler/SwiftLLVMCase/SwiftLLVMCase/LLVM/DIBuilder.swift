//
//  DIBuilder.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A `DIBuilder` is a helper object used to generate debugging information in
/// the form of LLVM metadata.  A `DIBuilder` is usually paired with an
/// `IRBuilder` to allow for the generation of code and metadata in lock step.
public final class DIBuilder {
  internal let llvm: LLVMDIBuilderRef

  /// The module this `DIBuilder` is associated with.
  public let module: Module

  /// Initializes a new `DIBuilder` object.
  ///
  /// - Parameters:
  ///   - module: The parent module.
  ///   - allowUnresolved: If true, when this DIBuilder is finalized it will
  ///                      collect unresolved nodes attached to the module in
  ///                      order to resolve cycles
  public init(module: Module, allowUnresolved: Bool = true) {
    self.module = module
    if allowUnresolved {
      self.llvm = LLVMCreateDIBuilder(module.llvm)
    } else {
      self.llvm = LLVMCreateDIBuilderDisallowUnresolved(module.llvm)
    }
  }

  /// Construct any deferred debug info descriptors.
  public func finalize() {
    LLVMDIBuilderFinalize(self.llvm)
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeDIBuilder(self.llvm)
  }
}

// MARK: Declarations

extension DIBuilder {
  /// Builds a call to a debug intrinsic for declaring a local variable and
  /// inserts it before a given instruction.
  ///
  /// This intrinsic provides information about a local element
  /// (e.g. a variable) defined in some lexical scope.  The variable does not
  /// have to be physically represented in the source.
  ///
  /// Each variable may have at most one corresponding `llvm.dbg.declare`.  A
  /// variable declaration is not control-dependent: A variable is declared at
  /// most once, and that declaration remains in effect until the lifetime of
  /// that variable ends.
  ///
  /// `lldb.dbg.declare` can make optimizing code that needs accurate debug info
  /// difficult because of these scoping constraints.
  ///
  /// - Parameters:
  ///   - variable: The IRValue of a variable to declare.
  ///   - before: The instruction before which the intrinsic will be inserted.
  ///   - metadata: Local variable metadata.
  ///   - expr: A "complex expression" that modifies the current
  ///           variable declaration.
  ///   - location: The location of the variable in source.
  public func buildDeclare(
    of variable: IRValue,
    before: IRInstruction,
    metadata: LocalVariableMetadata,
    expr: ExpressionMetadata,
    location: DebugLocation
  ) {
    guard let _ = LLVMDIBuilderInsertDeclareBefore(
      self.llvm, variable.asLLVM(), metadata.asMetadata(),
      expr.asMetadata(), location.asMetadata(), before.asLLVM()) else {
        fatalError()
    }
  }

  /// Builds a call to a debug intrinsic for declaring a local variable and
  /// inserts it at the end of a given basic block.
  ///
  /// This intrinsic provides information about a local element
  /// (e.g. a variable) defined in some lexical scope.  The variable does not
  /// have to be physically represented in the source.
  ///
  /// Each variable may have at most one corresponding `llvm.dbg.declare`.  A
  /// variable declaration is not control-dependent: A variable is declared at
  /// most once, and that declaration remains in effect until the lifetime of
  /// that variable ends.
  ///
  /// `lldb.dbg.declare` can make optimizing code that needs accurate debug info
  /// difficult because of these scoping constraints.
  ///
  /// - Parameters:
  ///   - variable: The IRValue of a variable to declare.
  ///   - block: The block in which the intrinsic will be placed.
  ///   - metadata: Local variable metadata.
  ///   - expr: A "complex expression" that modifies the current
  ///           variable declaration.
  ///   - location: The location of the variable in source.
  public func buildDeclare(
    of variable: IRValue,
    atEndOf block: BasicBlock,
    metadata: LocalVariableMetadata,
    expr: ExpressionMetadata,
    location: DebugLocation
  ) {
    guard let _ = LLVMDIBuilderInsertDeclareAtEnd(
      self.llvm, variable.asLLVM(), metadata.asMetadata(),
      expr.asMetadata(), location.asMetadata(), block.asLLVM()) else {
        fatalError()
    }
  }

  /// Builds a call to a debug intrinsic for providing information about the
  /// value of a local variable and inserts it before a given instruction.
  ///
  /// This intrinsic provides information to model the result of a source
  /// variable being set to a new value.
  ///
  /// This intrinsic is built to describe the value of a source variable
  /// *directly*.  That is, the source variable may be a value or an address,
  /// but the value for that variable provided to this intrinsic is considered
  /// without interpretation to be the value of the given variable.
  ///
  /// - Parameters:
  ///   - value: The value to set the given variable to.
  ///   - metadata: Metadata for the given local variable.
  ///   - before: The instruction before which the intrinsic will be inserted.
  ///   - expr: A "complex expression" that modifies the given value.
  ///   - location: The location of the variable assignment in source.
  public func buildDbgValue(
    of value: IRValue,
    to metadata: LocalVariableMetadata,
    before: IRInstruction,
    expr: ExpressionMetadata,
    location: DebugLocation
  ) {
    guard let _ = LLVMDIBuilderInsertDbgValueBefore(
      self.llvm, value.asLLVM(), metadata.asMetadata(),
      expr.asMetadata(), location.asMetadata(), before.asLLVM()) else {
        fatalError()
    }
  }

  /// Builds a call to a debug intrinsic for providing information about the
  /// value of a local variable and inserts it before a given instruction.
  ///
  /// This intrinsic provides information to model the result of a source
  /// variable being set to a new value.
  ///
  /// This intrinsic is built to describe the value of a source variable
  /// *directly*.  That is, the source variable may be a value or an address,
  /// but the value for that variable provided to this intrinsic is considered
  /// without interpretation to be the value of the given variable.
  ///
  /// - Parameters:
  ///   - value: The value to set the given variable to.
  ///   - metadata: Metadata for the given local variable.
  ///   - block: The block in which the intrinsic will be placed.
  ///   - expr: A "complex expression" that modifies the given value.
  ///   - location: The location of the variable assignment in source.
  public func buildDbgValue(
    of value: IRValue,
    to metadata: LocalVariableMetadata,
    atEndOf block: BasicBlock,
    expr: ExpressionMetadata,
    location: DebugLocation
  ) {
    guard let _ = LLVMDIBuilderInsertDbgValueAtEnd(
      self.llvm, value.asLLVM(), metadata.asMetadata(),
      expr.asMetadata(), location.asMetadata(), block.asLLVM()) else {
        fatalError()
    }
  }
}

// MARK: Scope Entities

extension DIBuilder {
  /// A CompileUnit provides an anchor for all debugging information generated
  /// during this instance of compilation.
  ///
  /// - Parameters:
  ///   - language: The source programming language.
  ///   - file: The file descriptor for the source file.
  ///   - kind: The kind of debug info to generate.
  ///   - optimized: A flag that indicates whether optimization is enabled or
  ///     not when compiling the source file.  Defaults to `false`.
  ///   - splitDebugInlining: If true, minimal debug info in the module is
  ///     emitted to facilitate online symbolication and stack traces in the
  ///     absence of .dwo/.dwp files when using Split DWARF.
  ///   - debugInfoForProfiling: A flag that indicates whether to emit extra
  ///     debug information for profile collection.
  ///   - flags: Command line options that are embedded in debug info for use
  ///     by third-party tools.
  ///   - splitDWARFPath: The path to the split DWARF file.
  ///   - identity: The identity of the tool that is compiling this source file.
  ///   - sysRoot: The Clang system root (the value of the `-isysroot` that's passed to clang).
  ///   - sdkRoot: The SDK root -- on Darwin platforms, this is the last component of the sysroot.
  /// - Returns: A value representing a compilation-unit level scope.
  public func buildCompileUnit(
    for language: DWARFSourceLanguage,
    in file: FileMetadata,
    kind: DWARFEmissionKind,
    optimized: Bool = false,
    splitDebugInlining: Bool = false,
    debugInfoForProfiling: Bool = false,
    flags: [String] = [],
    runtimeVersion: Int = 0,
    splitDWARFPath: String = "",
    identity: String = "",
    sysRoot: String = "",
    sdkRoot: String = ""
  ) -> CompileUnitMetadata {
    let allFlags = flags.joined(separator: " ")
    guard let cu = LLVMDIBuilderCreateCompileUnit(
      self.llvm, language.llvm, file.llvm, identity, identity.count,
      optimized.llvm,
      allFlags, allFlags.count,
      UInt32(runtimeVersion),
      splitDWARFPath, splitDWARFPath.count,
      kind.llvm,
      /*DWOId*/0,
      splitDebugInlining.llvm,
      debugInfoForProfiling.llvm,
      sysRoot,
      sysRoot.count,
      sdkRoot,
      sdkRoot.count
    ) else {
      fatalError()
    }
    return CompileUnitMetadata(llvm: cu)
  }

  /// Create a file descriptor to hold debugging information for a file.
  ///
  /// Global variables and top level functions would be defined using this
  /// context. File descriptors also provide context for source line
  /// correspondence.
  ///
  /// - Parameters:
  ///   - name: The name of the file.
  ///   - directory: The directory the file resides in.
  /// - Returns: A value represending metadata about a given file.
  public func buildFile(
    named name: String, in directory: String
  ) -> FileMetadata {
    guard let file = LLVMDIBuilderCreateFile(
      self.llvm, name, name.count, directory, directory.count)
    else {
      fatalError("Failed to allocate metadata for a file")
    }
    return FileMetadata(llvm: file)
  }

  /// Creates a new descriptor for a module with the specified parent scope.
  ///
  /// - Parameters:
  ///   - name: Module name.
  ///   - scope: The parent scope containing this module declaration.
  ///   - macros: A list of -D macro definitions as they would appear on a
  ///             command line.
  ///   - includePath: The path to the module map file.
  ///   - includeSystemRoot: The Clang system root (value of -isysroot).
  public func buildModule(
    named name: String,
    scope: DIScope,
    macros: [String] = [],
    includePath: String = "",
    includeSystemRoot: String = ""
  ) -> ModuleMetadata {
    let macros = macros.joined(separator: " ")
    guard
      let module = LLVMDIBuilderCreateModule(
        self.llvm, scope.asMetadata(), name, name.count,
        macros, macros.count, includePath, includePath.count,
        includeSystemRoot, includeSystemRoot.count)
    else {
      fatalError("Failed to allocate metadata for a file")
    }
    return ModuleMetadata(llvm: module)
  }

  /// Creates a new descriptor for a namespace with the specified parent scope.
  ///
  /// - Parameters:
  ///   - name: NameSpace name.
  ///   - scope: The parent scope containing this module declaration.
  ///   - exportsSymbols: Whether or not the namespace exports symbols, e.g.
  ///                    this is true of C++ inline namespaces.
  public func buildNameSpace(
    named name: String, scope: DIScope, exportsSymbols: Bool
  ) -> NameSpaceMetadata {
    guard
      let nameSpace = LLVMDIBuilderCreateNameSpace(
        self.llvm, scope.asMetadata(), name, name.count, exportsSymbols.llvm)
    else {
      fatalError("Failed to allocate metadata for a file")
    }
    return NameSpaceMetadata(llvm: nameSpace)
  }

  /// Create a new descriptor for the specified subprogram.
  ///
  /// - Parameters:
  ///   - name: Function name.
  ///   - linkageName: Mangled function name.
  ///   - scope: Function scope.
  ///   - file: File where this variable is defined.
  ///   - line: Line number.
  ///   - scopeLine: Set to the beginning of the scope this starts
  ///   - type: Function type.
  ///   - flags: Flags to emit DWARF attributes.
  ///   - isLocal: True if this function is not externally visible.
  ///   - isDefinition: True if this is a function definition.
  ///   - isOptimized: True if optimization is enabled.
  public func buildFunction(
    named name: String, linkageName: String,
    scope: DIScope, file: FileMetadata, line: Int, scopeLine: Int,
    type: DISubroutineType,
    flags: DIFlags,
    isLocal: Bool = true, isDefinition: Bool = true,
    isOptimized: Bool = false
  ) -> FunctionMetadata {
    guard let fn = LLVMDIBuilderCreateFunction(
      self.llvm, scope.asMetadata(),
      name, name.count, linkageName, linkageName.count,
      file.asMetadata(), UInt32(line),
      type.asMetadata(),
      isLocal.llvm, isDefinition.llvm, UInt32(scopeLine),
      flags.llvm, isOptimized.llvm)
    else {
      fatalError("Failed to allocate metadata for a function")
    }
    return FunctionMetadata(llvm: fn)
  }

  /// Create a descriptor for a lexical block with the specified parent context.
  ///
  /// - Parameters:
  ///   - scope: Parent lexical block.
  ///   - File: Source file.
  ///   - line: The line in the source file.
  ///   - column: The column in the source file.
  ///
  public func buildLexicalBlock(
    scope: DIScope, file: FileMetadata, line: Int, column: Int
  ) -> LexicalBlockMetadata {
    guard let block = LLVMDIBuilderCreateLexicalBlock(
      self.llvm, scope.asMetadata(), file.asMetadata(),
      UInt32(line), UInt32(column))
    else {
      fatalError("Failed to allocate metadata for a lexical block")
    }
    return LexicalBlockMetadata(llvm: block)
  }

  /// Create a descriptor for a lexical block with a new file attached.
  ///
  /// - Parameters:
  ///   - scope: Lexical block.
  ///   - file: Source file.
  ///   - discriminator: DWARF path discriminator value.
  public func buildLexicalBlockFile(
    scope: DIScope, file: FileMetadata, discriminator: Int
  ) -> LexicalBlockFileMetadata {
    guard let block = LLVMDIBuilderCreateLexicalBlockFile(
      self.llvm, scope.asMetadata(), file.asMetadata(), UInt32(discriminator))
    else {
      fatalError("Failed to allocate metadata for a lexical block file")
    }
    return LexicalBlockFileMetadata(llvm: block)
  }
}

// MARK: Local Variables

extension DIBuilder {
  /// Create a new descriptor for a local auto variable.
  ///
  /// - Parameters:
  ///   - name: Variable name.
  ///   - scope: The local scope the variable is declared in.
  ///   - file: File where this variable is defined.
  ///   - line: Line number.
  ///   - type: Metadata describing the type of the variable.
  ///   - alwaysPreserve: If true, this descriptor will survive optimizations.
  ///   - flags: Flags.
  ///   - alignment: Variable alignment.
  public func buildLocalVariable(
    named name: String,
    scope: DIScope, file: FileMetadata, line: Int,
    type: DIType, alwaysPreserve: Bool = false,
    flags: DIFlags = [], alignment: Alignment
  ) -> LocalVariableMetadata {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let variable = LLVMDIBuilderCreateAutoVariable(
      self.llvm, scope.asMetadata(),
      name, name.count, file.asMetadata(), UInt32(line),
      type.asMetadata(), alwaysPreserve.llvm,
      flags.llvm, alignment.rawValue * radix)
    else {
      fatalError("Failed to allocate metadata for a local variable")
    }
    return LocalVariableMetadata(llvm: variable)
  }

  /// Create a new descriptor for a function parameter variable.
  ///
  /// - Parameters:
  ///   - name: Variable name.
  ///   - index: Unique argument number for this variable; starts at 1.
  ///   - scope: The local scope the variable is declared in.
  ///   - file: File where this variable is defined.
  ///   - line: Line number.
  ///   - type: Metadata describing the type of the variable.
  ///   - alwaysPreserve: If true, this descriptor will survive optimizations.
  ///   - flags: Flags.
  public func buildParameterVariable(
    named name: String, index: Int,
    scope: DIScope, file: FileMetadata, line: Int,
    type: DIType, alwaysPreserve: Bool = false,
    flags: DIFlags = []
  ) -> LocalVariableMetadata {
    guard let variable = LLVMDIBuilderCreateParameterVariable(
      self.llvm, scope.asMetadata(), name, name.count,
      UInt32(index), file.asMetadata(), UInt32(line),
      type.asMetadata(), alwaysPreserve.llvm, flags.llvm)
    else {
      fatalError("Failed to allocate metadata for a parameter variable")
    }
    return LocalVariableMetadata(llvm: variable)
  }
}

// MARK: Debug Locations

extension DIBuilder {
  /// Creates a new debug location that describes a source location.
  ///
  /// - Parameters:
  ///   - location: The location of the line and column for this information.
  ///               If the location of the value is unknown, pass
  ///               `(line: 0, column: 0)`.
  ///   - scope: The scope this debug location resides in.
  ///   - inlinedAt: If this location has been inlined somewhere, the scope in
  ///                which it was inlined.  Defaults to `nil`.
  /// - Returns: A value representing a debug location.
  public func buildDebugLocation(
    at location : (line: Int, column: Int),
    in scope: DIScope,
    inlinedAt: DIScope? = nil
  ) -> DebugLocation {
    guard let loc = LLVMDIBuilderCreateDebugLocation(
      self.module.context.llvm, UInt32(location.line), UInt32(location.column),
      scope.asMetadata(), inlinedAt?.asMetadata())
    else {
      fatalError("Failed to allocate metadata for a debug location")
    }
    return DebugLocation(llvm: loc)
  }
}

extension DIBuilder {
  /// Create subroutine type.
  ///
  /// - Parameters:
  ///   - file: The file in which the subroutine resides.
  ///   - parameterTypes: An array of subroutine parameter types.
  ///   - returnType: The return type of the function, if any.
  ///   - flags: Flags to emit DWARF attributes.
  public func buildSubroutineType(
    in file: FileMetadata,
    parameterTypes: [DIType], returnType: DIType? = nil,
    flags: DIFlags = []
  ) -> DISubroutineType {
    // The return type is always the first operand.
    var diTypes = [returnType?.asMetadata()]
    diTypes.append(contentsOf: parameterTypes.map {
      return $0.asMetadata() as Optional
    })
    return diTypes.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateSubroutineType(
        self.llvm, file.asMetadata(),
        buf.baseAddress!, UInt32(buf.count),
        flags.llvm)
      else {
          fatalError("Failed to allocate metadata")
      }
      return DISubroutineType(llvm: ty)
    }
  }

  /// Create a debugging information entry for an enumeration.
  ///
  /// - Parameters:
  ///   - name: Enumeration name.
  ///   - scope: Scope in which this enumeration is defined.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - elements: Enumeration elements.
  ///   - numElements: Number of enumeration elements.
  ///   - underlyingType: Underlying type of a C++11/ObjC fixed enum.
  public func buildEnumerationType(
    named name: String,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, alignment: Alignment,
    elements: [DIType], underlyingType: DIType
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    var diTypes = elements.map { $0.asMetadata() as Optional }
    return diTypes.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateEnumerationType(
        self.llvm, scope.asMetadata(),
        name, name.count, file.asMetadata(), UInt32(line),
        size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
        buf.baseAddress!, UInt32(buf.count),
        underlyingType.asMetadata())
      else {
        fatalError("Failed to allocate metadata")
      }
      return DIOpaqueType(llvm: ty)
    }
  }

  /// Create a debugging information entry for a union.
  ///
  /// - Parameters:
  ///   - name: Union name.
  ///   - scope: Scope in which this union is defined.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - flags: Flags to encode member attribute, e.g. private
  ///   - elements: Union elements.
  ///   - runtimeVersion: Optional parameter, Objective-C runtime version.
  ///   - uniqueID: A unique identifier for the union.
  public func buildUnionType(
    named name: String,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, alignment: Alignment, flags: DIFlags,
    elements: [DIType],
    runtimeVersion: Int = 0, uniqueID: String = ""
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    var diTypes = elements.map { $0.asMetadata() as Optional }
    return diTypes.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateUnionType(
        self.llvm, scope.asMetadata(),
        name, name.count, file.asMetadata(), UInt32(line),
        size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
        flags.llvm, buf.baseAddress!, UInt32(buf.count),
        UInt32(runtimeVersion), uniqueID, uniqueID.count)
      else {
        fatalError("Failed to allocate metadata")
      }
      return DIOpaqueType(llvm: ty)
    }
  }

  /// Create a debugging information entry for an array.
  ///
  /// - Parameters:
  ///   - elementType: Metadata describing the type of the elements.
  ///   - size: The total size of the array.
  ///   - alignment: The alignment of the array.
  ///   - subscripts: A list of ranges of valid subscripts into the array.  For
  ///                 unbounded arrays, pass the unchecked range `-1...0`.
  public func buildArrayType(
    of elementType: DIType,
    size: Size, alignment: Alignment,
    subscripts: [Range<Int>] = []
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    var diSubs = subscripts.map {
      LLVMDIBuilderGetOrCreateSubrange(self.llvm,
                                       Int64($0.lowerBound), Int64($0.count))
    }
    return diSubs.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateArrayType(
        self.llvm, size.rawValue, alignment.rawValue * radix,
        elementType.asMetadata(),
        buf.baseAddress!, UInt32(buf.count))
      else {
        fatalError("Failed to allocate metadata")
      }
      return DIOpaqueType(llvm: ty)
    }
  }

  /// Create a debugging information entry for a vector.
  ///
  /// - Parameters:
  ///   - elementType: Metadata describing the type of the elements.
  ///   - size: The total size of the array.
  ///   - alignment: The alignment of the array.
  ///   - subscripts: A list of ranges of valid subscripts into the array.  For
  ///                 unbounded arrays, pass the unchecked range `-1...0`.
  public func buildVectorType(
    of elementType: DIType,
    size: Size, alignment: Alignment,
    subscripts: [Range<Int>] = []
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    var diSubs = subscripts.map {
      LLVMDIBuilderGetOrCreateSubrange(self.llvm,
                                       Int64($0.lowerBound), Int64($0.count))
    }
    return diSubs.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateVectorType(
        self.llvm, size.rawValue, alignment.rawValue * radix,
        elementType.asMetadata(),
        buf.baseAddress!, UInt32(buf.count))
      else {
        fatalError("Failed to allocate metadata")
      }
      return DIOpaqueType(llvm: ty)
    }
  }

  /// Create a debugging information entry for a DWARF unspecified type.
  ///
  /// Some languages have constructs in which a type may be left unspecified or
  /// the absence of a type may be explicitly indicated.  For example, C++
  /// permits using the `auto` return type specifier for the return type of a
  /// member function declaration. The actual return type is deduced based on
  /// the definition of the function, so it may not be known when the function
  /// is declared. The language implementation can provide an unspecified type
  /// entry with the name `auto` which can be referenced by the return type
  /// attribute of a function declaration entry. When the function is later
  /// defined, the `subprogram` entry for the definition includes a reference to
  /// the actual return type.
  ///
  /// - Parameter name: The name of the type
  public func buildUnspecifiedType(named name: String) -> DIType {
    guard let ty = LLVMDIBuilderCreateUnspecifiedType(
      self.llvm, name, name.count)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a basic type.
  ///
  /// - Parameters:
  ///   - name: Type name.
  ///   - encoding: The basic type encoding
  ///   - size: Size of the type.
  public func buildBasicType(
    named name: String, encoding: DIAttributeTypeEncoding, flags: DIFlags, size: Size
  ) -> DIType {
    let radix = UInt64(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateBasicType(
      self.llvm, name, name.count,
      size.valueInBits(radix: radix), encoding.llvm, flags.llvm)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a pointer.
  ///
  /// - Parameters:
  ///   - pointee: Type pointed by this pointer.
  ///   - size: The size of the pointer value.
  ///   - alignment: The alignment of the pointer.
  ///   - addressSpace: The address space the pointer type reside in.
  ///   - name: The name of the pointer type.
  public func buildPointerType(
    pointee: DIType, size: Size, alignment: Alignment,
    addressSpace: AddressSpace = .zero, name: String = ""
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreatePointerType(
      self.llvm, pointee.asMetadata(),
      size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
      UInt32(addressSpace.rawValue), name, name.count)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a struct.
  ///
  /// - Parameters:
  ///   - name: Struct name.
  ///   - scope: Scope in which this struct is defined.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: The total size of the struct and its members.
  ///   - alignment: The alignment of the struct.
  ///   - flags: Flags to encode member attributes.
  ///   - elements: Struct elements.
  ///   - vtableHolder: The object containing the vtable for the struct.
  ///   - runtimeVersion: Optional parameter, Objective-C runtime version.
  ///   - uniqueId: A unique identifier for the struct.
  public func buildStructType(
    named name: String,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, alignment: Alignment, flags: DIFlags = [],
    baseType: DIType? = nil, elements: [DIType] = [],
    vtableHolder: DIType? = nil, runtimeVersion: Int = 0, uniqueID: String = ""
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    var diEls = elements.map { $0.asMetadata() as Optional }
    return diEls.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateStructType(
        self.llvm, scope.asMetadata(), name, name.count,
        file.asMetadata(), UInt32(line),
        size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
        flags.llvm,
        baseType?.asMetadata(),
        buf.baseAddress!, UInt32(buf.count), UInt32(runtimeVersion),
        vtableHolder?.asMetadata(), uniqueID, uniqueID.count)
      else {
        fatalError("Failed to allocate metadata")
      }
      return DIOpaqueType(llvm: ty)
    }
  }

  /// Create a debugging information entry for a member.
  ///
  /// - Parameters:
  ///   - parentType: Parent type.
  ///   - scope: Member scope.
  ///   - name: Member name.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - offset: Member offset.
  ///   - flags: Flags to encode member attributes.
  public func buildMemberType(
    of parentType: DIType, scope: DIScope, name: String,
    file: FileMetadata, line: Int,
    size: Size, alignment: Alignment, offset: Size, flags: DIFlags = []
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateMemberType(
      self.llvm, scope.asMetadata(), name, name.count, file.asMetadata(),
      UInt32(line),
      size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
      offset.rawValue,
      flags.llvm, parentType.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a C++ static data member.
  ///
  /// - Parameters:
  ///   - parentType: Type of the static member.
  ///   - scope: Member scope.
  ///   - name: Member name.
  ///   - file: File where this member is declared.
  ///   - line: Line number.
  ///   - alignment: Member alignment.
  ///   - flags: Flags to encode member attributes.
  ///   - initialValue: Constant initializer of the member.
  public func buildStaticMemberType(
    of parentType: DIType, scope: DIScope, name: String, file: FileMetadata,
    line: Int, alignment: Alignment, flags: DIFlags = [],
    initialValue: IRConstant? = nil
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateStaticMemberType(
      self.llvm, scope.asMetadata(), name, name.count,
      file.asMetadata(), UInt32(line),
      parentType.asMetadata(), flags.llvm,
      initialValue?.asLLVM(), alignment.rawValue * radix)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a pointer to member.
  ///
  /// - Parameters:
  ///   - pointee: Type pointed to by this pointer.
  ///   - baseType: Type for which this pointer points to members of.
  ///   - size: Size.
  ///   - alignment: Alignment.
  ///   - flags: Flags.
  public func buildMemberPointerType(
    pointee: DIType, baseType: DIType,
    size: Size, alignment: Alignment,
    flags: DIFlags = []
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateMemberPointerType(
      self.llvm, pointee.asMetadata(), baseType.asMetadata(),
      size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
      flags.llvm)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a uniqued DIType* clone with FlagObjectPointer and
  /// FlagArtificial set.
  ///
  /// - Parameters:
  ///   - pointee: The underlying type to which this pointer points.
  public func buildObjectPointerType(pointee: DIType) -> DIType {
    guard let ty = LLVMDIBuilderCreateObjectPointerType(
      self.llvm, pointee.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a qualified type, e.g. 'const int'.
  ///
  /// - Parameters:
  ///   - tag: Tag identifying type.
  ///   - type: Base Type.
  public func buildQualifiedType(_ tag: DWARFTag, _ type: DIType) -> DIType {
    guard let ty = LLVMDIBuilderCreateQualifiedType(
      self.llvm, tag.rawValue, type.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a c++ style reference or rvalue
  /// reference type.
  ///
  /// - Parameters:
  ///   - tag: Tag identifying type.
  ///   - type: Base Type.
  public func buildReferenceType(_ tag: DWARFTag, _ type: DIType) -> DIType {
    guard let ty = LLVMDIBuilderCreateReferenceType(
      self.llvm, tag.rawValue, type.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create C++11 nullptr type.
  public func buildNullPtrType() -> DIType {
    guard let ty = LLVMDIBuilderCreateNullPtrType(self.llvm) else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }
}

extension DIBuilder {
  /// Create a debugging information entry for a typedef.
  ///
  /// - Parameters:
  ///   - type: Original type.
  ///   - name: Typedef name.
  ///   - alignment: Alignment of the type.
  ///   - scope: The surrounding context for the typedef.
  ///   - file: File where this type is defined.
  ///   - line: Line number.
  public func buildTypedef(
    of type: DIType,
    name: String,
    alignment: Alignment,
    scope: DIScope,
    file: FileMetadata,
    line: Int
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateTypedef(
      self.llvm, type.asMetadata(), name, name.count,
      file.asMetadata(), UInt32(line), scope.asMetadata(),
      alignment.rawValue * radix)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry to establish inheritance relationship
  /// between two types.
  ///
  /// - Parameters:
  ///   - derived: Original type.
  ///   - base: Base type. Ty is inherits from base.
  ///   - baseOffset: Base offset.
  ///   - virtualBasePointerOffset: Virtual base pointer offset.
  ///   - flags: Flags to describe inheritance attribute, e.g. private
  public func buildInheritance(
    of derived: DIType, to base: DIType,
    baseOffset: Size, virtualBasePointerOffset: Size, flags: DIFlags = []
  ) -> DIType {
    let radix = UInt64(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateInheritance(
      self.llvm, derived.asMetadata(),
      base.asMetadata(),
      baseOffset.valueInBits(radix: radix),
      UInt32(virtualBasePointerOffset.valueInBits(radix: radix)),
      flags.llvm)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a permanent forward-declared type.
  ///
  /// - Parameters:
  ///   - name: Type name.
  ///   - tag: A unique tag for this type.
  ///   - scope: Type scope.
  ///   - file: File where this type is defined.
  ///   - line: Line number where this type is defined.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - runtimeLanguage: Indicates runtime version for languages like
  ///     Objective-C.
  ///   - uniqueID: A unique identifier for the type.
  public func buildForwardDeclaration(
    named name: String, tag: DWARFTag,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, alignment: Alignment,
    runtimeLanguage: Int = 0, uniqueID: String = ""
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateForwardDecl(
      self.llvm, tag.rawValue, name, name.count,
      scope.asMetadata(), file.asMetadata(), UInt32(line),
      UInt32(runtimeLanguage),
      size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
      uniqueID, uniqueID.count) else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a temporary forward-declared type.
  ///
  /// - Parameters:
  ///   - name: Type name.
  ///   - tag: A unique tag for this type.
  ///   - scope: Type scope.
  ///   - file: File where this type is defined.
  ///   - line: Line number where this type is defined.
  ///     Objective-C.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - flags: Flags.
  ///   - runtimeVersion: Indicates runtime version for languages like
  ///   - uniqueID: A unique identifier for the type.
  public func buildReplaceableCompositeType(
    named name: String, tag: DWARFTag,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, alignment: Alignment, flags: DIFlags = [],
    runtimeVersion: Int = 0, uniqueID: String = ""
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateReplaceableCompositeType(
      self.llvm, tag.rawValue, name, name.count,
      scope.asMetadata(), file.asMetadata(), UInt32(line),
      UInt32(runtimeVersion),
      size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
      flags.llvm,
      uniqueID, uniqueID.count)
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a bit field member.
  ///
  /// - Parameters:
  ///   - name: Member name.
  ///   - type: Parent type.
  ///   - scope: Member scope.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: Member size.
  ///   - offset: Member offset.
  ///   - storageOffset: Member storage offset.
  ///   - flags: Flags to encode member attribute.
  public func buildBitFieldMemberType(
    named name: String, type: DIType,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, offset: Size, storageOffset: Size,
    flags: DIFlags = []
  ) -> DIType {
    let radix = UInt64(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateBitFieldMemberType(
      self.llvm, scope.asMetadata(), name, name.count,
      file.asMetadata(), UInt32(line),
      size.valueInBits(radix: radix), offset.valueInBits(radix: radix),
      storageOffset.valueInBits(radix: radix),
      flags.llvm, type.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for a class.
  ///
  ///   - name: Class name.
  ///   - baseType: Debug info of the base class of this type.
  ///   - scope: Scope in which this class is defined.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - offset: Member offset.
  ///   - flags: Flags to encode member attribute, e.g. private.
  ///   - elements: Class members.
  ///   - vtableHolder: Debug info of the base class that contains vtable
  ///     for this type. This is used in `DW_AT_containing_type`.
  ///   - uniqueID: A unique identifier for the type.
  public func buildClassType(
    named name: String, derivedFrom baseType: DIType?,
    scope: DIScope, file: FileMetadata, line: Int,
    size: Size, alignment: Alignment, offset: Size, flags: DIFlags,
    elements: [DIType] = [],
    vtableHolder: DIType? = nil, uniqueID: String = ""
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    var diEls = elements.map { $0.asMetadata() as Optional }
    return diEls.withUnsafeMutableBufferPointer { buf in
      guard let ty = LLVMDIBuilderCreateClassType(
        self.llvm, scope.asMetadata(), name, name.count,
        file.asMetadata(), UInt32(line),
        size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
        offset.rawValue, flags.llvm,
        baseType?.asMetadata(),
        buf.baseAddress!, UInt32(buf.count),
        vtableHolder?.asMetadata(), nil, uniqueID, uniqueID.count)
      else {
        fatalError("Failed to allocate metadata")
      }
      return DIOpaqueType(llvm: ty)
    }
  }

  /// Create a uniqued DIType* clone with FlagArtificial set.
  ///
  /// - Parameters:
  ///   - type: The underlying type.
  public func buildArtificialType(_ type: DIType) -> DIType {
    guard let ty = LLVMDIBuilderCreateArtificialType(
      self.llvm, type.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }
}

// MARK: Imported Entities

extension DIBuilder {
  /// Create a descriptor for an imported module.
  ///
  /// - Parameters:
  ///   - context: The scope this module is imported into
  ///   - namespace: The namespace being imported here.
  ///   - file: File where the declaration is located.
  ///   - line: Line number of the declaration.
  public func buildImportedModule(
    in context: DIScope, namespace: NameSpaceMetadata,
    file: FileMetadata, line: Int
  ) -> ImportedEntityMetadata {
    guard let mod = LLVMDIBuilderCreateImportedModuleFromNamespace(
      self.llvm, context.asMetadata(),
      namespace.asMetadata(), file.asMetadata(), UInt32(line))
    else {
      fatalError("Failed to allocate metadata")
    }
    return ImportedEntityMetadata(llvm: mod)
  }

  /// Create a descriptor for an imported module.
  ///
  /// - Parameters:
  ///   - context: The scope this module is imported into.
  ///   - aliasee: An aliased namespace.
  ///   - file: File where the declaration is located.
  ///   - line: Line number of the declaration.
  public func buildImportedModule(
    in context: DIScope, aliasee: ImportedEntityMetadata,
    file: FileMetadata, line: Int
  ) -> ImportedEntityMetadata {
    guard let mod = LLVMDIBuilderCreateImportedModuleFromNamespace(
      self.llvm, context.asMetadata(), aliasee.asMetadata(),
      file.asMetadata(), UInt32(line))
    else {
      fatalError("Failed to allocate metadata")
    }
    return ImportedEntityMetadata(llvm: mod)
  }

  /// Create a descriptor for an imported module.
  ///
  /// - Parameters:
  ///   - context: The scope this module is imported into.
  ///   - module: The module being imported here
  ///   - file: File where the declaration is located.
  ///   - line: Line number of the declaration.
  public func buildImportedModule(
    in context: DIScope, module: ModuleMetadata, file: FileMetadata, line: Int
  ) -> ImportedEntityMetadata {
    guard let mod = LLVMDIBuilderCreateImportedModuleFromModule(
      self.llvm, context.asMetadata(), module.asMetadata(),
      file.asMetadata(), UInt32(line))
    else {
      fatalError("Failed to allocate metadata")
    }
    return ImportedEntityMetadata(llvm: mod)
  }
  
  /// Create a descriptor for an imported function.
  ///
  /// - Parameters:
  ///   - context: The scope this module is imported into.
  ///   - declaration: The declaration (or definition) of a function, type, or
  ///                   variable.
  ///   - file: File where the declaration is located.
  ///   - line: Line number of the declaration.
  ///   - name: The name of the imported declaration.
  public func buildImportedDeclaration(
    in context: DIScope, declaration: IRMetadata,
    file: FileMetadata, line: Int, name: String = ""
  ) -> ImportedEntityMetadata {
    guard let mod = LLVMDIBuilderCreateImportedDeclaration(
      self.llvm, context.asMetadata(),
      declaration.asMetadata(),
      file.asMetadata(), UInt32(line), name, name.count)
    else {
      fatalError("Failed to allocate metadata")
    }
    return ImportedEntityMetadata(llvm: mod)
  }
}

// MARK: Objective-C

extension DIBuilder {
  /// Create a debugging information entry for Objective-C instance variable.
  ///
  /// - Parameters:
  ///   - property: The property associated with this ivar.
  ///   - name: Member name.
  ///   - type: Type.
  ///   - file: File where this member is defined.
  ///   - line: Line number.
  ///   - size: Member size.
  ///   - alignment: Member alignment.
  ///   - offset: Member offset.
  ///   - flags: Flags to encode member attributes.
  public func buildObjCIVar(
    for property: ObjectiveCPropertyMetadata, name: String, type: DIType,
    file: FileMetadata, line: Int,
    size: Size, alignment: Alignment, offset: Size, flags: DIFlags = []
  ) -> DIType {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateObjCIVar(
      self.llvm, name, name.count, file.asMetadata(), UInt32(line),
      size.valueInBits(radix: UInt64(radix)), alignment.rawValue * radix,
      offset.rawValue, flags.llvm, type.asMetadata(), property.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return DIOpaqueType(llvm: ty)
  }

  /// Create a debugging information entry for Objective-C property.
  ///
  /// - Parameters:
  ///   - name: Property name.
  ///   - type: Type.
  ///   - file: File where this property is defined.
  ///   - line: Line number.
  ///   - getter: Name of the Objective C property getter selector.
  ///   - setter: Name of the Objective C property setter selector.
  ///   - propertyAttributes: Objective C property attributes.
  public func buildObjCProperty(
    named name: String, type: DIType,
    file: FileMetadata, line: Int,
    getter: String, setter: String,
    propertyAttributes: ObjectiveCPropertyAttribute
  ) -> ObjectiveCPropertyMetadata {
    guard let ty = LLVMDIBuilderCreateObjCProperty(
      self.llvm, name, name.count, file.asMetadata(), UInt32(line),
      getter, getter.count, setter, setter.count,
      propertyAttributes.rawValue, type.asMetadata())
    else {
      fatalError("Failed to allocate metadata")
    }
    return ObjectiveCPropertyMetadata(llvm: ty)
  }
}

extension DIBuilder {
  /// Create a new descriptor for the specified variable which has a complex
  /// address expression for its address.
  ///
  /// - Parameters:
  ///    - expression: An array of complex address operations.
  public func buildExpression(_ expression: [DWARFExpression]) -> ExpressionMetadata {
    var expr = expression.flatMap { $0.rawValue }
    let count = expr.count
    return expr.withUnsafeMutableBytes { raw in
      let rawVal = raw.bindMemory(to: Int64.self)
      guard let expr = LLVMDIBuilderCreateExpression(
        self.llvm, rawVal.baseAddress!, count)
      else {
        fatalError("Failed to allocate metadata")
      }
      return ExpressionMetadata(llvm: expr)
    }
  }

  /// Create a new descriptor for the specified variable that does not have an
  /// address, but does have a constant value.
  ///
  /// - Parameters:
  ///   - value: The constant value.
  public func buildConstantExpresion(_ value: Int) -> ExpressionMetadata {
    guard let expr = LLVMDIBuilderCreateConstantValueExpression(
      self.llvm, Int64(value))
    else {
      fatalError("Failed to allocate metadata")
    }
    return ExpressionMetadata(llvm: expr)
  }

  /// Create a new descriptor for the specified variable.
  ///
  /// - Parameters:
  ///   - name: Name of the variable.
  ///   - linkageName: Mangled  name of the variable.
  ///   - type: Variable Type.
  ///   - scope: Variable scope.
  ///   - file: File where this variable is defined.
  ///   - line: Line number.
  ///   - isLocal: Boolean flag indicate whether this variable is
  ///     externally visible or not.
  ///   - expression: The location of the global relative to the attached
  ///     GlobalVariable.
  ///   - declaration: Reference to the corresponding declaration.
  ///   - alignment: Variable alignment
  public func buildGlobalExpression(
    named name: String, linkageName: String, type: DIType,
    scope: DIScope, file: FileMetadata, line: Int,
    isLocal: Bool = true,
    expression: ExpressionMetadata? = nil,
    declaration: IRMetadata? = nil,
    alignment: Alignment
  ) -> ExpressionMetadata {
    let radix = UInt32(self.module.dataLayout.intPointerType().width)
    guard let ty = LLVMDIBuilderCreateGlobalVariableExpression(
      self.llvm, scope.asMetadata(),
      name, name.count, linkageName, linkageName.count,
      file.asMetadata(), UInt32(line),
      type.asMetadata(),
      isLocal.llvm,
      expression?.asMetadata(), declaration?.asMetadata(),
      alignment.rawValue * radix)
    else {
      fatalError("Failed to allocate metadata")
    }
    return ExpressionMetadata(llvm: ty)
  }
}

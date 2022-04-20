//
//  IRMetadata.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An unfortunate artifact of the design of the metadata class hierarchy is
/// that you may find it convenient to force-cast metadata nodes.  In general,
/// this behavior is not encouraged, but it will be supported for now.
public protocol _IRMetadataInitializerHack {
  /// Initialize a metadata node from a raw LLVM metadata ref.
  init(llvm: LLVMMetadataRef)
}

/// The `Metadata` protocol captures those types that represent metadata nodes
/// in LLVM IR.
///
/// LLVM IR allows metadata to be attached to instructions in the program that
/// can convey extra information about the code to the optimizers and code
/// generator. One example application of metadata is source-level debug
/// information.
///
/// Metadata does not have a type, and is not a value. If referenced from a call
/// instruction, it uses the metadata type.
///
/// Debug Information
/// =================
///
/// The idea of LLVM debugging information is to capture how the important
/// pieces of the source-language’s Abstract Syntax Tree map onto LLVM code.
/// LLVM takes a number of positions on the impact of the broader compilation
/// process on debug information:
///
/// - Debugging information should have very little impact on the rest of the
///   compiler. No transformations, analyses, or code generators should need to
///   be modified because of debugging information.
/// - LLVM optimizations should interact in well-defined and easily described
///   ways with the debugging information.
/// - Because LLVM is designed to support arbitrary programming languages,
///   LLVM-to-LLVM tools should not need to know anything about the semantics
///   of the source-level-language.
/// - Source-level languages are often widely different from one another. LLVM
///   should not put any restrictions of the flavor of the source-language, and
///   the debugging information should work with any language.
/// - With code generator support, it should be possible to use an LLVM compiler
///   to compile a program to native machine code and standard debugging
///   formats. This allows compatibility with traditional machine-code level
///   debuggers, like GDB, DBX, or CodeView.
public protocol IRMetadata: _IRMetadataInitializerHack {
  /// Retrieves the underlying LLVM metadata object.
  func asMetadata() -> LLVMMetadataRef
}

extension IRMetadata {
  /// Replaces all uses of the this metadata with the given metadata.
  ///
  /// - parameter metadata: The new value to swap in.
  public func replaceAllUses(with metadata: IRMetadata) {
    LLVMMetadataReplaceAllUsesWith(self.asMetadata(), metadata.asMetadata())
  }
}

extension IRMetadata {
  /// Dumps a representation of this metadata to stderr.
  public func dump() {
    LLVMDumpValue(LLVMMetadataAsValue(LLVMGetGlobalContext(), self.asMetadata()))
  }

  /// Force-casts metadata to a destination type.
  ///
  /// - warning: In general, use of this method is discouraged and can
  ///   lead to unpredictable results or undefined behavior.  No checks are
  ///   performed before, during, or after the cast.
  public func forceCast<DestTy: IRMetadata>(to: DestTy.Type) -> DestTy {
    return DestTy(llvm: self.asMetadata())
  }

  /// Returns the kind of this metadata node.
  public var kind: IRMetadataKind {
    return IRMetadataKind(raw: LLVMGetMetadataKind(self.asMetadata()))
  }
}

/// Denotes a scope in which child metadata nodes can be inserted.
public protocol DIScope: IRMetadata {}

extension DIScope {
  /// Retrieves the file metadata associated with this scope, if any.
  public var file: FileMetadata? {
    return LLVMDIScopeGetFile(self.asMetadata()).map(FileMetadata.init(llvm:))
  }
}

/// Denotes metadata for a type.
public protocol DIType: DIScope {}

extension DIType {
  /// Retrieves the name of this type.
  public var name: String {
    var length: Int = 0
    let cstring = LLVMDITypeGetName(self.asMetadata(), &length)
    return String(cString: cstring!)
  }

  /// Retrieves the size of the type represented by this metadata in bits.
  public var sizeInBits: Size {
    return Size(LLVMDITypeGetSizeInBits(self.asMetadata()))
  }

  /// Retrieves the offset of the type represented by this metadata in bits.
  public var offsetInBits: Size {
    return Size(LLVMDITypeGetOffsetInBits(self.asMetadata()))
  }

  /// Retrieves the alignment of the type represented by this metadata in bits.
  public var alignmentInBits: Alignment {
    return Alignment(LLVMDITypeGetAlignInBits(self.asMetadata()))
  }

  /// Retrieves the line the type represented by this metadata is declared on.
  public var line: Int {
    return Int(LLVMDITypeGetLine(self.asMetadata()))
  }

  /// Retrieves the flags the type represented by this metadata is declared
  /// with.
  public var flags: DIFlags {
    return DIFlags(rawValue: LLVMDITypeGetFlags(self.asMetadata()).rawValue)
  }
}

/// A `DebugLocation` represents a location in source.
///
/// Debug locations are de-duplicated by file and line.  If more than one
/// location inside a given scope needs to share a line, a discriminator value
/// must be set or those locations will be considered equivalent.
public struct DebugLocation: IRMetadata {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  /// Retrieves the line described by this location.
  public var line: Int {
    return Int(LLVMDILocationGetLine(self.llvm))
  }

  /// Retrieves the column described by this location.
  public var column: Int {
    return Int(LLVMDILocationGetColumn(self.llvm))
  }

  /// Retrieves the enclosing scope containing this location.
  public var scope: DIScope {
    return DIOpaqueType(llvm: LLVMDILocationGetScope(self.llvm))
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

struct AnyMetadata: IRMetadata {
  let llvm: LLVMMetadataRef

  func asMetadata() -> LLVMMetadataRef {
    return llvm
  }
}

struct DIOpaqueType: DIType {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `CompileUnitMetadata` nodes represent a compile unit, the root of a metadata
/// hierarchy for a translation unit.
///
/// Compile unit descriptors provide the root scope for objects declared in a
/// specific compilation unit. `FileMetadata` descriptors are defined using this
/// scope.
///
/// These descriptors are collected by a named metadata node `!llvm.dbg.cu`.
/// They keep track of global variables, type information, and imported entities
/// (declarations and namespaces).
public struct CompileUnitMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}


/// `FileMetadata` nodes represent files.
///
/// The file name does not necessarily have to be a proper file path.  For
/// example, it can include additional slash-separated path components.
public struct FileMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }

  /// Retrieves the name of this file
  public var name: String {
    var length: UInt32 = 0
    let cstring = LLVMDIFileGetFilename(self.asMetadata(), &length)
    return String(cString: cstring!)
  }

  /// Retrieves the directory of this file
  public var directory: String {
    var length: UInt32 = 0
    let cstring = LLVMDIFileGetDirectory(self.asMetadata(), &length)
    return String(cString: cstring!)
  }

  /// Retrieves the source text of this file.
  public var source: String {
    var length: UInt32 = 0
    let cstring = LLVMDIFileGetSource(self.asMetadata(), &length)
    return String(cString: cstring!)
  }
}

/// `DIBasicType` nodes represent primitive types, such as `int`, `bool` and
/// `float`.
///
/// Basic types carry an encoding describing the details of the type to
/// influence how it is presented in debuggers.  LLVM currently supports
/// specific DWARF "Attribute Type Encodings" that are enumerated in
/// `DIAttributeTypeEncoding`.
public struct DIBasicType: DIType {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `DISubroutineType` nodes represent subroutine types.
///
/// Subroutine types are meant to mirror their formal declarations in source:
/// arguments are represented in order.  The return type is optional and meant
/// to represent the concept of `void` in C-like languages.
public struct DISubroutineType: DIType {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `LexicalBlockMetadata` nodes describe nested blocks within a subprogram. The
/// line number and column numbers are used to distinguish two lexical blocks at
/// same depth.
///
/// Usually lexical blocks are distinct to prevent node merging based on
/// operands.
public struct LexicalBlockMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `LexicalBlockFile` nodes are used to discriminate between sections of a
/// lexical block. The file field can be changed to indicate textual inclusion,
/// or the discriminator field can be used to discriminate between control flow
/// within a single block in the source language.
public struct LexicalBlockFileMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `LocalVariableMetadata` nodes represent local variables and function
/// parameters in the source language.
public struct LocalVariableMetadata: IRMetadata {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `ObjectiveCPropertyMetadata` nodes represent Objective-C property nodes.
public struct ObjectiveCPropertyMetadata: IRMetadata {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `ImportedEntityMetadata` nodes represent entities (such as modules) imported
/// into a compile unit.
public struct ImportedEntityMetadata: DIType {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `NameSpaceMetadata` nodes represent subroutines in the source program.
/// They are attached to corresponding LLVM IR functions.
public struct FunctionMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `NameSpaceMetadata` nodes represent entities like C++ modules.
public struct ModuleMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `NameSpaceMetadata` nodes represent entities like C++ namespaces.
public struct NameSpaceMetadata: DIScope {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// `MDString` nodes represent string constants in metadata nodes.
public struct MDString: IRMetadata, ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  private let llvm: LLVMMetadataRef

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }

  /// Create an `MDString` node from the given string value.
  ///
  /// - Parameters:
  ///   - value: The string value to assign to this metadata node.
  public init(_ value: String) {
    self.llvm = LLVMValueAsMetadata(LLVMMDString(value, UInt32(value.count)))
  }

  public init(stringLiteral value: String) {
    self.llvm = LLVMValueAsMetadata(LLVMMDString(value, UInt32(value.count)))
  }

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }
}

/// `MDNode` objects represent generic nodes in a metadata graph.
///
/// A metadata node is a tuple of references to other metadata.  In general,
/// metadata graphs are acyclic and terminate in metadata nodes without
/// operands.
public struct MDNode: IRMetadata {
  private let llvm: LLVMMetadataRef

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }

  /// Create a metadata node in the given context with the given operands.
  ///
  /// - Parameters:
  ///   - context: The context to allocate the node in.
  ///   - operands: The operands to attach to the metadata node.
  public init(in context: Context = .global, operands: [IRMetadata]) {
    var operands = operands.map { $0.asMetadata() as Optional }
    self.llvm = operands.withUnsafeMutableBufferPointer { buf in
      return LLVMMDNodeInContext2(context.llvm, buf.baseAddress!, buf.count)
    }
  }

  /// Create a metadata node with the value of a given constant.
  ///
  /// - Parameters:
  ///   - constant: The constant value to attach to the node.
  public init(constant: IRConstant) {
    self.llvm = LLVMValueAsMetadata(constant.asLLVM())
  }

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }
}

/// Represents a temporary metadata node.
///
/// Temporary metadata nodes aid in the construction of cyclic metadata. The
/// typical construction pattern is usually as follows:
///
///     // Allocate a temporary temp node
///     let temp = TemporaryMDNode(in: context, operands: [])
///     // Prepare the operands to the metadata node...
///     var ops = [IRMetadata]()
///     // ...
///     // Create the real node
///     let root = MDNode(in: context, operands: ops)
///
/// At this point we have the following metadata structure:
///
///     //   !0 = metadata !{}            <- temp
///     //   !1 = metadata !{metadata !0} <- root
///     // Replace the temp operand with the root node
///
/// The knot is tied by RAUW'ing the temporary node:
///
///     temp.replaceAllUses(with: root)
///     // We now have
///     //   !1 = metadata !{metadata !1} <- self-referential root
///
/// - Warning: It is critical that temporary metadata nodes be "RAUW'd"
///   (replace-all-uses-with) before the metadata graph is finalized.  After
///   that time, all remaining temporary metadata nodes will become unresolved
///   metadata.
public class TemporaryMDNode: IRMetadata {
  private let llvm: LLVMMetadataRef

  required public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }

  /// Create a new temporary metadata node in the given context with the
  /// given operands.
  ///
  /// - Parameters:
  ///   - context: The context to allocate the node in.
  ///   - operands: The operands to attach to the metadata node.
  public init(in context: Context = .global, operands: [IRMetadata]) {
    var operands = operands.map { $0.asMetadata() as Optional }
    self.llvm = operands.withUnsafeMutableBufferPointer { buf in
      return LLVMTemporaryMDNode(context.llvm, buf.baseAddress!, buf.count)
    }
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeTemporaryMDNode(self.llvm)
  }

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }
}

/// `ExpressionMetadata` nodes represent expressions that are inspired by the
/// DWARF expression language. They are used in debug intrinsics (such as
/// llvm.dbg.declare and llvm.dbg.value) to describe how the referenced LLVM
/// variable relates to the source language variable.
///
/// Debug intrinsics are interpreted left-to-right: start by pushing the
/// value/address operand of the intrinsic onto a stack, then repeatedly push
/// and evaluate opcodes from the `ExpressionMetadata` until the final variable
/// description is produced.
///
/// Though DWARF supports hundreds of expressions, LLVM currently implements
/// a very limited subset.
public struct ExpressionMetadata: IRMetadata {
  internal let llvm: LLVMMetadataRef

  public func asMetadata() -> LLVMMetadataRef {
    return llvm
  }

  public init(llvm: LLVMMetadataRef) {
    self.llvm = llvm
  }
}

/// Enumerates the kind of metadata nodes.
public enum IRMetadataKind {
  /// The metadata is a string.
  case mdString
  /// The metadata is a constant-as-metadata node.
  case constantAsMetadata
  /// The metadata is a local-as-metadata node.
  case localAsMetadata
  /// The metadata is a disctint metadata operand placeholder.
  case distinctMDOperandPlaceholder
  /// The metadata is a tuple.
  case mdTuple
  /// The metadata is a location.
  case location
  /// The metadata is an expression.
  case expression
  /// The metadata is a global variable expression.
  case globalVariableExpression
  /// The metadata is a generic DI node.
  case genericDINode
  /// The metadata is a subrange.
  case subrange
  /// The metadata is an enumerator.
  case enumerator
  /// The metadata is a basic type.
  case basicType
  /// The metadata is a derived type.
  case derivedType
  /// The metadata is a composite type.
  case compositeType
  /// The metadata is a subroutine type.
  case subroutineType
  /// The metadata is a file.
  case file
  /// The metadata is a compile unit.
  case compileUnit
  /// The metadata is a subprogram.
  case subprogram
  /// The metadata is a lexical block.
  case lexicalBlock
  /// The metadata is a lexical block file.
  case lexicalBlockFile
  /// The metadata is a namespace.
  case namespace
  /// The metadata is a module.
  case module
  /// The metadata is a template type parameter.
  case templateTypeParameter
  /// The metadata is a template value parameter.
  case templateValueParameter
  /// The metadata is a global variable.
  case globalVariable
  /// The metadata is a local variable.
  case localVariable
  /// The metadata is a label.
  case label
  /// The metadata is an Objective-C property.
  case objCProperty
  /// The metadata is an imported entity.
  case importedEntity
  /// The metadata is a macro.
  case macro
  /// The metadata is a macro file.
  case macroFile

  fileprivate init(raw: LLVMMetadataKind) {
    switch Int(raw) {
    case LLVMMDStringMetadataKind: self = .mdString
    case LLVMConstantAsMetadataMetadataKind: self = .constantAsMetadata
    case LLVMLocalAsMetadataMetadataKind: self = .localAsMetadata
    case LLVMDistinctMDOperandPlaceholderMetadataKind: self = .distinctMDOperandPlaceholder
    case LLVMMDTupleMetadataKind: self = .mdTuple
    case LLVMDILocationMetadataKind: self = .location
    case LLVMDIExpressionMetadataKind: self = .expression
    case LLVMDIGlobalVariableExpressionMetadataKind: self = .globalVariableExpression
    case LLVMGenericDINodeMetadataKind: self = .genericDINode
    case LLVMDISubrangeMetadataKind: self = .subrange
    case LLVMDIEnumeratorMetadataKind: self = .enumerator
    case LLVMDIBasicTypeMetadataKind: self = .basicType
    case LLVMDIDerivedTypeMetadataKind: self = .derivedType
    case LLVMDICompositeTypeMetadataKind: self = .compositeType
    case LLVMDISubroutineTypeMetadataKind: self = .subroutineType
    case LLVMDIFileMetadataKind: self = .file
    case LLVMDICompileUnitMetadataKind: self = .compileUnit
    case LLVMDISubprogramMetadataKind: self = .subprogram
    case LLVMDILexicalBlockMetadataKind: self = .lexicalBlock
    case LLVMDILexicalBlockFileMetadataKind: self = .lexicalBlockFile
    case LLVMDINamespaceMetadataKind: self = .namespace
    case LLVMDIModuleMetadataKind: self = .module
    case LLVMDITemplateTypeParameterMetadataKind: self = .templateTypeParameter
    case LLVMDITemplateValueParameterMetadataKind: self = .templateValueParameter
    case LLVMDIGlobalVariableMetadataKind: self = .globalVariable
    case LLVMDILocalVariableMetadataKind: self = .localVariable
    case LLVMDILabelMetadataKind: self = .label
    case LLVMDIObjCPropertyMetadataKind: self = .objCProperty
    case LLVMDIImportedEntityMetadataKind: self = .importedEntity
    case LLVMDIMacroMetadataKind: self = .macro
    case LLVMDIMacroFileMetadataKind: self = .macroFile
    default:
      fatalError("Unknown kind")
    }
  }
}

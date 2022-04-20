//
//  MetadataAttributes.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// Source languages known to DWARF.
public enum DWARFSourceLanguage {
  /// ISO Ada:1983
  case ada83
  /// ISO Ada:1995
  case ada95
  /// BLISS
  case bliss
  /// Non-standardized C, e.g. K&R C.
  case c
  /// ISO C:1989.
  case c89
  /// ISO C:1999.
  case c99
  /// ISO C:2011
  case c11
  /// ISO C++90
  case cPlusPlus
  /// ISO C++03
  case cPlusPlus03
  /// ISO C++11
  case cPlusPlus11
  /// ISO C++14
  case cPlusPlus14
  /// ISO COBOL:1974
  case cobol74
  /// ISO COBOL:1985
  case cobol85
  /// C
  case d
  /// Dylan
  case dylan
  /// ISO FORTRAN:1977
  case fortran77
  /// ISO Fortran:1990
  case fortran90
  /// ISO Fortran:1995
  case fortran95
  /// ISO Fortran:2004
  case fortran03
  /// ISO Fortran:2010
  case fortran08
  /// Go
  case go
  /// Haskell
  case haskell
  /// Java
  case java
  /// Julia
  case julia
  /// ISO Modula-2:1996
  case modula2
  /// Module-3
  case modula3
  /// Objective-C
  case objectiveC
  /// Objective-C++
  case objectiveCPlusPlus
  /// OCaml
  case ocaml
  /// OpenCL
  case openCL
  /// ISO Pascal:1983
  case pascal83
  /// ANSI PL/I:1976
  case pli
  /// Python
  case python
  /// RenderScript Kernel Language
  case renderScript
  /// Rust
  case rust
  /// Swift
  case swift
  /// Unified Parallel C
  case upc

  // MARK: Vendor Extensions

  /// MIPS Assembler
  case mipsAssembler
  /// Google RenderScript Kernel Language
  case googleRenderScript
  /// Borland Delphi
  case borlandDelphi


  private static let languageMapping: [DWARFSourceLanguage: LLVMDWARFSourceLanguage] = [
    .c: LLVMDWARFSourceLanguageC, .c89: LLVMDWARFSourceLanguageC89,
    .c99: LLVMDWARFSourceLanguageC99, .c11: LLVMDWARFSourceLanguageC11,
    .ada83: LLVMDWARFSourceLanguageAda83,
    .cPlusPlus: LLVMDWARFSourceLanguageC_plus_plus,
    .cPlusPlus03: LLVMDWARFSourceLanguageC_plus_plus_03,
    .cPlusPlus11: LLVMDWARFSourceLanguageC_plus_plus_11,
    .cPlusPlus14: LLVMDWARFSourceLanguageC_plus_plus_14,
    .cobol74: LLVMDWARFSourceLanguageCobol74,
    .cobol85: LLVMDWARFSourceLanguageCobol85,
    .fortran77: LLVMDWARFSourceLanguageFortran77,
    .fortran90: LLVMDWARFSourceLanguageFortran90,
    .pascal83: LLVMDWARFSourceLanguagePascal83,
    .modula2: LLVMDWARFSourceLanguageModula2,
    .java: LLVMDWARFSourceLanguageJava,
    .ada95: LLVMDWARFSourceLanguageAda95,
    .fortran95: LLVMDWARFSourceLanguageFortran95,
    .pli: LLVMDWARFSourceLanguagePLI,
    .objectiveC: LLVMDWARFSourceLanguageObjC,
    .objectiveCPlusPlus: LLVMDWARFSourceLanguageObjC_plus_plus,
    .upc: LLVMDWARFSourceLanguageUPC,
    .d: LLVMDWARFSourceLanguageD,
    .python: LLVMDWARFSourceLanguagePython,
    .openCL: LLVMDWARFSourceLanguageOpenCL,
    .go: LLVMDWARFSourceLanguageGo,
    .modula3: LLVMDWARFSourceLanguageModula3,
    .haskell: LLVMDWARFSourceLanguageHaskell,
    .ocaml: LLVMDWARFSourceLanguageOCaml,
    .rust: LLVMDWARFSourceLanguageRust,
    .swift: LLVMDWARFSourceLanguageSwift,
    .julia: LLVMDWARFSourceLanguageJulia,
    .dylan: LLVMDWARFSourceLanguageDylan,
    .fortran03: LLVMDWARFSourceLanguageFortran03,
    .fortran08: LLVMDWARFSourceLanguageFortran08,
    .renderScript: LLVMDWARFSourceLanguageRenderScript,
    .bliss: LLVMDWARFSourceLanguageBLISS,
    .mipsAssembler: LLVMDWARFSourceLanguageMips_Assembler,
    .googleRenderScript: LLVMDWARFSourceLanguageGOOGLE_RenderScript,
    .borlandDelphi: LLVMDWARFSourceLanguageBORLAND_Delphi,
  ]

  /// Retrieves the corresponding `LLVMDWARFSourceLanguage`.
  internal var llvm: LLVMDWARFSourceLanguage {
    return DWARFSourceLanguage.languageMapping[self]!
  }
}

/// Enumerates the supported identifying tags for corresponding DWARF
/// Debugging Information Entries (DIEs) known to LLVM.
public enum DWARFTag: UInt32 {
  /// Identifies metadata for an array type.
  case arrayType = 0x0001
  /// Identifies metadata for a class type.
  case classType = 0x0002
  /// Identifies metadata for an alternate entry point.
  case entryPoint = 0x0003
  /// Identifies metadata for an enumeration type.
  case enumerationType = 0x0004
  /// Identifies metadata for a formal parameter of a parameter list.
  case formalParameter = 0x0005
  /// Identifies metadata for an imported declaration.
  case importedDeclaration = 0x0008
  /// Identifies metadata for a label in the source; the
  /// target of one or more `go to` statements.
  case label = 0x000a
  /// Identifies metadata for a lexical block in the source (usually for
  /// C-like languages).
  case lexicalBlock = 0x000b
  /// Identifies metadata for a data member.
  case member = 0x000d
  /// Identifies metadata for a pointer type.
  case pointerType = 0x000f
  /// Identifies metadata for a reference type
  case referenceType = 0x0010
  /// Identifies metadata for a complete compilation unit.
  case compileUnit = 0x0011
  /// Identifies metadata for a string type.
  case stringType = 0x0012
  /// Identifies metadata for a structure type.
  case structureType = 0x0013
  /// Identifies metadata for a subroutine type.
  case subroutineType = 0x0015
  /// Identifies metadata for a typedef declaration.
  case typedef = 0x0016
  /// Identifies metadata for a union type.
  case unionType = 0x0017
  /// Identifies metadata for an unspecified parameter list.  Can also be used
  /// to identify vararg parameter lists.
  case unspecifiedParameters = 0x0018
  /// Identifies metadata for a variant record.
  case variant = 0x0019
  /// Identifies metadata for a Fortran common block.
  case commonBlock = 0x001a
  /// Identifies metadata for a Fortran common inclusion.
  case commonInclusion = 0x001b
  /// Identifies metadata for an inheritance clause.
  case inheritance = 0x001c
  /// Identifies metadata for an inlined subroutine.
  case inlinedSubroutine = 0x001d
  /// Identifies metadata for a module.
  case module = 0x001e
  /// Identifies metadata for a pointer to a data member.
  case ptrToMemberType = 0x001f
  /// Identifies metadata for a set type.
  case setType = 0x0020
  /// Identifies metadata for a subrange type describing the
  /// dimensions of an array.
  case subrangeType = 0x0021
  /// Identifies metadata for Pascal and Modula-2's `with` statements.
  case withStmt = 0x0022
  /// Identifies metadata for an access declaration.
  case accessDeclaration = 0x0023
  /// Identifies metadata for a a base type: a type that is not defined in terms
  /// of metadata for other data types.
  case baseType = 0x0024
  /// Identifies metadata for the catch block in a `try-catch` statement.
  case catchBlock = 0x0025
  /// Identifies metadata for a constant type.
  case constType = 0x0026
  /// Identifies metadata for a constant.
  case constant = 0x0027
  /// Identifies metadata for an enumerator.
  case enumerator = 0x0028
  /// Identifies metadata for a file.
  case fileType = 0x0029
  /// Identifies metadata for a C++ `friend` declaration.
  case friend = 0x002a
  /// Identifies metadata for a Fortran 90 namelist.
  case namelist = 0x002b
  /// Identifies metadata for an item in a Fortran 90 namelist.
  case namelistItem = 0x002c
  /// Identifies metadata for an Ada or Pascal packed type.
  case packedType = 0x002d
  /// Identifies metadata for a subprogram.
  case subprogram = 0x002e
  /// Identifies metadata for a template type parameter.
  case templateTypeParameter = 0x002f
  /// Identifies metadata for a template value parameter.
  case templateValueParameter = 0x0030
  /// Identifies metadata for the thrown type from a subroutine.
  case thrownType = 0x0031
  /// Identifies metadata for the try block in a `try-catch` statement.
  case tryBlock = 0x0032
  /// Identifies metadata for a part of a variant record.
  case variantPart = 0x0033
  /// Identifies metadata for a variable.
  case variable = 0x0034
  /// Identifies metadata for a volatile-qualified type.
  case volatileType = 0x0035

  // MARK: New in DWARF v3

  /// Identifies metadata for a DWARF procedure.
  case dwarfProcedure = 0x0036
  /// Identifies metadata for a restrict-qualified type.
  case restrictType = 0x0037
  /// Identifies metadata for a Java interface type.
  case interfaceType = 0x0038
  /// Identifies metadata for a namespace.
  case namespace = 0x0039
  /// Identifies metadata for an imported module.
  case importedModule = 0x003a
  /// Identifies metadata for an unspecified type.
  case unspecifiedType = 0x003b
  /// Identifies metadata for a portion of an object file.
  case partialUnit = 0x003c
  /// Identifies metadata for an imported compilation unit.
  case importedUnit = 0x003d
  /// Identifies metadata for a COBOL "level-88" condition that associates a
  /// data item, called the conditional variable, with a set of one or more
  /// constant values and/or value ranges.
  case condition = 0x003f
  /// Identifies metadata for a UPC shared-qualified type.
  case sharedType = 0x0040

  // MARK: New in DWARF v4

  /// Identifies metadata for a single type.
  case typeUnit = 0x0041
  /// Identifies metadata for an rvalue-reference-qualified type.
  case rvalueReferenceType = 0x0042
  /// Identifies metadata for a template alias.
  case templateAlias = 0x0043

  // MARK: New in DWARF v5

  /// Identifies metadata for a Fortran "coarray" - an array whose elements
  /// are located in different processes rather than in the memory of one
  /// process.
  case coarrayType = 0x0044
  /// Identifies metadata for a generic subrange.  This is useful for arrays of
  /// dynamic size in C and Fortran.
  case genericSubrange = 0x0045
  /// Identifies metadata for a dynamic type.
  case dynamicType = 0x0046
  /// Identifies metadata for an atomic type.
  case atomicType = 0x0047
  /// Identifies metadata for a call site.
  case callSite = 0x0048
  /// Identifies metadata for a parameter at a call site.
  case callSiteParameter = 0x0049
  /// Identifies metadata for the "skeleton" compilation unit in a split DWARF
  /// object file.
  case skeletonUnit = 0x004a
  /// Identifies metadata for an immutable type.
  case immutableType = 0x004b

  // MARK: Vendor extensions

  /// Identifies metadata for a MIPS loop.
  case mipsLoop = 0x4081
  /// Identifies metadata for a format label.
  case formatLabel = 0x4101
  /// Identifies metadata for a function template.
  case functionTemplate = 0x4102
  /// Identifies metadata for a class template.
  case classTemplate = 0x4103
  /// Identifies metadata for a template template parameter.
  case gnuTemplateTemplateParam = 0x4106
  /// Identifies metadata for a template parameter pack.
  case gnuTemplateParameterPack = 0x4107
  /// Identifies metadata for a formal parameter pack.
  case gnuFormalParameterPack = 0x4108
  /// Identifies metadata for a call site.
  case gnuCallSite = 0x4109
  /// Identifies metadata for a call site parameter.
  case gnuCallSiteParameter = 0x410a
  /// Identifies metadata for an Objective-C property.
  case applyProperty = 0x4200
  /// Identifies metadata for an Borland Delphi property.
  case borlandProperty = 0xb000
  /// Identifies metadata for an Borland Delphi property.
  case borlandDelphiString = 0xb001
  /// Identifies metadata for an Borland Delphi dynamic array.
  case borlandDelphiDynamicArray = 0xb002
  /// Identifies metadata for an Borland Delphi set.
  case borlandDelphiSet = 0xb003
  /// Identifies metadata for an Borland Delphi variant.
  case borlandDelphiVariant = 0xb004
}

/// Enumerates the known attributes that can appear on an Objective-C property.
public struct ObjectiveCPropertyAttribute : OptionSet {
  public let rawValue: UInt32

  public init(rawValue: UInt32) {
    self.rawValue = rawValue
  }

  /// Indicates a property has `readonly` access.
  public static let readonly          = ObjectiveCPropertyAttribute(rawValue: 0x01)
  /// Indicates a property has a customized getter name.
  public static let getter            = ObjectiveCPropertyAttribute(rawValue: 0x02)
  /// Indicates a property has `assign` ownership.
  public static let assign            = ObjectiveCPropertyAttribute(rawValue: 0x04)
  /// Indicates a property has `readwrite` access.
  public static let readwrite         = ObjectiveCPropertyAttribute(rawValue: 0x08)
  /// Indicates a property has `retain` ownership.
  public static let retain            = ObjectiveCPropertyAttribute(rawValue: 0x10)
  /// Indicates a property has `copy` ownership.
  public static let copy              = ObjectiveCPropertyAttribute(rawValue: 0x20)
  /// Indicates a property has `nonatomic` accessors.
  public static let nonatomic         = ObjectiveCPropertyAttribute(rawValue: 0x40)
  /// Indicates a property has a customized setter name.
  public static let setter            = ObjectiveCPropertyAttribute(rawValue: 0x80)
  /// Indicates a property has `atomic` accessors.
  public static let atomic            = ObjectiveCPropertyAttribute(rawValue: 0x100)
  /// Indicates a property has `weak` ownership.
  public static let weak              = ObjectiveCPropertyAttribute(rawValue: 0x200)
  /// Indicates a property has `strong` ownership.
  public static let strong            = ObjectiveCPropertyAttribute(rawValue: 0x400)
  /// Indicates a property has `unsafe_unretained` ownership.
  public static let unsafeUnretained = ObjectiveCPropertyAttribute(rawValue: 0x800)
  /// Indicates a property has an explicit nullability annotation.
  public static let nullability       = ObjectiveCPropertyAttribute(rawValue: 0x1000)
  /// Indicates a property is null_resettable.
  public static let nullResettable   = ObjectiveCPropertyAttribute(rawValue: 0x2000)
  /// Indicates a property is a `class` property.
  public static let `class`           = ObjectiveCPropertyAttribute(rawValue: 0x4000)
}

/// Describes how a base type is encoded and to be interpreted by a debugger.
public enum DIAttributeTypeEncoding {
  /// A linear machine address.
  case address
  /// A true or false value.
  case boolean
  /// A complex binary floating-point number.
  case complexFloat
  /// A binary floating-point number.
  case float
  /// A signed binary integer.
  case signed
  /// A signed character.
  case signedChar
  /// An unsigned binary integer.
  case unsigned
  /// An unsigned character.
  case unsignedChar
  /// An imaginary binary floating-point number.
  case imaginaryFloat
  /// A packed decimal number.
  case packedDecimal
  /// A numeric string.
  case numericString
  /// An edited string.
  case edited
  /// A signed fixed-point scaled integer.
  case signedFixed
  /// An unsigned fixed-point scaled integer.
  case unsignedFixed
  /// An IEEE-754R decimal floating-point number.
  case decimalFloat
  /// An ISO/IEC 10646-1:1993 character.
  case utf
  /// An ISO/IEC 10646-1:1993 character in UCS-4 format.
  case ucs
  /// An ISO/IEC 646:1991 character.
  case ascii

  private static let encodingMapping: [DIAttributeTypeEncoding: LLVMDWARFTypeEncoding] = [
    .address:         0x01,
    .boolean:         0x02,
    .complexFloat:    0x03,
    .float:           0x04,
    .signed:          0x05,
    .signedChar:      0x06,
    .unsigned:        0x07,
    .unsignedChar:    0x08,
    .imaginaryFloat:  0x09,
    .packedDecimal:   0x0a,
    .numericString:   0x0b,
    .edited:          0x0c,
    .signedFixed:     0x0d,
    .unsignedFixed:   0x0e,
    .decimalFloat:    0x0f,
    .utf:             0x10,
    .ucs:             0x11,
    .ascii:           0x12,
  ]

  internal var llvm: LLVMDWARFTypeEncoding {
    return DIAttributeTypeEncoding.encodingMapping[self]!
  }
}

/// Enumerates a set of flags that can be applied to metadata nodes to change
/// their interpretation at compile time or attach additional semantic
/// significance at runtime.
public struct DIFlags : OptionSet {
  public let rawValue: LLVMDIFlags.RawValue

  public init(rawValue: LLVMDIFlags.RawValue) {
    self.rawValue = rawValue
  }

  /// Denotes the `private` visibility attribute.
  public static let `private`           = DIFlags(rawValue: LLVMDIFlagPrivate.rawValue)
  /// Denotes the `protected` visibility attribute.
  public static let protected           = DIFlags(rawValue: LLVMDIFlagProtected.rawValue)
  /// Denotes the `public` visibility attribute.
  public static let `public`            = DIFlags(rawValue: LLVMDIFlagPublic.rawValue)
  /// Denotes a forward declaration.
  public static let forwardDeclaration  = DIFlags(rawValue: LLVMDIFlagFwdDecl.rawValue)
  /// Denotes a block object.
  public static let appleBlock          = DIFlags(rawValue: LLVMDIFlagAppleBlock.rawValue)
  /// Denotes a virtual function or dynamic dispatch.
  public static let virtual             = DIFlags(rawValue: LLVMDIFlagVirtual.rawValue)
  /// Denotes a compiler-generated declaration that may not appear in source.
  public static let artificial          = DIFlags(rawValue: LLVMDIFlagArtificial.rawValue)
  /// Denotes an `explicit`-annotated declaration.
  public static let explicit            = DIFlags(rawValue: LLVMDIFlagExplicit.rawValue)
  /// Denotes a prototype declaration.
  public static let prototyped          = DIFlags(rawValue: LLVMDIFlagPrototyped.rawValue)
  /// Denotes an Objective-C class whose definition is visible to the compiler.
  public static let objectiveCClassComplete = DIFlags(rawValue: LLVMDIFlagObjcClassComplete.rawValue)
  /// Denotes a pointer value that is known to point to a C++ or Objective-C
  /// object - usually `self` or `this`.
  public static let objectPointer       = DIFlags(rawValue: LLVMDIFlagObjectPointer.rawValue)
  /// Denotes a vector type.
  public static let vector              = DIFlags(rawValue: LLVMDIFlagVector.rawValue)
  /// Denotes a static member.
  public static let staticMember        = DIFlags(rawValue: LLVMDIFlagStaticMember.rawValue)
  /// Denotes an lvalue reference.
  public static let lValueReference     = DIFlags(rawValue: LLVMDIFlagLValueReference.rawValue)
  /// Denotes an rvalue reference.
  public static let rValueReference     = DIFlags(rawValue: LLVMDIFlagRValueReference.rawValue)
  /// Denotes a class type that is part of a single inheritance class hierarchy.
  /// This flag is required to be set for CodeView compatibility.
  public static let singleInheritance   = DIFlags(rawValue: LLVMDIFlagSingleInheritance.rawValue)
  /// Denotes a class type that is part of a multiple inheritance class
  /// hierarchy.  This flag is required to be set for CodeView compatibility.
  public static let multipleInheritance = DIFlags(rawValue: LLVMDIFlagMultipleInheritance.rawValue)
  /// Denotes a class type whose inheritance involves virtual members.  This
  /// flag is required to be set for CodeView compatibility.
  public static let virtualInheritance  = DIFlags(rawValue: LLVMDIFlagVirtualInheritance.rawValue)
  /// Denotes a class type that introduces virtual members.  This is needed for
  /// the MS C++ ABI does not include all virtual methods from non-primary bases
  /// in the vtable for the most derived class
  public static let introducedVirtual   = DIFlags(rawValue: LLVMDIFlagIntroducedVirtual.rawValue)
  /// Denotes a bitfield type.
  public static let bitField            = DIFlags(rawValue: LLVMDIFlagBitField.rawValue)
  /// Denotes a `noreturn` function.
  public static let noReturn            = DIFlags(rawValue: LLVMDIFlagNoReturn.rawValue)
  /// Denotes a parameter that is passed by value according to the target's
  /// calling convention.
  public static let passByValue         = DIFlags(rawValue: LLVMDIFlagTypePassByValue.rawValue)
  /// Denotes a parameter that is passed by indirect reference according to the
  /// target's calling convention.
  public static let passByReference     = DIFlags(rawValue: LLVMDIFlagTypePassByReference.rawValue)
  /// Denotes a "fixed enum" type e.g. a C++ `enum class`.
  public static let enumClass           = DIFlags(rawValue: LLVMDIFlagEnumClass.rawValue)
  /// Denotes a thunk function.
  public static let thunk               = DIFlags(rawValue: LLVMDIFlagThunk.rawValue)
  /// Denotes a class that has a non-trivial default constructor or is not trivially copiable.
  public static let nonTrivial          = DIFlags(rawValue: LLVMDIFlagNonTrivial.rawValue)
  /// Denotes an indirect virtual base class.
  public static let indirectVirtualBase = DIFlags(rawValue: LLVMDIFlagIndirectVirtualBase.rawValue)
  /// The mask for `public`, `private`, and `protected` accessibility.
  public static let accessibility       = DIFlags(rawValue: LLVMDIFlagAccessibility.rawValue)
  /// The mask for `singleInheritance`, `multipleInheritance`,
  /// and `virtualInheritance`.
  public static let pointerToMemberRep  = DIFlags(rawValue: LLVMDIFlagPtrToMemberRep.rawValue)

  internal var llvm: LLVMDIFlags {
    return LLVMDIFlags(self.rawValue)
  }
}

/// The amount of debug information to emit.
public enum DWARFEmissionKind {
  /// No debug information should be emitted.
  case none
  /// Full debug information should be emitted.
  case full
  /// Onle line tables should be emitted.
  case lineTablesOnly

  private static let emissionMapping: [DWARFEmissionKind: LLVMDWARFEmissionKind] = [
    .none: LLVMDWARFEmissionNone, .full: LLVMDWARFEmissionFull,
    .lineTablesOnly: LLVMDWARFEmissionLineTablesOnly,
  ]

  internal var llvm: LLVMDWARFEmissionKind {
    return DWARFEmissionKind.emissionMapping[self]!
  }
}

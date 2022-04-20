//
//  Comdat.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A `Comdat` object represents a particular COMDAT section in a final
/// generated ELF or COFF object file.  All COMDAT sections are keyed by a
/// unique name that the linker uses, in conjunction with the section's
/// `selectionKind` to determine how to treat conflicting or identical COMDAT
/// sections at link time.
///
/// COMDAT sections are typically used by languages where multiple translation
/// units may define the same symbol, but where
/// "One-Definition-Rule" (ODR)-like concepts apply (perhaps because taking the
/// address of the object referenced by the symbol is defined behavior).  For
/// example, a C++ header file may define an inline function that cannot be
/// successfully inlined at all call sites.  The C++ compiler would then emit
/// a COMDAT section in each object file for the function with the `.any`
/// selection kind and the linker would pick any section it desires before
/// emitting the final object file.
///
/// It is important to be aware of the selection kind of a COMDAT section as
/// these provide strengths and weaknesses at compile-time and link-time.  It
/// is also important to be aware that only certain platforms support mixing
/// identically-keyed COMDAT sections with mixed selection kinds e.g. COFF
/// supports mixing `.any` and `.largest`, WebAssembly only supports `.any`,
/// and Mach-O doesn't support COMDAT sections at all.
///
/// When targeting COFF, there are also restrictions on the way global objects
/// must appear in COMDAT sections.  All global objects and aliases to those
/// global objects must belong to a COMDAT group with the same name and must
/// have greater than local linkage.  Else the local symbol may be renamed in
/// the event of a collision, defeating code-size savings.
///
/// The combined use of COMDATS and sections may yield surprising results.
/// For example:
///
///     let module = Module(name: "COMDATTest")
///     let builder = IRBuilder(module: module)
///
///     let foo = module.comdat(named: "foo")
///     let bar = module.comdat(named: "bar")
///
///     var g1 = builder.addGlobal("g1", initializer: IntType.int8.constant(42))
///     g1.comdat = foo
///     var g2 = builder.addGlobal("g2", initializer: IntType.int8.constant(42))
///     g2.comdat = bar
///
/// From the object file perspective, this requires the creation of two sections
/// with the same name. This is necessary because both globals belong to
/// different COMDAT groups and COMDATs, at the object file level, are
/// represented by sections.
public class Comdat {
  internal let llvm: LLVMComdatRef

  internal init(llvm: LLVMComdatRef) {
    self.llvm = llvm
  }

  /// The selection kind for this COMDAT section.
  public var selectionKind: Comdat.SelectionKind {
    get { return Comdat.SelectionKind(llvm: LLVMGetComdatSelectionKind(self.llvm)) }
    set { LLVMSetComdatSelectionKind(self.llvm, newValue.llvm) }
  }
}

extension Comdat {
  /// A `Comdat.SelectionKind` describes the behavior of the linker when
  /// linking COMDAT sections.
  public enum SelectionKind {
    /// The linker may choose any COMDAT section with a matching key.
    ///
    /// This selection kind is the most relaxed - any section with the same key
    /// but not necessarily identical size or contents can be chosen.  Precisely
    /// which section is chosen is implementation-defined.
    ///
    /// This selection kind is the default for all newly-inserted sections.
    case any
    /// The linker may choose any identically-keyed COMDAT section and requires
    /// all other referenced data to match its selection's referenced data.
    ///
    /// This selection kind requires that the data in each COMDAT section be
    /// identical in length and content.  Inclusion of multiple non-identical
    /// COMDAT sections with the same key is an error.
    ///
    /// For global objects in LLVM, identical contents is defined to mean that
    /// their initializers point to the same global `IRValue`.
    case exactMatch
    /// The linker chooses the identically-keyed COMDAT section with the largest
    /// size, ignoring content.
    case largest
    /// The COMDAT section with this key is unique.
    ///
    /// This selection requires that no other COMDAT section have the same key
    /// as this section, making the choice of selection unambiguous.  Inclusion
    /// of any other COMDAT section with the same key is an error.
    case noDuplicates
    /// The linker may choose any identically-keyed COMDAT section and requires
    /// all other sections to have the same size as its selection.
    case sameSize

    internal init(llvm: LLVMComdatSelectionKind) {
      switch llvm {
      case LLVMAnyComdatSelectionKind: self = .any
      case LLVMExactMatchComdatSelectionKind: self = .exactMatch
      case LLVMLargestComdatSelectionKind: self = .largest
//      case LLVMNoDuplicatesComdatSelectionKind: self = .noDuplicates
      case LLVMSameSizeComdatSelectionKind: self = .sameSize
      default: fatalError("unknown comdat selection kind \(llvm)")
      }
    }

    private static let comdatMapping: [Comdat.SelectionKind: LLVMComdatSelectionKind] = [
      .any: LLVMAnyComdatSelectionKind,
      .exactMatch: LLVMExactMatchComdatSelectionKind,
      .largest: LLVMLargestComdatSelectionKind,
//      .noDuplicates: LLVMNoDuplicatesComdatSelectionKind,
      .sameSize: LLVMSameSizeComdatSelectionKind,
    ]

    fileprivate var llvm: LLVMComdatSelectionKind {
      return SelectionKind.comdatMapping[self]!
    }
  }
}

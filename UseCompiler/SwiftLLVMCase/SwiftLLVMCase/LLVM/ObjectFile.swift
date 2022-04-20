//
//  ObjectFile.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// Enumerates the possible failures that can be thrown initializing
/// a MemoryBuffer.
public enum BinaryFileError: Error {
  /// The MemoryBuffer failed to be initialized for a specific reason.
  case couldNotCreate(String)
}

/// A `BinaryFile` is a (mostly) architecture-independent representation of an
/// in-memory image file.
public class BinaryFile {
  let llvm: LLVMBinaryRef

  /// The backing buffer for this binary file.
  public let buffer: MemoryBuffer

  /// The kind of this binary file.
  public let kind: Kind

  /// The kinds of binary files known to LLVM.
  public enum Kind {
    /// A static library archive file.
    case archive
    /// A universal Mach-O binary with multiple component object files for
    /// different architectures.
    case machOUniversalBinary
    /// A COFF imports table file.
    case coffImportFile
    /// LLVM IR.
    case ir
    /// A Windows resource file.
    case winRes
    /// A COFF file.
    case coff
    /// A 32-bit little-endian ELF binary.
    case elf32L
    /// A 32-bit big-endian ELF binary.
    case elf32B
    /// A 64-bit little-endian ELF binary.
    case elf64L
    /// A 64-bit big-endian ELF binary.
    case elf64B
    /// A 32-bit little-endian Mach-O binary.
    case machO32L
    /// A 32-bit big-endian Mach-O binary.
    case machO32B
    /// A 64-bit little-endian Mach-O binary.
    case machO64L
    /// A 64-bit big-endian Mach-O binary.
    case machO64B
    /// A web assembly binary.
    case wasm

    internal init(llvm: LLVMBinaryType) {
      switch llvm {
      case LLVMBinaryTypeArchive: self = .archive
      case LLVMBinaryTypeMachOUniversalBinary: self = .machOUniversalBinary
      case LLVMBinaryTypeCOFFImportFile: self = .coff
      case LLVMBinaryTypeIR: self = .ir
      case LLVMBinaryTypeWinRes: self = .winRes
      case LLVMBinaryTypeCOFF: self = .coff
      case LLVMBinaryTypeELF32L: self = .elf32L
      case LLVMBinaryTypeELF32B: self = .elf32B
      case LLVMBinaryTypeELF64L: self = .elf64L
      case LLVMBinaryTypeELF64B: self = .elf64B
      case LLVMBinaryTypeMachO32L: self = .machO32L
      case LLVMBinaryTypeMachO32B: self = .machO32B
      case LLVMBinaryTypeMachO64L: self = .machO64L
      case LLVMBinaryTypeMachO64B: self = .machO64B
      case LLVMBinaryTypeWasm: self = .wasm
      default: fatalError("unknown binary type \(llvm)")
      }
    }
  }

  init(llvm: LLVMBinaryRef, buffer: MemoryBuffer) {
    self.llvm = llvm
    self.kind = Kind(llvm: LLVMBinaryGetType(llvm))
    self.buffer = buffer
  }

  /// Creates a Binary File with the contents of a provided memory buffer.
  ///
  /// - Parameters:
  ///   - memoryBuffer: A memory buffer containing a valid binary file.
  ///   - context: The context to allocate the given binary in.
  /// - throws: `BinaryFileError` if there was an error on creation.
  public init(memoryBuffer: MemoryBuffer, in context: Context = .global) throws {
    var error: UnsafeMutablePointer<Int8>?
    self.llvm = LLVMCreateBinary(memoryBuffer.llvm, context.llvm, &error)
    if let error = error {
      defer { LLVMDisposeMessage(error) }
      throw BinaryFileError.couldNotCreate(String(cString: error))
    }
    self.kind = Kind(llvm: LLVMBinaryGetType(self.llvm))
    self.buffer = memoryBuffer
  }

  /// Creates an `ObjectFile` with the contents of the object file at
  /// the provided path.
  /// - parameter path: The absolute file path on your filesystem.
  /// - throws: `MemoryBufferError` or `BinaryFileError` if there was an error
  ///           on creation
  public convenience init(path: String) throws {
    let memoryBuffer = try MemoryBuffer(contentsOf: path)
    try self.init(memoryBuffer: memoryBuffer)
  }


  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeBinary(llvm)
  }
}

/// An in-memory representation of a format-independent object file.
public class ObjectFile: BinaryFile {
  override init(llvm: LLVMBinaryRef, buffer: MemoryBuffer) {
    super.init(llvm: llvm, buffer: buffer)
    precondition(self.kind != .machOUniversalBinary,
                 "File format is not an object file; use MachOUniversalBinaryFile instead")
  }

  /// Creates an object file with the contents of a provided memory buffer.
  ///
  /// - Parameters:
  ///   - memoryBuffer: A memory buffer containing a valid object file.
  ///   - context: The context to allocate the given binary in.
  /// - throws: `BinaryFileError` if there was an error on creation.
  public override init(memoryBuffer: MemoryBuffer, in context: Context = .global) throws {
    try super.init(memoryBuffer: memoryBuffer, in: context)
    precondition(self.kind != .machOUniversalBinary,
                 "File format is not an object file; use MachOUniversalBinaryFile instead")
  }

  /// Returns a sequence of all the sections in this object file.
  public var sections: SectionSequence {
    return SectionSequence(llvm: LLVMObjectFileCopySectionIterator(llvm), object: self)
  }

  /// Returns a sequence of all the symbols in this object file.
  public var symbols: SymbolSequence {
    return SymbolSequence(llvm: LLVMObjectFileCopySymbolIterator(llvm), object: self)
  }
}

/// An in-memory representation of a Mach-O universal binary file.
public final class MachOUniversalBinaryFile: BinaryFile {
  /// Creates an `MachOUniversalBinaryFile` with the contents of the object file at
  /// the provided path.
  /// - parameter path: The absolute file path on your filesystem.
  /// - throws: `MemoryBufferError` or `BinaryFileError` if there was an error
  ///           on creation
  public convenience init(path: String) throws {
    let memoryBuffer = try MemoryBuffer(contentsOf: path)
    try self.init(memoryBuffer: memoryBuffer)
  }

  /// Creates a Mach-O universal binary file with the contents of a provided
  /// memory buffer.
  ///
  /// - Parameters:
  ///   - memoryBuffer: A memory buffer containing a valid universal Mach-O file.
  ///   - context: The context to allocate the given binary in.
  /// - throws: `BinaryFileError` if there was an error on creation.
  public override init(memoryBuffer: MemoryBuffer, in context: Context = .global) throws {
    try super.init(memoryBuffer: memoryBuffer, in: context)
    guard self.kind == .machOUniversalBinary else {
      throw BinaryFileError.couldNotCreate("File is not a Mach-O universal binary")
    }
  }

  /// Retrieves the object file for a specific architecture, if it exists.
  ///
  /// - Parameters:
  ///   - architecture: The architecture of a Mach-O file contained in this
  ///                   universal binary file.
  /// - Returns: An object file for the given architecture if it exists.
  /// - throws: `BinaryFileError` if there was an error on creation.
  public func objectFile(for architecture: Triple.Architecture) throws -> Slice {
    var error: UnsafeMutablePointer<Int8>?
    let archName = architecture.rawValue
    let archFile: LLVMBinaryRef = LLVMMachOUniversalBinaryCopyObjectForArch(self.llvm, archName, archName.count, &error)
    if let error = error {
      defer { LLVMDisposeMessage(error) }
      throw BinaryFileError.couldNotCreate(String(cString: error))
    }
    let buffer = MemoryBuffer(llvm: LLVMBinaryCopyMemoryBuffer(archFile))
    return Slice(parent: self, llvm: archFile, buffer: buffer)
  }

  /// Represents an architecture-specific slice of a Mach-O universal binary
  /// file.
  public final class Slice: ObjectFile {
    // Maintain a strong reference to our parent binary so the backing buffer
    // doesn't disappear on us.
    private let parent: MachOUniversalBinaryFile

    fileprivate init(parent: MachOUniversalBinaryFile, llvm: LLVMBinaryRef, buffer: MemoryBuffer) {
      self.parent = parent
      super.init(llvm: llvm, buffer: buffer)
    }

    private override init(llvm: LLVMBinaryRef, buffer: MemoryBuffer) {
      fatalError()
    }

    private override init(memoryBuffer: MemoryBuffer, in context: Context = .global) throws {
      fatalError()
    }
  }
}

/// A Section represents one of the binary sections in an object file.
public struct Section {
  /// The section's declared name.
  public let name: String
  /// The size of the contents of the section.
  public let size: Int
  /// The raw contents of the section.
  public let contents: UnsafeBufferPointer<CChar>
  /// The address of the section in the object file.
  public let address: Int

  /// The parent sequence of this section.
  private let sectionIterator: LLVMSectionIteratorRef

  internal init(fromIterator si: LLVMSectionIteratorRef) {
    self.sectionIterator = si
    self.name = String(cString: LLVMGetSectionName(si))
    self.size = Int(LLVMGetSectionSize(si))
    self.contents = UnsafeBufferPointer<CChar>(start: LLVMGetSectionContents(si), count: self.size)
    self.address = Int(LLVMGetSectionAddress(si))
  }

  /// Returns a sequence of all the relocations in this object file.
  public var relocations: RelocationSequence {
    return RelocationSequence(
      llvm: LLVMGetRelocations(self.sectionIterator),
      sectionIterator: self.sectionIterator
    )
  }

  /// Returns whether a symbol matching the given `Symbol` can be found in
  /// this section.
  public func contains(symbol: Symbol) -> Bool {
    return LLVMGetSectionContainsSymbol(self.sectionIterator, symbol.symbolIterator) != 0
  }
}

/// A sequence for iterating over the sections in an object file.
public class SectionSequence: Sequence {
  let llvm: LLVMSectionIteratorRef?
  let objectFile: ObjectFile

  init(llvm: LLVMSectionIteratorRef?, object: ObjectFile) {
    self.llvm = llvm
    self.objectFile = object
  }

  /// Makes an iterator that iterates over the sections in an object file.
  public func makeIterator() -> AnyIterator<Section> {
    return AnyIterator {
      guard let it = self.llvm else {
        return nil
      }

      if LLVMObjectFileIsSectionIteratorAtEnd(self.objectFile.llvm, it) != 0 {
        return nil
      }
      defer { LLVMMoveToNextSection(it) }
      return Section(fromIterator: it)
    }
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeSectionIterator(llvm)
  }
}

/// A symbol is a top-level addressable entity in an object file.
public struct Symbol {
  /// The symbol name.
  public let name: String
  /// The size of the data in the symbol.
  public let size: Int
  /// The address of the symbol in the object file.
  public let address: Int

  /// The parent sequence of this symbol.
  fileprivate let symbolIterator: LLVMSymbolIteratorRef

  internal init(fromIterator si: LLVMSymbolIteratorRef) {
    self.name = String(cString: LLVMGetSymbolName(si))
    self.size = Int(LLVMGetSymbolSize(si))
    self.address = Int(LLVMGetSymbolAddress(si))
    self.symbolIterator = si
  }
}

/// A Relocation represents the contents of a relocated symbol in the dynamic
/// linker.
public struct Relocation {
  /// Retrieves the type of this relocation.
  ///
  /// The value of this integer is dependent upon the type of object file
  /// it was retrieved from.
  public let type: Int
  /// The offset the relocated symbol resides at.
  public let offset: Int
  /// The symbol that is the subject of the relocation.
  public let symbol: Symbol
  /// Get a string that represents the type of this relocation for display
  /// purposes.
  public let typeName: String

  internal init(fromIterator ri: LLVMRelocationIteratorRef) {
    self.type = Int(LLVMGetRelocationType(ri))
    self.offset = Int(LLVMGetRelocationOffset(ri))
    self.symbol = Symbol(fromIterator: LLVMGetRelocationSymbol(ri))
    self.typeName = String(cString: LLVMGetRelocationTypeName(ri))
  }
}

/// A sequence for iterating over the relocations in an object file.
public class RelocationSequence: Sequence {
  let llvm: LLVMRelocationIteratorRef
  let sectionIterator: LLVMSectionIteratorRef

  init(llvm: LLVMRelocationIteratorRef, sectionIterator: LLVMSectionIteratorRef) {
    self.llvm = llvm
    self.sectionIterator = sectionIterator
  }

  /// Creates an iterator that will iterate over all relocations in an object
  /// file.
  public func makeIterator() -> AnyIterator<Relocation> {
    return AnyIterator {
      if LLVMIsRelocationIteratorAtEnd(self.sectionIterator, self.llvm) != 0 {
        return nil
      }
      defer { LLVMMoveToNextRelocation(self.llvm) }
      return Relocation(fromIterator: self.llvm)
    }
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeSectionIterator(llvm)
  }
}

/// A sequence for iterating over the symbols in an object file.
public class SymbolSequence: Sequence {
  let llvm: LLVMSymbolIteratorRef?
  let object: ObjectFile

  init(llvm: LLVMSymbolIteratorRef?, object: ObjectFile) {
    self.llvm = llvm
    self.object = object
  }

  /// Creates an iterator that will iterate over all symbols in an object
  /// file.
  public func makeIterator() -> AnyIterator<Symbol> {
    return AnyIterator {
      guard let it = self.llvm else {
        return nil
      }
      if LLVMObjectFileIsSymbolIteratorAtEnd(self.object.llvm, it) != 0 {
        return nil
      }
      defer { LLVMMoveToNextSymbol(it) }
      return Symbol(fromIterator: it)
    }
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeSymbolIterator(llvm)
  }
}

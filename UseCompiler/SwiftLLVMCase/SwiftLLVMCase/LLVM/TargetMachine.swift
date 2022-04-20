//
//  TargetMachine.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// The supported types of files codegen can produce.
public enum CodegenFileType {
  /// An object file (.o).
  case object
  /// An assembly file (.asm).
  case assembly
  /// An LLVM Bitcode file (.bc).
  case bitCode

  /// Returns the underlying `LLVMCodeGenFileType` associated with this file
  /// type.
  public func asLLVM() -> LLVMCodeGenFileType {
    switch self {
    case .object: return LLVMObjectFile
    case .assembly: return LLVMAssemblyFile
    case .bitCode: fatalError("not handled here")
    }
  }

  /// The name of the file type.
  internal var name: String {
    switch self {
    case .object:
      return "object"
    case .assembly:
      return "assembly"
    case .bitCode:
      return "bitcode"
    }
  }
}

/// Represents one of a few errors that can be thrown by a `TargetMachine`
public enum TargetMachineError: Error, CustomStringConvertible {
  /// The target machine failed to emit the specified file type.
  /// This case also contains the message emitted by LLVM explaining the
  /// failure.
  case couldNotEmit(String, CodegenFileType)

  /// The target machine failed to emit the bitcode for this module.
  case couldNotEmitBitCode

  /// The specified target triple was invalid.
  case invalidTriple(String)

  /// The Target is could not be created.
  /// This case also contains the message emitted by LLVM explaining the
  /// failure.
  case couldNotCreateTarget(String, String)

  public var description: String {
    switch self {
    case .couldNotCreateTarget(let triple, let message):
      return "could not create target for '\(triple)': \(message)"
    case .invalidTriple(let target):
      return "invalid target triple '\(target)'"
    case .couldNotEmit(let message, let fileType):
      return "could not emit \(fileType.name) file: \(message)"
    case .couldNotEmitBitCode:
      return "could not emit bitcode for an unknown reason"
    }
  }
}

/// A `Target` object represents an object that encapsulates information about
/// a host architecture, vendor, ABI, etc.
public class Target {
  internal let llvm: LLVMTargetRef

  /// Creates a `Target` object from an LLVM target object.
  public init(llvm: LLVMTargetRef) {
    self.llvm = llvm
  }

  /// Returns `true` if this target supports just-in-time compilation.
  ///
  /// Attempting to create a JIT for a `Target` where this predicate is false
  /// may lead to program instability or corruption.
  public var hasJIT: Bool {
    return LLVMTargetHasJIT(self.llvm) != 0
  }


  /// Returns `true` if this target has a `TargetMachine` associated with it.
  ///
  /// Target machines are registered by the corresponding initializer functions
  /// for each target.  LLVMSwift will ensure that these functions are invoked
  /// when a TargetMachine is created, but not before.
  public var hasTargetMachine: Bool {
    return LLVMTargetHasTargetMachine(self.llvm) != 0
  }

  /// Returns `true` if this target has an ASM backend.
  ///
  /// ASM backends are registered by the corresponding iniailizer functions for
  /// each target.  LLVMSwift will ensure that these functions are invoked
  /// when a TargetMachine is created, but not before.
  public var hasASMBackend: Bool {
    return LLVMTargetHasAsmBackend(self.llvm) != 0
  }

  /// The name of this target.
  public var name: String {
    guard let str = LLVMGetTargetName(self.llvm) else {
      return ""
    }
    return String(validatingUTF8: UnsafePointer<CChar>(str)) ?? ""
  }

  /// The description of this target.
  public var targetDescription: String {
    guard let str = LLVMGetTargetDescription(self.llvm) else {
      return ""
    }
    return String(validatingUTF8: UnsafePointer<CChar>(str)) ?? ""
  }

  /// Returns a sequence of all targets in the global list of targets.
  public static var allTargets: AnySequence<Target> {
    var current = firstTarget
    return AnySequence<Target> {
      return AnyIterator<Target> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Returns the first target in the global target list, if it exists.
  public static var firstTarget: Target? {
    guard let targetRef = LLVMGetFirstTarget() else { return nil }
    return Target(llvm: targetRef)
  }

  /// Returns the target following this target in the global target list,
  /// if it exists.
  public func next() -> Target? {
    guard let targetRef = LLVMGetNextTarget(self.llvm) else { return nil }
    return Target(llvm: targetRef)
  }
}

/// A `TargetMachine` object represents an object that encapsulates information
/// about a particular machine (i.e. CPU type) associated with a target
/// environment.
public class TargetMachine {
  internal let llvm: LLVMTargetMachineRef

  /// The target information associated with this target machine.
  public let target: Target

  /// The data layout semantics associated with this target machine.
  public let dataLayout: TargetData

  /// The target triple for this target machine.
  public let triple: Triple

  /// The CPU associated with this target machine.
  public var cpu: String {
    guard let str = LLVMGetTargetMachineCPU(self.llvm) else {
      return ""
    }
    defer { LLVMDisposeMessage(str) }
    return String(validatingUTF8: UnsafePointer<CChar>(str)) ?? ""
  }

  /// The feature string associated with this target machine.
  public var features: String {
    guard let str = LLVMGetTargetMachineFeatureString(self.llvm) else {
      return ""
    }
    defer { LLVMDisposeMessage(str) }
    return String(validatingUTF8: UnsafePointer<CChar>(str)) ?? ""
  }

  internal var ownsContext: Bool = true

  /// Creates a Target Machine with information about its target environment.
  ///
  /// - parameter triple: An optional target triple to target.  If this is not
  ///   provided the target triple of the host machine will be assumed.
  /// - parameter cpu: An optional CPU type to target.  If this is not provided
  ///   the host CPU will be inferred.
  /// - parameter features: An optional string containing the features a
  ///   particular target provides.
  /// - parameter optLevel: The optimization level for generated code.  If no
  ///   value is provided, the default level of optimization is assumed.
  /// - parameter relocations: The relocation model of the target environment.
  ///   If no mode is provided, the default model for the target architecture is
  ///   assumed.
  /// - parameter codeModel: The kind of code to produce for this target.  If
  ///   no model is provided, the default model for the target architecture is
  ///   assumed.
  public init(triple: Triple = .default, cpu: String = "", features: String = "",
              optLevel: CodeGenOptLevel = .default, relocations: RelocationModel = .default,
              codeModel: CodeModel = .default) throws {

    // Ensure the LLVM initializer is called when the first module is created
    initializeLLVM()

    self.triple = triple
    var target: LLVMTargetRef?
    var error: UnsafeMutablePointer<Int8>?
    LLVMGetTargetFromTriple(self.triple.data, &target, &error)
    if let error = error {
      defer { LLVMDisposeMessage(error) }
      throw TargetMachineError.couldNotCreateTarget(self.triple.data,
                                                    String(cString: error))
    }
    self.target = Target(llvm: target!)
    self.llvm = LLVMCreateTargetMachine(target!, self.triple.data, cpu, features,
                                        optLevel.asLLVM(),
                                        relocations.asLLVM(),
                                        codeModel.asLLVM())
    self.dataLayout = TargetData(llvm: LLVMCreateTargetDataLayout(self.llvm))
  }

  /// Emits an LLVM Bitcode, ASM, or object file for the given module to the
  /// provided filename.
  ///
  /// Failure during any part of the compilation process or the process of
  /// writing the results to disk will result in a `TargetMachineError` being
  /// thrown describing the error in detail.
  ///
  /// - parameter module: The module whose contents will be codegened.
  /// - parameter type: The type of codegen to perform on the given module.
  /// - parameter path: The path to write the resulting file.
  public func emitToFile(module: Module, type: CodegenFileType, path: String) throws {
    if case .bitCode = type {
      if LLVMWriteBitcodeToFile(module.llvm, path) != 0 {
        throw TargetMachineError.couldNotEmitBitCode
      }
      return
    }
    var err: UnsafeMutablePointer<Int8>?
    let status = path.withCString { cStr -> LLVMBool in
      let mutable = strdup(cStr)
      defer { free(mutable) }
      return LLVMTargetMachineEmitToFile(llvm, module.llvm, mutable, type.asLLVM(), &err)
    }
    if let err = err, status != 0 {
      defer { LLVMDisposeMessage(err) }
      throw TargetMachineError.couldNotEmit(String(cString: err), type)
    }
  }

  /// Emits an LLVM Bitcode, ASM, or object file for the given module to a new
  /// `MemoryBuffer` containing the contents.
  ///
  /// Failure during any part of the compilation process or the process of
  /// writing the results to disk will result in a `TargetMachineError` being
  /// thrown describing the error in detail.
  ///
  /// - parameter module: The module whose contents will be codegened.
  /// - parameter type: The type of codegen to perform on the given module.
  public func emitToMemoryBuffer(module: Module, type: CodegenFileType) throws -> MemoryBuffer {
    if case .bitCode = type {
      guard let buffer = LLVMWriteBitcodeToMemoryBuffer(module.llvm) else {
        throw TargetMachineError.couldNotEmitBitCode
      }
      return MemoryBuffer(llvm: buffer)
    }
    var buf: LLVMMemoryBufferRef?
    var error: UnsafeMutablePointer<Int8>?
    LLVMTargetMachineEmitToMemoryBuffer(llvm, module.llvm,
                                        type.asLLVM(), &error, &buf)
    if let error = error {
      defer { free(error) }
      throw TargetMachineError.couldNotEmit(String(cString: error), type)
    }
    guard let llvm = buf else {
      throw TargetMachineError.couldNotEmit("unknown reason", type)
    }
    return MemoryBuffer(llvm: llvm)
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    guard self.ownsContext else {
      return
    }
    LLVMDisposeTargetMachine(llvm)
  }
}

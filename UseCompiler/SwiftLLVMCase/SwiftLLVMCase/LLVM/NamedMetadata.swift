//
//  NamedMetadata.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A `NamedMetadata` object represents a module-level metadata value identified
/// by a user-provided name.  Named metadata is generated lazily when operands
/// are attached.
public class NamedMetadata {
  /// The module with which this named metadata is associated.
  public let module: Module
  /// The name associated with this named metadata.
  public let name: String

  private let llvm: LLVMNamedMDNodeRef

  init(module: Module, llvm: LLVMNamedMDNodeRef) {
    self.module = module
    self.llvm = llvm
    var nameLen = 0
    guard let rawName = LLVMGetNamedMetadataName(llvm, &nameLen) else {
      fatalError("Could not retrieve name for named MD node?")
    }
    self.name = String(cString: rawName)
  }

  /// Retrieves the previous alias in the module, if there is one.
  public func previous() -> NamedMetadata? {
    guard let previous = LLVMGetPreviousNamedMetadata(llvm) else { return nil }
    return NamedMetadata(module: self.module, llvm: previous)
  }

  /// Retrieves the next alias in the module, if there is one.
  public func next() -> NamedMetadata? {
    guard let next = LLVMGetNextNamedMetadata(llvm) else { return nil }
    return NamedMetadata(module: self.module,llvm: next)
  }

  /// Computes the operands of a named metadata node.
  public var operands: [IRMetadata] {
    let count = Int(LLVMGetNamedMetadataNumOperands(self.module.llvm, name))
    let operands = UnsafeMutablePointer<LLVMValueRef?>.allocate(capacity: count)
    LLVMGetNamedMetadataOperands(self.module.llvm, name, operands)

    var ops = [IRMetadata]()
    ops.reserveCapacity(count)
    for i in 0..<count {
      guard let rawOperand = operands[i] else {
        continue
      }
      guard let metadata = LLVMValueAsMetadata(rawOperand) else {
        continue
      }
      ops.append(AnyMetadata(llvm: metadata))
    }
    return ops
  }

  /// Appends a metadata node as an operand.
  public func addOperand(_ op: IRMetadata) {
    let metaVal = LLVMMetadataAsValue(self.module.context.llvm, op.asMetadata())
    LLVMAddNamedMetadataOperand(self.module.llvm, self.name, metaVal)
  }
}

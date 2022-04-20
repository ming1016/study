//
//  Instruction.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An `IRInstruction` is a value that directly represents an instruction and
/// in particular the result of the execution of that instruction.
public protocol IRInstruction: IRValue { }

extension IRInstruction {
  /// Retrieves the opcode associated with this `Instruction`.
  public var opCode: OpCode {
    return OpCode(rawValue: LLVMGetInstructionOpcode(self.asLLVM()))
  }

  /// Retrieves the current debug location of this instruction.
  public var debugLocation: DebugLocation? {
    get { return LLVMInstructionGetDebugLoc(self.asLLVM()).map(DebugLocation.init(llvm:)) }
    set { LLVMInstructionSetDebugLoc(self.asLLVM(), newValue?.asMetadata()) }
  }

  /// Obtain the instruction that occurs before this one, if it exists.
  public func previous() -> Instruction? {
    guard let val = LLVMGetPreviousInstruction(self.asLLVM()) else { return nil }
    return Instruction(llvm: val)
  }

  /// Obtain the instruction that occurs after this one, if it exists.
  public func next() -> Instruction? {
    guard let val = LLVMGetNextInstruction(self.asLLVM()) else { return nil }
    return Instruction(llvm: val)
  }

  /// Retrieves the parent basic block that contains this instruction, if it
  /// exists.
  public var parentBlock: BasicBlock? {
    guard let parent = LLVMGetInstructionParent(self.asLLVM()) else { return nil }
    return BasicBlock(llvm: parent)
  }

  /// Retrieves the first use of this instruction.
  public var firstUse: Use? {
    guard let use = LLVMGetFirstUse(self.asLLVM()) else { return nil }
    return Use(llvm: use)
  }

  /// Retrieves the sequence of instructions that use the value from this
  /// instruction.
  public var uses: AnySequence<Use> {
    var current = firstUse
    return AnySequence<Use> {
      return AnyIterator<Use> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Removes this instruction from a basic block but keeps it alive.
  ///
  /// - note: To ensure correct removal of the instruction, you must invalidate
  ///         any remaining references to its result values.
  public func removeFromParent() {
    LLVMInstructionRemoveFromParent(self.asLLVM())
  }
}


/// An `Instruction` represents an instruction residing in a basic block.
public struct Instruction: IRInstruction {
  internal let llvm: LLVMValueRef

  /// Creates an `Intruction` from an `LLVMValueRef` object.
  public init(llvm: LLVMValueRef) {
    self.llvm = llvm
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }

  /// Create a copy of 'this' instruction that is identical in all ways except
  /// the following:
  ///
  ///  - The instruction has no parent
  ///  - The instruction has no name
  public func clone() -> Instruction {
    return Instruction(llvm: LLVMInstructionClone(self.llvm))
  }
}

/// A `TerminatorInstruction` represents an instruction that terminates a
/// basic block.
public struct TerminatorInstruction: IRInstruction {
  internal let llvm: LLVMValueRef

  /// Creates a `TerminatorInstruction` from an `LLVMValueRef` object.
  public init(llvm: LLVMValueRef) {
    self.llvm = llvm
  }

  /// Retrieves the number of successors of this terminator instruction.
  public var successorCount: Int {
    return Int(LLVMGetNumSuccessors(llvm))
  }

  /// Returns the successor block at the specified index, if it exists.
  public func getSuccessor(at idx: Int) -> BasicBlock? {
    guard let succ = LLVMGetSuccessor(llvm, UInt32(idx)) else { return nil }
    return BasicBlock(llvm: succ)
  }

  /// Updates the successor block at the specified index.
  public func setSuccessor(at idx: Int, to bb: BasicBlock) {
    LLVMSetSuccessor(llvm, UInt32(idx), bb.asLLVM())
  }

  public func asLLVM() -> LLVMValueRef {
    return self.llvm
  }
}

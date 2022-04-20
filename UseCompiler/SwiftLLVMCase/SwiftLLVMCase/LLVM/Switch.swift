//
//  Switch.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A `Switch` represents a `switch` instruction.  A `switch` instruction
/// defines a jump table of values and destination basic blocks to pass the flow
/// of control to if a condition value matches.  If no match is made, control
/// flow passes to the default basic block.
public struct Switch: IRInstruction {
  internal let llvm: LLVMValueRef

  /// Inserts a case with the given value and destination basic block in the
  /// jump table of this `switch` instruction.
  ///
  /// - parameter value: The value that acts as the selector for this case.
  /// - parameter block: The destination block for the flow of control if this
  ///   case is matched.
  public func addCase(_ value: IRValue, _ block: BasicBlock) {
    LLVMAddCase(llvm, value.asLLVM(), block.asLLVM())
  }

  /// Retrieves the basic block the flow of control reaches should a
  /// value not match any of the cases in the branch table.
  var defaultDestination: BasicBlock {
    return BasicBlock(llvm: LLVMGetSwitchDefaultDest(self.llvm))
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }
}


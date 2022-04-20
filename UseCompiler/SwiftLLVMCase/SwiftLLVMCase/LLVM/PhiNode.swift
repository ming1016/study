//
//  PhiNode.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A `PhiNode` object represents a PHI node.
///
/// Because all instructions in LLVM IR are in SSA (Single Static Assignment)
/// form, a PHI node is necessary when the value of a variable assignment
/// depends on the path the flow of control takes through the program.  For
/// example:
///
/// ```swift
/// var a = 1
/// if c == 42 {
///   a = 2
/// }
/// let b = a
/// ```
///
/// The value of `b` in this program depends on the value of the condition
/// involving the variable `c`.  Because `b` must be assigned to once, a PHI
/// node is created and the program effectively is transformed into the
/// following:
///
/// ```swift
/// let aNoCond = 1
/// if c == 42 {
///   let aCondTrue = 2
/// }
/// let b = PHI(aNoCond, aCondTrue)
/// ```
///
/// If the flow of control reaches `aCondTrue`, the value of `b` is `2`, else it
/// is `1` and SSA semantics are preserved.
public struct PhiNode: IRInstruction {
  internal let llvm: LLVMValueRef

  /// Adds a list of incoming value and their associated basic blocks to the end
  /// of the list of incoming values for this PHI node.
  ///
  /// - parameter valueMap: A list of incoming values and their associated basic
  ///   blocks.
  public func addIncoming(_ valueMap: [(IRValue, BasicBlock)]) {
    var values = valueMap.map { $0.0.asLLVM() as Optional }
    var blocks = valueMap.map { $0.1.asLLVM() as Optional }

    values.withUnsafeMutableBufferPointer { valueBuf in
      blocks.withUnsafeMutableBufferPointer { blockBuf in
        LLVMAddIncoming(llvm,
                        valueBuf.baseAddress,
                        blockBuf.baseAddress,
                        UInt32(valueMap.count))
      }
    }
  }

  /// Obtain the incoming values and their associated basic blocks for this PHI
  /// node.
  public var incoming: [(IRValue, BasicBlock)] {
    let count = Int(LLVMCountIncoming(llvm))
    var values = [(IRValue, BasicBlock)]()
    for i in 0..<count {
      guard let value = incomingValue(at: i),
        let block = incomingBlock(at: i) else { continue }
      values.append((value, block))
    }
    return values
  }

  /// Retrieves the incoming value for the given index for this PHI node, if it
  /// exists.
  ///
  /// - parameter index: The index of the incoming value to retrieve.
  ///
  /// - returns: A value representing the incoming value to this PHI node at
  ///   the given index, if it exists.
  public func incomingValue(at index: Int) -> IRValue? {
    return LLVMGetIncomingValue(llvm, UInt32(index))
  }

  /// Retrieves the incoming basic block for the given index for this PHI node,
  /// if it exists.
  ///
  /// - parameter index: The index of the incoming basic block to retrieve.
  ///
  /// - returns: A value representing the incoming basic block to this PHI node
  ///   at the given index, if it exists.
  public func incomingBlock(at index: Int) -> BasicBlock? {
    guard let blockRef = LLVMGetIncomingBlock(llvm, UInt32(index)) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }
}

//
//  BasicBlock.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A `BasicBlock` represents a basic block in an LLVM IR program.  A basic
/// block contains a sequence of instructions, a pointer to its parent block and
/// its follower block, and an optional label that gives the basic block an
/// entry in the symbol table.  Because of this label, the type of every basic
/// block is `LabelType`.
///
/// A basic block can be thought of as a sequence of instructions, and indeed
/// its member instructions may be iterated over with a `for-in` loop.  A well-
/// formed basic block has as its last instruction a "terminator" that produces
/// a transfer of control flow and possibly yields a value.  All other
/// instructions in the middle of the basic block may not be "terminator"
/// instructions.  Basic blocks are not required to be well-formed until
/// code generation is complete.
///
/// Creating a Basic Block
/// ======================
///
/// By default, the initializer for a basic block merely creates the block but
/// does not associate it with a function.
///
///     let module = Module(name: "Example")
///     let fun = builder.addFunction("example",
///                                   type: FunctionType([], VoidType()))
///
///     // This basic block is "floating" outside of a function.
///     let floatingBB = BasicBlock(name: "floating")
///     // Until we associate it with a function by calling `Function.append(_:)`.
///     fun.append(floatingBB)
///
/// A basic block may be created and automatically inserted at the end of a
/// function by calling `Function.appendBasicBlock(named:in:)`.
///
///     let module = Module(name: "Example")
///     let fun = builder.addFunction("example",
///                                   type: FunctionType([], VoidType()))
///
///     // This basic block is "attached" to the example function.
///     let attachedBB = fun.appendBasicBlock(named: "attached")
///
/// The Address of a Basic Block
/// ============================
///
/// Basic blocks (except the entry block) may have their labels appear in the
/// symbol table.  Naturally, these labels are associated with address values
/// in the final object file.  The value of that address may be accessed for the
/// purpose of an indirect call or a direct comparisson by calling
/// `Function.address(of:)` and providing one of the function's child blocks as
/// an argument.  Providing any other basic block outside of the function as an
/// argument value is undefined.
///
/// The Entry Block
/// ===============
///
/// The first basic block (the entry block) in a `Function` is special:
///
/// - The entry block is immediately executed when the flow of control enters
///   its parent function.
/// - The entry block is not allowed to have predecessor basic blocks
///   (i.e. there cannot be any branches to the entry block of a function).
/// - The address of the entry block is not a well-defined value.
/// - The entry block cannot have PHI nodes.  This is enforced structurally,
///   as the entry block can have no predecessor blocks to serve as operands
///   to the PHI node.
/// - Static `alloca` instructions situated in the entry block are treated
///   specially by most LLVM backends.  For example, FastISel keeps track of
///   static `alloca` values in the entry block to more efficiently reference
///   them from the base pointer of the stack frame.
public struct BasicBlock: IRValue {
  internal let llvm: LLVMBasicBlockRef

  /// Creates a `BasicBlock` from an `LLVMBasicBlockRef` object.
  public init(llvm: LLVMBasicBlockRef) {
    self.llvm = llvm
  }

  /// Creates a new basic block without a parent function.
  ///
  /// The basic block should be inserted into a function or destroyed before
  /// the IR builder is finalized.
  public init(context: Context = .global, name: String = "") {
    self.llvm = LLVMCreateBasicBlockInContext(context.llvm, name)
  }

  /// Given that this block and a given block share a parent function, move this
  /// block before the given block in that function's basic block list.
  ///
  /// - Parameter position: The basic block that acts as a position before
  ///   which this block will be moved.
  public func move(before position: BasicBlock) {
    LLVMMoveBasicBlockBefore(self.asLLVM(), position.asLLVM())
  }

  /// Given that this block and a given block share a parent function, move this
  /// block after the given block in that function's basic block list.
  ///
  /// - Parameter position: The basic block that acts as a position after
  ///   which this block will be moved.
  public func move(after position: BasicBlock) {
    LLVMMoveBasicBlockAfter(self.asLLVM(), position.asLLVM())
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }

  /// Retrieves the name of this basic block.
  public var name: String {
    let cstring = LLVMGetBasicBlockName(self.llvm)
    return String(cString: cstring!)
  }

  /// Returns the first instruction in the basic block, if it exists.
  public var firstInstruction: IRInstruction? {
    guard let val = LLVMGetFirstInstruction(llvm) else { return nil }
    return Instruction(llvm: val)
  }

  /// Returns the first instruction in the basic block, if it exists.
  public var lastInstruction: IRInstruction? {
    guard let val = LLVMGetLastInstruction(llvm) else { return nil }
    return Instruction(llvm: val)
  }

  /// Returns the terminator instruction if this basic block is well formed or
  /// `nil` if it is not well formed.
  public var terminator: TerminatorInstruction? {
    guard let term = LLVMGetBasicBlockTerminator(llvm) else { return nil }
    return TerminatorInstruction(llvm: term)
  }

  /// Returns the parent function of this basic block, if it exists.
  public var parent: Function? {
    guard let functionRef = LLVMGetBasicBlockParent(llvm) else { return nil }
    return Function(llvm: functionRef)
  }

  /// Returns the basic block following this basic block, if it exists.
  public func next() -> BasicBlock? {
    guard let blockRef = LLVMGetNextBasicBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Returns the basic block before this basic block, if it exists.
  public func previous() -> BasicBlock? {
    guard let blockRef = LLVMGetPreviousBasicBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Returns a sequence of the Instructions that make up this basic block.
  public var instructions: AnySequence<IRInstruction> {
    var current = firstInstruction
    return AnySequence<IRInstruction> {
      return AnyIterator<IRInstruction> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Removes this basic block from a function but keeps it alive.
  ///
  /// - note: To ensure correct removal of the block, you must invalidate any
  ///         references to it and its child instructions.  The block must also
  ///         have no successor blocks that make reference to it.
  public func removeFromParent() {
    LLVMRemoveBasicBlockFromParent(llvm)
  }

  /// Moves this basic block before the given basic block.
  public func moveBefore(_ block: BasicBlock) {
    LLVMMoveBasicBlockBefore(llvm, block.llvm)
  }

  /// Moves this basic block after the given basic block.
  public func moveAfter(_ block: BasicBlock) {
    LLVMMoveBasicBlockAfter(llvm, block.llvm)
  }
}

extension BasicBlock {
  /// An `Address` represents a function-relative address of a basic block for
  /// use with the `indirectbr` instruction.
  public struct Address: IRValue {
    internal let llvm: LLVMValueRef

    internal init(llvm: LLVMValueRef) {
      self.llvm = llvm
    }

    /// Retrieves the underlying LLVM value object.
    public func asLLVM() -> LLVMValueRef {
      return llvm
    }
  }
}

extension BasicBlock: Equatable {
  public static func == (lhs: BasicBlock, rhs: BasicBlock) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

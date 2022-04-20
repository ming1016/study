//
//  Function.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// A `Function` represents a named function body in LLVM IR source.  Functions
/// in LLVM IR encapsulate a list of parameters and a sequence of basic blocks
/// and provide a way to append to that sequence to build out its body.
///
/// A LLVM function definition contains a list of basic blocks, starting with
/// a privileged first block called the "entry block". After the entry blocks'
/// terminating instruction come zero or more other basic blocks.  The path the
/// flow of control can potentially take, from each block to its terminator
/// and on to other blocks, forms the "Control Flow Graph" (CFG) for the
/// function.  The nodes of the CFG are the basic blocks, and the edges are
/// directed from the terminator instruction of one block to any number of
/// potential target blocks.
///
/// Additional basic blocks may be created and appended to the function at
/// any time.
///
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     let fun = builder.addFunction("example",
///                                   type: FunctionType([], VoidType()))
///     // Create and append the entry block
///     let entryBB = fun.appendBasicBlock(named: "entry")
///     // Create and append a standalone basic block
///     let freestanding = BasicBlock(name: "freestanding")
///     fun.append(freestanding)
///
/// An LLVM function always has the type `FunctionType`.  This type is used to
/// determine the number and kind of parameters to the function as well as its
/// return value, if any.  The parameter values, which would normally enter
/// the entry block, are instead attached to the function and are accessible
/// via the `parameters` property.
///
/// Calling Convention
/// ==================
///
/// By default, all functions in LLVM are invoked with the C calling convention
/// but the exact calling convention of both a function declaration and a
/// `call` instruction are fully configurable.
///
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     let fun = builder.addFunction("example",
///                                   type: FunctionType([], VoidType()))
///     // Switch to swiftcc
///     fun.callingConvention = .swift
///
/// The calling convention of a function and a corresponding call instruction
/// must match or the result is undefined.
///
/// Sections
/// ========
///
/// A function may optionally state the section in the object file it
/// should reside in through the use of a metadata attachment.  This can be
/// useful to satisfy target-specific data layout constraints, or to provide
/// some hints to optimizers and linkers.  LLVMSwift provides a convenience
/// object called an `MDBuilder` to assist in the creation of this metadata.
///
///     let mdBuilder = MDBuilder()
///     // __attribute__((hot))
///     let hotAttr = mdBuilder.buildFunctionSectionPrefix(".hot")
///
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     let fun = builder.addFunction("example",
///                                   type: FunctionType([], VoidType()))
///     // Attach the metadata
///     fun.addMetadata(hotAttr, kind: .sectionPrefix)
///
/// For targets that support it, a function may also specify a COMDAT section.
///
///     fun.comdat = module.comdat(named: "example")
///
/// Debug Information
/// =================
///
/// A function may also carry debug information through special subprogram
/// nodes.  These nodes are intended to capture the structure of the function
/// as it appears in the source so that it is available for inspection by a
/// debugger.  See `DIBuilderr.buildFunction` for more information.
public class Function: IRGlobal {
  internal let llvm: LLVMValueRef
  internal init(llvm: LLVMValueRef) {
    self.llvm = llvm
  }

  /// Accesses the metadata associated with this function.
  ///
  /// To build new function metadata, see `DIBuilder.buildFunction`.
  public var metadata: FunctionMetadata {
    get { return FunctionMetadata(llvm: LLVMGetSubprogram(self.llvm)) }
    set { LLVMSetSubprogram(self.llvm, newValue.asMetadata()) }
  }

  /// Accesses the calling convention for this function.
  public var callingConvention: CallingConvention {
    get { return CallingConvention(llvm: LLVMCallConv(rawValue: LLVMGetFunctionCallConv(llvm))) }
    set { LLVMSetFunctionCallConv(llvm, newValue.llvm.rawValue) }
  }

  /// Retrieves the entry block of this function.
  public var entryBlock: BasicBlock? {
    guard let blockRef = LLVMGetEntryBasicBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Retrieves the first basic block in this function's body.
  ///
  /// The first basic block in a function is special in two ways: it is
  /// immediately executed on entrance to the function, and it is not allowed to
  /// have predecessor basic blocks (i.e. there can not be any branches to the
  /// entry block of a function). Because the block can have no predecessors, it
  /// also cannot have any PHI nodes.
  public var firstBlock: BasicBlock? {
    guard let blockRef = LLVMGetFirstBasicBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Retrieves the last basic block in this function's body.
  public var lastBlock: BasicBlock? {
    guard let blockRef = LLVMGetLastBasicBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Retrieves the sequence of basic blocks that make up this function's body.
  public var basicBlocks: AnySequence<BasicBlock> {
    var current = firstBlock
    return AnySequence<BasicBlock> {
      return AnyIterator<BasicBlock> {
        defer { current = current?.next() }
        return current
      }
    }
  }

  /// Retrieves the number of basic blocks in this function
  public var basicBlockCount: Int {
    return Int(LLVMCountBasicBlocks(self.llvm))
  }

  /// Computes the address of the specified basic block in this function.
  ///
  /// - WARNING: Taking the address of the entry block is illegal.
  ///
  /// This value only has defined behavior when used as an operand to the
  /// `indirectbr` instruction, or for comparisons against null. Pointer
  /// equality tests between labels addresses results in undefined behavior.
  /// Though, again, comparison against null is ok, and no label is equal to
  /// the null pointer. This may be passed around as an opaque pointer sized
  /// value as long as the bits are not inspected. This allows `ptrtoint` and
  /// arithmetic to be performed on these values so long as the original value
  /// is reconstituted before the indirectbr instruction.
  ///
  /// Finally, some targets may provide defined semantics when using the value
  /// as the operand to an inline assembly, but that is target specific.
  ///
  /// - parameter block: The basic block to compute the address of.
  ///
  /// - returns: An IRValue representing the address of the given basic block
  ///   in this function, else nil if the address cannot be computed or the
  ///   basic block does not reside in this function.
  public func address(of block: BasicBlock) -> BasicBlock.Address? {
    guard let addr = LLVMBlockAddress(llvm, block.llvm) else {
      return nil
    }
    return BasicBlock.Address(llvm: addr)
  }

  /// Retrieves the previous function in the module, if there is one.
  public func previous() -> Function? {
    guard let previous = LLVMGetPreviousFunction(llvm) else { return nil }
    return Function(llvm: previous)
  }

  /// Retrieves the next function in the module, if there is one.
  public func next() -> Function? {
    guard let next = LLVMGetNextFunction(llvm) else { return nil }
    return Function(llvm: next)
  }

  /// Retrieves a parameter at the given index, if it exists.
  ///
  /// - parameter index: The index of the parameter to retrieve.
  ///
  /// - returns: The parameter at the specified index if it exists, else nil.
  public func parameter(at index: Int) -> Parameter? {
    guard let value = LLVMGetParam(llvm, UInt32(index)) else { return nil }
    return Parameter(llvm: value)
  }

  /// Retrieves a parameter at the first index, if it exists.
  public var firstParameter: Parameter? {
    guard let value = LLVMGetFirstParam(llvm) else { return nil }
    return Parameter(llvm: value)
  }

  /// Retrieves a parameter at the last index, if it exists.
  public var lastParameter: Parameter? {
    guard let value = LLVMGetLastParam(llvm) else { return nil }
    return Parameter(llvm: value)
  }

  /// Retrieves the list of all parameters for this function, in order.
  public var parameters: [IRValue] {
    var current = firstParameter
    var params = [Parameter]()
    while let param = current {
      params.append(param)
      current = param.next()
    }
    return params
  }

  /// Retrieves the number of parameter values in this function.
  public var parameterCount: Int {
    return Int(LLVMCountParams(self.llvm))
  }

  /// Appends the named basic block to the body of this function.
  ///
  /// - parameter name: The name associated with this basic block.
  /// - parameter context: An optional context into which the basic block can be
  ///   inserted into.  If no context is provided, the block is inserted into
  ///   the global context.
  public func appendBasicBlock(named name: String, in context: Context? = nil) -> BasicBlock {
    let block: LLVMBasicBlockRef
    if let context = context {
      block = LLVMAppendBasicBlockInContext(context.llvm, llvm, name)
    } else {
      block = LLVMAppendBasicBlock(llvm, name)
    }
    return BasicBlock(llvm: block)
  }

  /// Appends the named basic block to the body of this function.
  ///
  /// - parameter basicBlock: The block to append.
  public func append(_ basicBlock: BasicBlock) {
    LLVMAppendExistingBasicBlock(llvm, basicBlock.asLLVM())
  }

  /// Deletes the function from its containing module.
  /// - note: This does not remove calls to this function from the
  ///         module. Ensure you have removed all instructions that reference
  ///         this function before deleting it.
  public func delete() {
    LLVMDeleteFunction(llvm)
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }
}

/// A `Parameter` represents an index into the parameters of a `Function`.
public struct Parameter: IRValue {
  internal let llvm: LLVMValueRef

  /// Retrieves the next parameter, if it exists.
  public func next() -> Parameter? {
    guard let param = LLVMGetNextParam(llvm) else { return nil }
    return Parameter(llvm: param)
  }

  /// Retrieves the previous parameter, if it exists.
  public func previous() -> Parameter? {
    guard let param = LLVMGetPreviousParam(llvm) else { return nil }
    return Parameter(llvm: param)
  }

  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return llvm
  }
}

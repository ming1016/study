//
//  IRBuilder.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An `IRBuilder` is a helper object that generates LLVM instructions.
///
/// IR builders keep track of a position (the "insertion point") within a
/// module, function, or basic block and has methods to insert instructions at
/// that position.  Other features include conveniences to insert calls to
/// C standard library functions like `malloc` and `free`, the creation of
/// global entities like (C) strings, and inline assembly.
///
/// Threading Considerations
/// ========================
///
/// An `IRBuilder` object is not thread safe.  It is associated with a single
/// module which is, in turn, associated with a single LLVM context object.
/// In concurrent environments, exactly one IRBuilder should be created per
/// thread, and that thread should be the one that ultimately created its parent
/// module and context.  Inserting instructions into the same IR builder object
/// in a concurrent manner will result in malformed IR being generated in
/// non-deterministic ways.  If concurrent codegen is needed, a separate LLVM
/// context, module, and IRBuilder should be created on each thread.
/// Once each thread has finished generating code, the resulting modules should
/// be merged together.  See `Module.link(_:)` for more information.
///
/// IR Navigation
/// =============
///
/// By default, the insertion point of a builder is undefined.  To move the
/// IR builder's cursor, a basic block must be created, but not necessarily
/// inserted into a function.
///
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     // Create a freestanding basic block and insert an `ret`
///     // instruction into it.
///     let freestanding = BasicBlock(name: "freestanding")
///     // Move the IR builder to the end of the block's instruction list.
///     builder.positionAtEnd(of: freestanding)
///     let ret = builder.buildRetVoid()
///
/// Instructions serve as a way to position the IR builder to a point before
/// their creation.  This allows for instructions to be inserted *before* a
/// given instruction rather than at the very end of a basic block.
///
///     // Move before the `ret` instruction
///     builder.positionBefore(ret)
///     // Insert an `alloca` instruction before the `ret`.
///     let intAlloca = builder.buildAlloca(type: IntType.int8)
///     // Move before the `alloca`
///     builder.positionBefore(intAlloca)
///     // Insert an `malloc` call before the `alloca`.
///     let intMalloc = builder.buildMalloc(IntType.int8)
///
/// To insert this block into a function, see `Function.append`.
///
/// Sometimes it is necessary to reset the insertion point.  When the insertion
/// point is reset, instructions built with the IR builder are still created,
/// but are not inserted into a basic block.  To clear the insertion point, call
/// `IRBuilder.clearInsertionPosition()`.
///
/// Building LLVM IR
/// ================
///
/// All functions that build instructions are prefixed with `build`.  Invoking
/// these functions inserts the appropriate LLVM instruction at the insertion
/// point, assuming it points to a valid location.
///
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     let fun = builder.addFunction("test",
///                                   type: FunctionType([
///                                           IntType.int8,
///                                           IntType.int8,
///                                   ], FloatType.float))
///     let entry = fun.appendBasicBlock(named: "entry")
///     // Set the insertion point to the entry block of this function
///     builder.positionAtEnd(of: entry)
///     // Build an `add` instruction at the insertion point
///     let result = builder.buildAdd(fun.parameters[0], fun.parameters[1])
///
/// Customizing LLVM IR
/// ===================
///
/// To be well-formed, certain instructions may involve more setup than just
/// being built.  In such cases, LLVMSwift will yield a specific instance of
/// `IRInstruction` that will allow for this kind of configuration.
///
/// A prominent example of this is the PHI node.  Building a PHI node produces
/// an empty PHI node - this is not a well-formed instruction. A PHI node must
/// have its incoming basic blocks attached. To do so, `PhiNode.addIncoming(_:)`
/// is called with a list of pairs of incoming values and their enclosing
/// basic blocks.
///
///     // Build a function that selects one of two floating parameters based
///     // on a given boolean value.
///     let module = Module(name: "Example")
///     let builder = IRBuilder(module: module)
///     let select = builder.addFunction("select",
///                                      type: FunctionType([
///                                              IntType.int1,
///                                              FloatType.float,
///                                              FloatType.float,
///                                      ], FloatType.float))
///     let entry = select.appendBasicBlock(named: "entry")
///     builder.positionAtEnd(of: entry)
///
///     let thenBlock = select.appendBasicBlock(named: "then")
///     let elseBlock = select.appendBasicBlock(named: "else")
///     let mergeBB = select.appendBasicBlock(named: "merge")
///     let branch = builder.buildCondBr(condition: select.parameters[0],
///                                      then: thenBlock,
///                                      else: elseBlock)
///     builder.positionAtEnd(of: thenBlock)
///     let opThen = builder.buildAdd(select.parameters[1], select.parameters[2])
///     builder.buildBr(mergeBB)
///     builder.positionAtEnd(of: elseBlock)
///     let opElse = builder.buildSub(select.parameters[1], select.parameters[2])
///     builder.buildBr(mergeBB)
///     builder.positionAtEnd(of: mergeBB)
///
///     // Build the PHI node
///     let phi = builder.buildPhi(FloatType.float)
///     // Attach the incoming blocks.
///     phi.addIncoming([
///       (opThen, thenBlock),
///       (opElse, elseBlock),
///     ])
///     builder.buildRet(phi)
public class IRBuilder {
  internal let llvm: LLVMBuilderRef

  /// The module this `IRBuilder` is associated with.
  public let module: Module

  /// Creates an `IRBuilder` object with the given module.
  ///
  /// - parameter module: The module into which instructions will be inserted.
  public init(module: Module) {
    self.module = module
    self.llvm = LLVMCreateBuilderInContext(module.context.llvm)
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    LLVMDisposeBuilder(llvm)
  }
}

// MARK: IR Navigation

extension IRBuilder {
  /// Repositions the IR Builder at the end of the given basic block.
  ///
  /// - parameter block: The basic block to reposition the IR Builder after.
  public func positionAtEnd(of block: BasicBlock) {
    LLVMPositionBuilderAtEnd(llvm, block.llvm)
  }

  /// Repositions the IR Builder before the start of the given instruction.
  ///
  /// - parameter inst: The instruction to reposition the IR Builder before.
  public func positionBefore(_ inst: IRInstruction) {
    LLVMPositionBuilderBefore(llvm, inst.asLLVM())
  }

  /// Repositions the IR Builder at the point specified by the given instruction
  /// in the given basic block.
  ///
  /// This is equivalent to calling `positionAtEnd(of:)` with the given basic
  /// block then calling `positionBefore(_:)` with the given instruction.
  ///
  /// - parameter inst: The instruction to reposition the IR Builder before.
  /// - parameter block: The basic block to reposition the IR builder in.
  public func position(_ inst: IRInstruction, block: BasicBlock) {
    LLVMPositionBuilder(llvm, block.llvm, inst.asLLVM())
  }

  /// Clears the insertion point.
  ///
  /// Subsequent instructions will not be inserted into a block.
  public func clearInsertionPosition() {
    LLVMClearInsertionPosition(llvm)
  }

  /// Gets the basic block built instructions will be inserted into.
  public var insertBlock: BasicBlock? {
    guard let blockRef = LLVMGetInsertBlock(llvm) else { return nil }
    return BasicBlock(llvm: blockRef)
  }

  /// Gets the function this builder is building into.
  public var currentFunction: Function? {
    return insertBlock?.parent
  }

  /// Inserts the given instruction into the IR Builder.
  ///
  /// - parameter inst: The instruction to insert.
  /// - parameter name: The name for the newly inserted instruction.
  public func insert(_ inst: IRInstruction, name: String? = nil) {
    if let name = name {
      LLVMInsertIntoBuilderWithName(llvm, inst.asLLVM(), name)
    } else {
      LLVMInsertIntoBuilder(llvm, inst.asLLVM())
    }
  }
}

// MARK: Debug Information

extension IRBuilder {
  /// Access location information used by debugging information.
  public var currentDebugLocation: DebugLocation? {
    get { return LLVMGetCurrentDebugLocation2(self.llvm).map(DebugLocation.init(llvm:)) }
    set { LLVMSetCurrentDebugLocation2(self.llvm, newValue?.asMetadata()) }
  }

  /// Set the floating point math metadata to be used for floating-point
  /// operations.
  public var defaultFloatingPointMathTag: MDNode? {
    get { return LLVMBuilderGetDefaultFPMathTag(self.llvm).map(MDNode.init(llvm:)) }
    set { LLVMBuilderSetDefaultFPMathTag(self.llvm, newValue?.asMetadata()) }
  }
}

// MARK: Convenience Instructions

extension IRBuilder {
  /// Builds the specified binary operation instruction with the given arguments.
  ///
  /// - parameter op: The operation to build.
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of perfomring the given binary
  ///   operation with the given values as arguments.
  public func buildBinaryOperation(_ op: OpCode.Binary, _ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildBinOp(llvm, op.llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Builds the specified cast operation instruction with the given value and
  /// destination type.
  ///
  /// - parameter op: The cast operation to build.
  /// - parameter value: The value to cast.
  /// - parameter type: The destination type to cast to.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of casting the given value to
  ///   the given destination type using the given operation.
  public func buildCast(_ op: OpCode.Cast, value: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildCast(llvm, op.llvm, value.asLLVM(), type.asLLVM(), name)
  }

  /// Builds a cast operation from a value of pointer type to any other
  /// integral, pointer, or vector of integral/pointer type.
  ///
  /// There are a number of restrictions on the form of the input value and
  /// destination type.  The source value of a pointer cast must be either a
  /// pointer or a vector of pointers.  The destination type must either be
  /// an integer type, a pointer type, or a vector type with integral or pointer
  /// element type.
  ///
  /// If the destination type is an integral type or a vector of integral
  /// elements, this builds a `ptrtoint` instruction.  Else, if the destination
  /// is a pointer type or vector of pointer type, and it has an address space
  /// that differs from the address space of the source value, an
  /// `addrspacecast` instruction is built.  If none of these are true, a
  /// `bitcast` instruction is built.
  ///
  /// - Parameters:
  ///   - value: The value to cast.  The value must have pointer type.
  ///   - type: The destination type to cast to.  This must be a pointer type,
  ///     integer type, or vector of the same.
  ///   - name: The name for the newly inserted instruction.
  /// - Returns: A value representing the result of casting the given value to
  ///   the given destination type using the appropriate pointer cast operation.
  public func buildPointerCast(of value: IRValue, to type: IRType, name: String = "") -> IRValue {
    precondition(value.type is PointerType || value.type.scalarType is PointerType,
                 "cast value must be a pointer or vector of pointers")
    precondition(type.scalarType is IntType || type.scalarType is PointerType,
                 "destination type must be int, pointer, or vector of int/pointer")

    return LLVMBuildPointerCast(llvm, value.asLLVM(), type.asLLVM(), name)
  }

  /// Builds a cast operation from a value of integral type to given integral
  /// type by zero-extension, sign-extension, bitcast, or truncation
  /// as necessary.
  ///
  /// - Parameters:
  ///   - value: The value to cast.
  ///   - type: The destination integer type to cast to.
  ///   - signed: If true, if an extension is required it will be a
  ///     sign-extension.  Else, all required extensions will be
  ///     zero-extensions.
  ///   - name: The name for the newly inserted instruction.
  /// - Returns: A value reprresenting the result of casting the given value to
  ///   the given destination integer type using the appropriate
  ///   integral cast operation.
  public func buildIntCast(of value: IRValue, to type: IntType, signed: Bool = true, name: String = "") -> IRValue {
    return LLVMBuildIntCast2(llvm, value.asLLVM(), type.asLLVM(), signed.llvm, name)
  }
}

// MARK: Arithmetic Instructions

extension IRBuilder {
  /// Build a negation instruction with the given value as an operand.
  ///
  /// Whether an integer or floating point negate instruction is built is
  /// determined by the type of the given value.  Providing an operand that is
  /// neither an integer nor a floating value is a fatal condition.
  ///
  /// - parameter value: The value to negate.
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the negation of the given value.
  public func buildNeg(_ value: IRValue,
                       overflowBehavior: OverflowBehavior = .default,
                       name: String = "") -> IRValue {
    let val = value.asLLVM()
    if value.type is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWNeg(llvm, val, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWNeg(llvm, val, name)
      case .default:
        return LLVMBuildNeg(llvm, val, name)
      }
    } else if value.type is FloatType {
      return LLVMBuildFNeg(llvm, val, name)
    }
    fatalError("Can only negate value of int or float types")
  }

  /// Build an add instruction with the given values as operands.
  ///
  /// Whether an integer or floating point add instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first summand value (the augend).
  /// - parameter rhs: The second summand value (the addend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the sum of the two operands.
  public func buildAdd(_ lhs: IRValue, _ rhs: IRValue,
                       overflowBehavior: OverflowBehavior = .default,
                       name: String = "") -> IRValue {
    let lhsType = lowerVector(lhs.type)

    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhsType is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWAdd(llvm, lhsVal, rhsVal, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWAdd(llvm, lhsVal, rhsVal, name)
      case .default:
        return LLVMBuildAdd(llvm, lhsVal, rhsVal, name)
      }
    } else if lhsType is FloatType {
      return LLVMBuildFAdd(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only add value of int, float, or vector types")
  }

  /// Build a subtract instruction with the given values as operands.
  ///
  /// Whether an integer or floating point subtract instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first value (the minuend).
  /// - parameter rhs: The second value (the subtrahend).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the difference of the two operands.
  public func buildSub(_ lhs: IRValue, _ rhs: IRValue,
                       overflowBehavior: OverflowBehavior = .default,
                       name: String = "") -> IRValue {
    let lhsType = lowerVector(lhs.type)

    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhsType is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWSub(llvm, lhsVal, rhsVal, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWSub(llvm, lhsVal, rhsVal, name)
      case .default:
        return LLVMBuildSub(llvm, lhsVal, rhsVal, name)
      }
    } else if lhsType is FloatType {
      return LLVMBuildFSub(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only subtract value of int or float types")
  }

  /// Build a multiply instruction with the given values as operands.
  ///
  /// Whether an integer or floating point multiply instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first factor value (the multiplier).
  /// - parameter rhs: The second factor value (the multiplicand).
  /// - parameter overflowBehavior: Should overflow occur, specifies the
  ///   behavior of the program.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the product of the two operands.
  public func buildMul(_ lhs: IRValue, _ rhs: IRValue,
                       overflowBehavior: OverflowBehavior = .default,
                       name: String = "") -> IRValue {
    let lhsType = lowerVector(lhs.type)

    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhsType is IntType {
      switch overflowBehavior {
      case .noSignedWrap:
        return LLVMBuildNSWMul(llvm, lhsVal, rhsVal, name)
      case .noUnsignedWrap:
        return LLVMBuildNUWMul(llvm, lhsVal, rhsVal, name)
      case .default:
        return LLVMBuildMul(llvm, lhsVal, rhsVal, name)
      }
    } else if lhsType is FloatType {
      return LLVMBuildFMul(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only multiply value of int or float types")
  }

  /// Build a remainder instruction that provides the remainder after divison of
  /// the first value by the second value.
  ///
  /// Whether an integer or floating point remainder instruction is built is
  /// determined by the type of the first given value.  Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  /// - parameter signed: Whether to emit a signed or unsigned remainder
  ///   instruction.  Defaults to emission of a signed remainder instruction.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the remainder of division of the first
  ///   operand by the second operand.
  public func buildRem(_ lhs: IRValue, _ rhs: IRValue,
                       signed: Bool = true,
                       name: String = "") -> IRValue {
    let lhsType = lowerVector(lhs.type)

    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhsType is IntType {
      if signed {
        return LLVMBuildSRem(llvm, lhsVal, rhsVal, name)
      } else {
        return LLVMBuildURem(llvm, lhsVal, rhsVal, name)
      }
    } else if lhsType is FloatType {
      return LLVMBuildFRem(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only take remainder of int or float types")
  }

  /// Build a division instruction that divides the first value by the second
  /// value.
  ///
  /// Whether an integer or floating point divide instruction is built is
  /// determined by the type of the first given value. Providing operands that
  /// are neither integers nor floating values is a fatal condition.
  ///
  /// - parameter lhs: The first value (the dividend).
  /// - parameter rhs: The second value (the divisor).
  /// - parameter signed: Whether to emit a signed or unsigned remainder
  ///                     instruction. Defaults to emission of a signed
  ///                     divide instruction.
  /// - parameter exact: Whether this division must be exact. Defaults to
  ///                    inexact.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the quotient of the first and second
  ///   operands.
  public func buildDiv(_ lhs: IRValue, _ rhs: IRValue,
                       signed: Bool = true, exact: Bool = false,
                       name: String = "") -> IRValue {
    let lhsType = lowerVector(lhs.type)

    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    if lhsType is IntType {
      if signed {
        if exact {
          return LLVMBuildExactSDiv(llvm, lhsVal, rhsVal, name)
        } else {
          return LLVMBuildSDiv(llvm, lhsVal, rhsVal, name)
        }
      } else {
        return LLVMBuildUDiv(llvm, lhsVal, rhsVal, name)
      }
    } else if lhsType is FloatType {
      return LLVMBuildFDiv(llvm, lhsVal, rhsVal, name)
    }
    fatalError("Can only divide values of int or float types")
  }

  /// Build an integer comparison between the two provided values using the
  /// given predicate.
  ///
  /// - precondition: Arguments must be integer or pointer or integer vector typed
  /// - precondition: lhs.type == rhs.type
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  /// - parameter predicate: The method of comparison to use.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of the comparision of the given
  ///   operands.
  public func buildICmp(_ lhs: IRValue, _ rhs: IRValue,
                        _ predicate: IntPredicate,
                        name: String = "") -> IRValue {
    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    assert(
        (lhs.type is IntType && rhs.type is IntType) ||
        (lhs.type is PointerType && rhs.type is PointerType) ||
        ((lhs.type is VectorType && rhs.type is VectorType) &&
            (LLVMGetTypeKind(LLVMGetElementType(lhs.type.asLLVM())) == LLVMIntegerTypeKind) &&
            (LLVMGetTypeKind(LLVMGetElementType(rhs.type.asLLVM())) == LLVMIntegerTypeKind)),
        "Can only build ICMP instruction with int or pointer types")
    return LLVMBuildICmp(llvm, predicate.llvm, lhsVal, rhsVal, name)
  }

  /// Build a floating comparison between the two provided values using the
  /// given predicate.
  ///
  /// Attempting to compare operands that are not floating is a fatal condition.
  ///
  /// - parameter lhs: The first value to compare.
  /// - parameter rhs: The second value to compare.
  /// - parameter predicate: The method of comparison to use.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of the comparision of the given
  ///   operands.
  public func buildFCmp(_ lhs: IRValue, _ rhs: IRValue,
                        _ predicate: RealPredicate,
                        name: String = "") -> IRValue {
    let lhsType = lowerVector(lhs.type)

    let lhsVal = lhs.asLLVM()
    let rhsVal = rhs.asLLVM()
    guard lhsType is FloatType else {
      fatalError("Can only build FCMP instruction with float types")
    }
    return LLVMBuildFCmp(llvm, predicate.llvm, lhsVal, rhsVal, name)
  }
}

// MARK: Logical Instructions

extension IRBuilder {
  /// Build a bitwise logical not with the given value as an operand.
  ///
  /// - parameter val: The value to negate.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the logical negation of the given operand.
  public func buildNot(_ val: IRValue, name: String = "") -> IRValue {
    return LLVMBuildNot(llvm, val.asLLVM(), name)
  }

  /// Build a bitwise logical exclusive OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the exclusive OR of the values of the
  ///   two given operands.
  public func buildXor(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildXor(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Build a bitwise logical OR with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the logical OR of the values of the
  ///   two given operands.
  public func buildOr(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildOr(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Build a bitwise logical AND with the given values as operands.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The second operand.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the logical AND of the values of the
  ///   two given operands.
  public func buildAnd(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    return LLVMBuildAnd(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Build a left-shift instruction of the first value by an amount in the
  /// second value.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The number of bits to shift the first operand left by.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the value of the first operand shifted
  ///   left by the number of bits specified in the second operand.
  public func buildShl(_ lhs: IRValue, _ rhs: IRValue,
                       name: String = "") -> IRValue {
    return LLVMBuildShl(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }

  /// Build a right-shift instruction of the first value by an amount in the
  /// second value.  If `isArithmetic` is true the value of the first operand is
  /// bitshifted with sign extension.  Else the value is bitshifted with
  /// zero-fill.
  ///
  /// - parameter lhs: The first operand.
  /// - parameter rhs: The number of bits to shift the first operand right by.
  /// - parameter isArithmetic: Whether this instruction performs an arithmetic
  ///   or logical right-shift.  The default is a logical right-shift.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the value of the first operand shifted
  ///   right by the numeber of bits specified in the second operand.
  public func buildShr(_ lhs: IRValue, _ rhs: IRValue,
                       isArithmetic: Bool = false,
                       name: String = "") -> IRValue {
    if isArithmetic {
      return LLVMBuildAShr(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
    } else {
      return LLVMBuildLShr(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
    }
  }
}

// MARK: Conditional Instructions

extension IRBuilder {
  /// Build a phi node with the given type acting as the result of any incoming
  /// basic blocks.
  ///
  /// - parameter type: The type of incoming values.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the newly inserted phi node.
  public func buildPhi(_ type: IRType, name: String = "") -> PhiNode {
    let value = LLVMBuildPhi(llvm, type.asLLVM(), name)!
    return PhiNode(llvm: value)
  }

  /// Build a select instruction to choose a value based on a condition without
  /// IR-level branching.
  ///
  /// - parameter cond: The condition to evaluate.  It must have type `i1` or
  ///   be a vector of `i1`.
  /// - parameter then: The value to select if the given condition is true.
  /// - parameter else: The value to select if the given condition is false.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the value selected for by the condition.
  public func buildSelect(_ cond: IRValue, then: IRValue, else: IRValue, name: String = "") -> IRInstruction {
    if let ty = cond.type as? IntType {
      precondition(ty.width == 1, "Switch statement condition must have bitwidth of 1, instead has bitwidth of \(ty.width)")
      return LLVMBuildSelect(llvm, cond.asLLVM(), then.asLLVM(), `else`.asLLVM(), name)
    } else if let ty = cond.type as? VectorType, let intTy = ty.elementType as? IntType {
      precondition(intTy.width == 1, "Switch statement condition must have bitwidth of 1, instead has bitwidth of \(intTy.width)")
      return LLVMBuildSelect(llvm, cond.asLLVM(), then.asLLVM(), `else`.asLLVM(), name)
    } else {
      fatalError("Condition must have type i1 or <i1 x N>")
    }
  }

  /// Build a branch table that branches on the given value with the given
  /// default basic block.
  ///
  /// The `switch` instruction is used to transfer control flow to one of
  /// several different places. It is a generalization of the `br` instruction,
  /// allowing a branch to occur to one of many possible destinations.
  ///
  /// This function returns a value that acts as a representation of the branch
  /// table for the `switch` instruction.  When the `switch` instruction is
  /// executed, this table is searched for the given value. If the value is
  /// found, control flow is transferred to the corresponding destination;
  /// otherwise, control flow is transferred to the default destination
  /// specified by the `else` block.
  ///
  /// To add branches to the `switch` table, see `Switch.addCase(_:_:)`.
  ///
  /// - parameter value: The value to compare.
  /// - parameter else: The default destination for control flow should the
  ///   value not match a case in the branch table.
  /// - parameter caseCount: The number of cases in the branch table.
  ///
  /// - returns: A value representing the newly inserted `switch` instruction.
  public func buildSwitch(_ value: IRValue, else: BasicBlock, caseCount: Int) -> Switch {
    return Switch(llvm: LLVMBuildSwitch(llvm,
                                        value.asLLVM(),
                                        `else`.asLLVM(),
                                        UInt32(caseCount))!)
  }
}

// MARK: Declaration Instructions

extension IRBuilder {
  /// Build a named function body with the given type.
  ///
  /// - parameter name: The name of the newly defined function.
  /// - parameter type: The type of the newly defined function.
  ///
  /// - returns: A value representing the newly inserted function definition.
  public func addFunction(_ name: String, type: FunctionType) -> Function {
    return Function(llvm: LLVMAddFunction(module.llvm, name, type.asLLVM()))
  }

  /// Build a named structure definition.
  ///
  /// - parameter name: The name of the structure.
  /// - parameter types: The type of fields that make up the structure's body.
  /// - parameter isPacked: Whether this structure should be 1-byte aligned with
  ///   no padding between elements.
  ///
  /// - returns: A value representing the newly declared named structure.
  public func createStruct(name: String, types: [IRType]? = nil, isPacked: Bool = false) -> StructType {
    let named = LLVMStructCreateNamed(module.context.llvm, name)!
    let type = StructType(llvm: named)
    if let types = types {
      type.setBody(types)
    }
    return type
  }
}

// MARK: Terminator Instructions

extension IRBuilder {
  /// Build an unconditional branch to the given basic block.
  ///
  /// The `br` instruction is used to cause control flow to transfer to a
  /// different basic block in the current function. There are two forms of this
  /// instruction, corresponding to a conditional branch and an unconditional
  /// branch.  To build a conditional branch, see
  /// `buildCondBr(condition:then:`else`:)`.
  ///
  /// - parameter block: The target block to transfer control flow to.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildBr(_ block: BasicBlock) -> IRInstruction {
    return LLVMBuildBr(llvm, block.llvm)
  }

  /// Build a condition branch that branches to the first basic block if the
  /// provided condition is `true`, otherwise to the second basic block.
  ///
  /// The `br` instruction is used to cause control flow to transfer to a
  /// different basic block in the current function. There are two forms of this
  /// instruction, corresponding to a conditional branch and an unconditional
  /// branch.  To build an unconditional branch, see `buildBr(_:)`.
  ///
  /// - parameter condition: A value of type `i1` that determines which basic
  ///   block to transfer control flow to.
  /// - parameter then: The basic block to transfer control flow to if the
  ///   condition evaluates to `true`.
  /// - parameter else: The basic block to transfer control flow to if the
  ///   condition evaluates to `false`.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildCondBr(
    condition: IRValue, then: BasicBlock, `else`: BasicBlock) -> IRInstruction {
    guard let instr: IRInstruction = LLVMBuildCondBr(llvm, condition.asLLVM(), then.asLLVM(), `else`.asLLVM()) else {
      fatalError("Unable to build conditional branch")
    }
    return instr
  }

  /// Build an indirect branch to a label within the current function.
  ///
  /// The `indirectbr` instruction implements an indirect branch to a label
  /// within the current function, whose address is specified by the `address`
  /// parameter.
  ///
  /// All possible destination blocks must be listed in the `destinations` list,
  /// otherwise this instruction has undefined behavior. This implies that jumps
  /// to labels defined in other functions have undefined behavior as well.
  ///
  /// - parameter address: The address of the label to branch to.
  /// - parameter destinations: The set of possible destinations the address may
  ///   point to.  The same block may appear multiple times in this list, though
  ///   this isn't particularly useful.
  ///
  /// - returns: An IRValue representing `void`.
  @discardableResult
  public func buildIndirectBr(address: BasicBlock.Address, destinations: [BasicBlock]) -> IRInstruction {
    guard let ret = LLVMBuildIndirectBr(llvm, address.asLLVM(), UInt32(destinations.count)) else {
      fatalError("Unable to build indirect branch to address \(address)")
    }
    for dest in destinations {
      LLVMAddDestination(ret, dest.llvm)
    }
    return ret
  }

  /// Build a return from the current function back to the calling function
  /// with the given value.
  ///
  /// Returning a value with a type that does not correspond to the return
  /// type of the current function is a fatal condition.
  ///
  /// There are two forms of the `ret` instruction: one that returns a value and
  /// then causes control flow, and one that just causes control flow to occur.
  /// To build the `ret` that does not return a value use `buildRetVoid()`.
  ///
  /// - parameter val: The value to return from the current function.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildRet(_ val: IRValue) -> IRInstruction {
    return LLVMBuildRet(llvm, val.asLLVM())
  }

  /// Build a void return from the current function.
  ///
  /// If the current function does not have a `Void` return value, failure to
  /// return a falue is a fatal condition.
  ///
  /// There are two forms of the `ret` instruction: one that returns a value and
  /// then causes control flow, and one that just causes control flow to occur.
  /// To build the `ret` that returns a value use `buildRet(_:)`.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildRetVoid() -> IRInstruction {
    return LLVMBuildRetVoid(llvm)
  }

  /// Build an unreachable instruction in the current function.
  ///
  /// The `unreachable` instruction has no defined semantics. This instruction
  /// is used to inform the optimizer that a particular portion of the code is
  /// not reachable. This can be used to indicate that the code after a
  /// no-return function cannot be reached, and other facts.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildUnreachable() -> IRInstruction {
    return LLVMBuildUnreachable(llvm)
  }

  /// Build a return from the current function back to the calling function with
  /// the given array of values as members of an aggregate.
  ///
  /// - parameter values: The values to insert as members of the returned
  ///   aggregate.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildRetAggregate(of values: [IRValue]) -> IRInstruction {
    var values = values.map { $0.asLLVM() as Optional }
    return values.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildAggregateRet(llvm, buf.baseAddress!, UInt32(buf.count))
    }
  }

  /// Build a call to the given function with the given arguments to transfer
  /// control to that function.
  ///
  /// - parameter fn: The function to invoke.
  /// - parameter args: A list of arguments.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of returning from the callee.
  public func buildCall(_ fn: IRValue, args: [IRValue], name: String = "") -> Call {
    var args = args.map { $0.asLLVM() as Optional }
    return args.withUnsafeMutableBufferPointer { buf in
      return Call(llvm: LLVMBuildCall(llvm, fn.asLLVM(), buf.baseAddress!, UInt32(buf.count), name))
    }
  }
}

// MARK: Exception Handling Instructions

extension IRBuilder {
  /// Build a call to the given function with the given arguments with the
  /// possibility of control transfering to either the `next` basic block or
  /// the `catch` basic block if an exception occurs.
  ///
  /// If the callee function returns with the `ret` instruction, control flow
  /// will return to the `next` label. If the callee (or any indirect callees)
  /// returns via the `resume` instruction or other exception handling
  /// mechanism, control is interrupted and continued at the dynamically nearest
  /// `exception` label.
  ///
  /// The `catch` block is a landing pad for the exception. As such, the first
  /// instruction of that block is required to be the `landingpad` instruction,
  /// which contains the information about the behavior of the program after
  /// unwinding happens.
  ///
  /// - parameter fn: The function to invoke.
  /// - parameter args: A list of arguments.
  /// - parameter next: The destination block if the invoke succeeds without exceptions.
  /// - parameter catch: The destination block if the invoke encounters an exception.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of returning from the callee
  ///   under normal circumstances.  Under exceptional circumstances, the value
  ///   represents the value of any `resume` instruction in the `catch` block.
  public func buildInvoke(_ fn: IRValue, args: [IRValue], next: BasicBlock, catch: BasicBlock, name: String = "") -> Invoke {
    precondition(`catch`.firstInstruction!.opCode == .landingPad, "First instruction of catch block must be a landing pad")

    var args = args.map { $0.asLLVM() as Optional }
    return args.withUnsafeMutableBufferPointer { buf in
      return Invoke(llvm: LLVMBuildInvoke(llvm, fn.asLLVM(), buf.baseAddress!, UInt32(buf.count), next.llvm, `catch`.llvm, name))
    }
  }

  /// Build a landing pad to specify that a basic block is where an exception
  /// lands, and corresponds to the code found in the `catch` portion of a
  /// `try/catch` sequence.
  ///
  /// The clauses are applied in order from top to bottom. If two landing pad
  /// instructions are merged together through inlining, the clauses from the
  /// calling function are appended to the list of clauses. When the call stack
  /// is being unwound due to an exception being thrown, the exception is
  /// compared against each clause in turn. If it doesn’t match any of the
  /// clauses, and the cleanup flag is not set, then unwinding continues further
  /// up the call stack.
  ///
  /// The landingpad instruction has several restrictions:
  ///
  /// - A landing pad block is a basic block which is the unwind destination of
  ///   an `invoke` instruction.
  /// - A landing pad block must have a `landingpad` instruction as its first
  ///   non-PHI instruction.
  /// - There can be only one `landingpad` instruction within the landing pad
  ///   block.
  /// - A basic block that is not a landing pad block may not include a
  ///   `landingpad` instruction.
  ///
  /// - parameter type: The type of the resulting value from the landing pad.
  /// - parameter personalityFn: The personality function.
  /// - parameter clauses: A list of `catch` and `filter` clauses.  This list
  ///   must either be non-empty or the landing pad must be marked as a cleanup
  ///   instruction.
  /// - parameter cleanup: A flag indicating whether the landing pad is a
  ///   cleanup.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value of the given type representing the result of matching
  ///   a clause during unwinding.
  public func buildLandingPad(returning type: IRType, personalityFn: Function? = nil, clauses: [LandingPadClause], cleanup: Bool = false, name: String = "") -> IRInstruction {
    precondition(cleanup || !clauses.isEmpty, "Landing pad must be created with clauses or as cleanup")

    let lp: IRInstruction = LLVMBuildLandingPad(llvm, type.asLLVM(), personalityFn?.asLLVM(), UInt32(clauses.count), name)
    for clause in clauses {
      LLVMAddClause(lp.asLLVM(), clause.asLLVM())
    }
    LLVMSetCleanup(lp.asLLVM(), cleanup.llvm)
    return lp
  }

  /// Build a resume instruction to resume propagation of an existing
  /// (in-flight) exception whose unwinding was interrupted with a
  /// `landingpad` instruction.
  ///
  /// When all cleanups are finished, if an exception is not handled by the
  /// current function, unwinding resumes by calling the resume instruction,
  /// passing in the result of the `landingpad` instruction for the original
  /// landing pad.
  ///
  /// - parameter: A value representing the result of the original landing pad.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildResume(_ val: IRValue) -> IRValue {
    return LLVMBuildResume(llvm, val.asLLVM())
  }
  
  /// Build a `va_arg` instruction to access arguments passed through the
  /// "variable argument" area of a function call.
  ///
  /// This instruction is used to implement the `va_arg` macro in C.
  ///
  /// - parameter list: A value of type `va_list*`
  /// - parameter type: The type of values in the variable argument area.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value of the specified argument type.  In addition, the
  ///   `va_list` pointer is incremented to point to the next argument.
  public func buildVAArg(_ list: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildVAArg(llvm, list.asLLVM(), type.asLLVM(), name)
  }
}

// MARK: Memory Access Instructions

extension IRBuilder {
  /// Build an `alloca` to allocate stack memory to hold a value of the given
  /// type.
  ///
  /// The `alloca` instruction allocates `sizeof(<type>)*count` bytes of
  /// memory on the runtime stack, returning a pointer of the appropriate type
  /// to the program. If `count` is specified, it is the number of elements
  /// allocated, otherwise `count` is defaulted to be one. If a constant
  /// alignment is specified, the value result of the allocation is guaranteed
  /// to be aligned to at least that boundary. The alignment may not be
  /// greater than `1 << 29`. If not specified, or if zero, the target will
  /// choose a default value that is convenient and compatible with the type.
  ///
  /// The returned value is allocated in the address space specified in the data layout string for the target. If
  /// no such value is specified, the value is allocated in the default address space.
  ///
  /// - parameter type: The sized type used to determine the amount of stack
  ///   memory to allocate.
  /// - parameter count: An optional number of slots to allocate, to simulate a
  ///                    C array.
  /// - parameter alignment: The alignment of the access.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing `void`.
  public func buildAlloca(type: IRType, count: IRValue? = nil,
                          alignment: Alignment = .zero, name: String = "") -> IRInstruction {
    let allocaInst: LLVMValueRef
    if let count = count {
      allocaInst = LLVMBuildArrayAlloca(llvm, type.asLLVM(), count.asLLVM(), name)
    } else {
      allocaInst = LLVMBuildAlloca(llvm, type.asLLVM(), name)!
    }
    if !alignment.isZero {
      LLVMSetAlignment(allocaInst, alignment.rawValue)
    }
    return allocaInst
  }

  /// Build a store instruction that stores the first value into the location
  /// given in the second value.
  ///
  /// If alignment is not specified, or if zero, the target will choose a default
  /// value that is convenient and compatible with the type.
  ///
  /// - parameter val: The source value.
  /// - parameter ptr: The destination pointer to store into.
  /// - parameter ordering: The ordering effect of the fence for this store,
  ///   if any.  Defaults to a nonatomic store.
  /// - parameter volatile: Whether this is a store to a volatile memory location.
  /// - parameter alignment: The alignment of the access.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildStore(_ val: IRValue, to ptr: IRValue, ordering: AtomicOrdering = .notAtomic, volatile: Bool = false, alignment: Alignment = .zero) -> IRInstruction {
    let storeInst = LLVMBuildStore(llvm, val.asLLVM(), ptr.asLLVM())!
    LLVMSetOrdering(storeInst, ordering.llvm)
    LLVMSetVolatile(storeInst, volatile.llvm)
    if !alignment.isZero {
      LLVMSetAlignment(storeInst, alignment.rawValue)
    }
    return storeInst
  }

  /// Build a load instruction that loads a value from the location in the
  /// given value.
  ///
  /// If alignment is not specified, or if zero, the target will choose a default
  /// value that is convenient and compatible with the type.
  ///
  /// - parameter ptr: The pointer value to load from.
  /// - parameter type: The type of value loaded from the given pointer.
  /// - parameter ordering: The ordering effect of the fence for this load,
  ///   if any.  Defaults to a nonatomic load.
  /// - parameter volatile: Whether this is a load from a volatile memory location.
  /// - parameter alignment: The alignment of the access.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of a load from the given
  ///   pointer value.
  public func buildLoad(_ ptr: IRValue, type: IRType, ordering: AtomicOrdering = .notAtomic, volatile: Bool = false, alignment: Alignment = .zero, name: String = "") -> IRInstruction {
    let loadInst = LLVMBuildLoad2(llvm, type.asLLVM(), ptr.asLLVM(), name)!
    LLVMSetOrdering(loadInst, ordering.llvm)
    LLVMSetVolatile(loadInst, volatile.llvm)
    if !alignment.isZero {
      LLVMSetAlignment(loadInst, alignment.rawValue)
    }
    return loadInst
  }

  
  /// Build a `GEP` (Get Element Pointer) instruction with a resultant value
  /// that is undefined if the address is outside the actual underlying
  /// allocated object and not the address one-past-the-end.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter type: The type used to calculate pointer offsets.
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func buildInBoundsGEP(_ ptr: IRValue, type: IRType, indices: [IRValue], name: String = "") -> IRValue {
    var vals = indices.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildInBoundsGEP2(llvm, type.asLLVM(), ptr.asLLVM(), buf.baseAddress, UInt32(buf.count), name)
    }
  }

  /// Build a GEP (Get Element Pointer) instruction.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter type: The type used to calculate pointer offsets.
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  public func buildGEP(_ ptr: IRValue, type: IRType, indices: [IRValue], name: String = "") -> IRValue {
    var vals = indices.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildGEP2(llvm, type.asLLVM(), ptr.asLLVM(), buf.baseAddress, UInt32(buf.count), name)
    }
  }

  /// Build a GEP (Get Element Pointer) instruction suitable for indexing into
  /// a struct of a given type.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter type: The type of the struct to index into.
  /// - parameter index: The offset from the base for the index calculation.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   struct value.
  public func buildStructGEP(_ ptr: IRValue, type: IRType, index: Int, name: String = "") -> IRValue {
    return LLVMBuildStructGEP2(llvm, type.asLLVM(), ptr.asLLVM(), UInt32(index), name)
  }
  
  /// Build an ExtractValue instruction to retrieve an indexed value from a
  /// struct or array value.
  ///
  /// `extractvalue` function like a GEP, but has different indexing semantics:
  ///
  /// - Since the value being indexed is not a pointer, the first index is
  /// omitted and assumed to be zero.
  /// - Not only struct indices but also array indices must be in bounds.
  ///
  /// - parameter value: The struct or array you're indexing into.
  /// - parameter index: The index at which to extract.
  ///
  /// - returns: The value in the struct at the provided index.
  public func buildExtractValue(_ value: IRValue, index: Int,
                                name: String = "") -> IRValue {
    return LLVMBuildExtractValue(llvm, value.asLLVM(), UInt32(index), name)
  }
}

// MARK: Null Test Instructions

extension IRBuilder {
  /// Build a comparision instruction that returns whether the given operand is
  /// `null`.
  ///
  /// - parameter val: The value to test.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An `i1`` value representing the result of a test to see if the
  ///   value is `null`.
  public func buildIsNull(_ val: IRValue, name: String = "") -> IRValue {
    return LLVMBuildIsNull(llvm, val.asLLVM(), name)
  }

  /// Build a comparision instruction that returns whether the given operand is
  /// not `null`.
  ///
  /// - parameter val: The value to test.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An `i1`` value representing the result of a test to see if the
  ///   value is not `null`.
  public func buildIsNotNull(_ val: IRValue, name: String = "") -> IRValue {
    return LLVMBuildIsNotNull(llvm, val.asLLVM(), name)
  }
}

// MARK: Conversion Instructions

extension IRBuilder {
  /// Build an instruction that either performs a truncation or a bitcast of
  /// the given value to a value of the given type.
  ///
  /// - parameter val: The value to cast or truncate.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of truncating or bitcasting the
  ///   given value to fit the given type.
  public func buildTruncOrBitCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildTruncOrBitCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build an instruction that either performs a zero extension or a bitcast of
  /// the given value to a value of the given type with a wider width.
  ///
  /// - parameter val: The value to zero extend.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of zero extending or bitcasting
  ///   the given value to fit the given type.
  public func buildZExtOrBitCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildZExtOrBitCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build a bitcast instruction to convert the given value to a value of the
  /// given type by just copying the bit pattern.
  ///
  /// The `bitcast` instruction is always a no-op cast because no bits change
  /// with this conversion. The conversion is done as if the value had been
  /// stored to memory and read back as the given type. Pointer (or vector of
  /// pointer) types may only be converted to other pointer (or vector of
  /// pointer) types with the same address space through this instruction. To
  /// convert pointers to other types, see `buildIntToPtr(_:type:name:)` or
  /// `buildPtrToInt(_:type:name:)`.
  ///
  /// - parameter val: The value to bitcast.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of bitcasting the given value
  ///   to fit the given type.
  public func buildBitCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildBitCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build a cast instruction to convert the given floating-point value to a
  /// value of the given type.
  ///
  /// - parameter val: The value to cast.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of casting the given value
  ///   to fit the given type.
  public func buildFPCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildFPCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build an address space cast instruction that converts a pointer value
  /// to a given type in a different address space.
  ///
  /// The `addrspacecast` instruction can be a no-op cast or a complex value
  /// modification, depending on the target and the address space pair. Pointer
  /// conversions within the same address space must be performed with the
  /// `bitcast` instruction. Note that if the address space conversion is legal
  /// then both result and operand refer to the same memory location.
  ///
  /// This instruction must be used in lieu of a `bitcast` even if the cast is between
  /// types of the same size.
  ///
  /// The address spaces of the value and the destination pointer types must
  /// be distinct.
  public func buildAddrSpaceCast(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildAddrSpaceCast(llvm, val.asLLVM(), type.asLLVM(), name)
  }
  
  /// Build a truncate instruction to truncate the given value to the given
  /// type with a shorter width.
  ///
  /// - parameter val: The value to truncate.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of truncating the given value
  ///   to fit the given type.
  public func buildTrunc(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildTrunc(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build a sign extension instruction to sign extend the given value to
  /// the given type with a wider width.
  ///
  /// - parameter val: The value to sign extend.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of sign extending the given
  ///   value to fit the given type.
  public func buildSExt(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildSExt(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build a zero extension instruction to zero extend the given value to the
  /// given type with a wider width.
  ///
  /// - parameter val: The value to zero extend.
  /// - parameter type: The destination type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of zero extending the given
  ///   value to fit the given type.
  public func buildZExt(_ val: IRValue, type: IRType, name: String = "") -> IRValue {
    return LLVMBuildZExt(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build an integer-to-pointer instruction to convert the given value to the
  /// given pointer type.
  ///
  /// The `inttoptr` instruction converts the given value to the given pointer
  /// type by applying either a zero extension or a truncation depending on the
  /// size of the integer value. If value is larger than the size of a pointer
  /// then a truncation is done. If value is smaller than the size of a pointer
  /// then a zero extension is done. If they are the same size, nothing is done
  /// (no-op cast).
  ///
  /// - parameter val: The integer value.
  /// - parameter type: The destination pointer type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A pointer value representing the value of the given integer
  ///   converted to the given pointer type.
  public func buildIntToPtr(_ val: IRValue, type: PointerType, name: String = "") -> IRValue {
    return LLVMBuildIntToPtr(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build a pointer-to-integer instruction to convert the given pointer value
  /// to the given integer type.
  ///
  /// The `ptrtoint` instruction converts the given pointer value to the given
  /// integer type by interpreting the pointer value as an integer and either
  /// truncating or zero extending that value to the size of the integer type.
  /// If the pointer value is smaller than the integer type then a zero
  /// extension is done. If the pointer value is larger than the integer type
  /// then a truncation is done. If they are the same size, then nothing is done
  /// (no-op cast) other than a type change.
  ///
  /// - parameter val: The pointer value.
  /// - parameter type: The destination integer type.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An integer value representing the value of the given pointer
  ///   converted to the given integer type.
  public func buildPtrToInt(_ val: IRValue, type: IntType, name: String = "") -> IRValue {
    return LLVMBuildPtrToInt(llvm, val.asLLVM(), type.asLLVM(), name)
  }

  /// Build an integer-to-floating instruction to convert the given integer
  /// value to the given floating type.
  ///
  /// - parameter val: The integer value.
  /// - parameter type: The destination integer type.
  /// - parameter signed: Whether the destination is a signed or unsigned integer.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A floating value representing the value of the given integer
  ///   converted to the given floating type.
  public func buildIntToFP(_ val: IRValue, type: FloatType, signed: Bool, name: String = "") -> IRValue {
    if signed {
      return LLVMBuildSIToFP(llvm, val.asLLVM(), type.asLLVM(), name)
    } else {
      return LLVMBuildUIToFP(llvm, val.asLLVM(), type.asLLVM(), name)
    }
  }

  /// Build a floating-to-integer instruction to convert the given floating
  /// value to the given integer type.
  ///
  /// - parameter val: The floating value.
  /// - parameter type: The destination integer type.
  /// - parameter signed: Whether the destination is a signed or unsigned integer.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: An integer value representing the value of the given float
  ///   converted to the given integer type.
  public func buildFPToInt(_ val: IRValue, type: IntType, signed: Bool, name: String = "") -> IRValue {
    if signed {
      return LLVMBuildFPToSI(llvm, val.asLLVM(), type.asLLVM(), name)
    } else {
      return LLVMBuildFPToUI(llvm, val.asLLVM(), type.asLLVM(), name)
    }
  }

  /// Build an expression that returns the difference between two pointer
  /// values, dividing out the size of the pointed-to objects.
  ///
  /// This is intended to implement C-style pointer subtraction. As such, the
  /// pointers must be appropriately aligned for their element types and
  /// pointing into the same object.
  ///
  /// - parameter lhs: The first pointer (the minuend).
  /// - parameter rhs: The second pointer (the subtrahend).
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A IRValue representing a 64-bit integer value of the difference
  ///   of the two pointer values modulo the size of the pointed-to objects.
  public func buildPointerDifference(_ lhs: IRValue, _ rhs: IRValue, name: String = "") -> IRValue {
    precondition(
      lhs.type is PointerType && rhs.type is PointerType,
      "Cannot take pointer diff of \(lhs.type) and \(rhs.type)."
    )
    return LLVMBuildPtrDiff(llvm, lhs.asLLVM(), rhs.asLLVM(), name)
  }
}

// MARK: Type Information

extension IRBuilder {
  /// Build a constant expression that returns the alignment of the given type
  /// in bytes.
  ///
  /// - parameter val: The type to evaluate the alignment of.
  ///
  /// - returns: An integer value representing the alignment of the given type
  ///   in bytes.
  public func buildAlignOf(_ val: IRType) -> IRValue {
    return LLVMAlignOf(val.asLLVM())
  }

  /// Build a constant expression that returns the size of the given type in
  /// bytes.
  ///
  /// - parameter val: The type to evaluate the size of.
  ///
  /// - returns: An integer value representing the size of the given type in
  ///   bytes.
  public func buildSizeOf(_ val: IRType) -> IRValue {
    return LLVMSizeOf(val.asLLVM())
  }
}

// MARK: Atomic Instructions

extension IRBuilder {
  /// Build a fence instruction that introduces "happens-before" edges between
  /// operations.
  ///
  /// A fence `A` which has (at least) `release` ordering semantics synchronizes
  /// with a fence `B` with (at least) `acquire` ordering semantics if and only
  /// if there exist atomic operations X and Y, both operating on some atomic
  /// object `M`, such that `A` is sequenced before `X`, `X` modifies `M`
  /// (either directly or through some side effect of a sequence headed by `X`),
  /// `Y` is sequenced before `B`, and `Y` observes `M`. This provides a
  /// happens-before dependency between `A` and `B`. Rather than an explicit
  /// fence, one (but not both) of the atomic operations `X` or `Y` might
  /// provide a release or acquire (resp.) ordering constraint and still
  /// synchronize-with the explicit fence and establish the happens-before edge.
  ///
  /// A fence which has `sequentiallyConsistent` ordering, in addition to having
  /// both `acquire` and `release` semantics specified above, participates in
  /// the global program order of other `sequentiallyConsistent` operations
  /// and/or fences.
  ///
  /// - parameter ordering: Defines the kind of "synchronizes-with" edge this
  ///   fence adds.
  /// - parameter singleThreaded: Specifies that the fence only synchronizes
  ///   with other atomics in the same thread. (This is useful for interacting
  ///   with signal handlers.) Otherwise this fence is atomic with respect to
  ///   all other code in the system.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing `void`.
  @discardableResult
  public func buildFence(ordering: AtomicOrdering, singleThreaded: Bool = false, name: String = "") -> IRInstruction {
    return LLVMBuildFence(llvm, ordering.llvm, singleThreaded.llvm, name)
  }

  /// Build an atomic compare-and-exchange instruction to atomically modify
  /// memory. It loads a value in memory and compares it to a given value. If
  /// they are equal, it tries to store a new value into the memory.
  ///
  /// - parameter ptr: The address of data to update atomically.
  /// - parameter old: The value to base the comparison on.
  /// - parameter new: The new value to write if comparison with the old value
  ///   returns true.
  /// - parameter successOrdering: Specifies how this cmpxchg synchronizes with
  ///   other atomic operations when it succeeds.
  /// - parameter failureOrdering: Specifies how this cmpxchg synchronizes with
  ///   other atomic operations when it fails.
  /// - parameter singleThreaded: Specifies that this cmpxchg only synchronizes
  ///   with other atomics in the same thread. (This is useful for interacting
  ///   with signal handlers.)  Otherwise this cmpxchg is atomic with respect to
  ///   all other code in the system.
  ///
  /// - returns: A value representing the original value at the given location
  ///   is together with a flag indicating success (true) or failure (false).
  public func buildAtomicCmpXchg(
    ptr: IRValue, of old: IRValue, to new: IRValue,
    successOrdering: AtomicOrdering, failureOrdering: AtomicOrdering,
    singleThreaded: Bool = false
  ) -> IRValue {

    if failureOrdering < .monotonic {
      fatalError("Failure ordering must be at least 'Monotonic'")
    }

    if successOrdering < .monotonic {
      fatalError("Success ordering must be at least 'Monotonic'")
    }

    if failureOrdering == .release || failureOrdering == .acquireRelease {
      fatalError("Failure ordering may not be 'Release' or 'Acquire Release'")
    }

    if failureOrdering > successOrdering {
      fatalError("Failure ordering must be no stronger than success ordering")
    }

    return LLVMBuildAtomicCmpXchg(
      llvm, ptr.asLLVM(), old.asLLVM(), new.asLLVM(),
      successOrdering.llvm, failureOrdering.llvm, singleThreaded.llvm
    )
  }

  /// Build an atomic read-modify-write instruction to atomically modify memory.
  ///
  /// - parameter atomicOp: The atomic operation to perform.
  /// - parameter ptr: The address of a value to modify.
  /// - parameter value: The second argument to the given operation.
  /// - parameter ordering: Defines the kind of "synchronizes-with" edge this
  ///   atomic operation adds.
  /// - parameter singleThreaded: Specifies that this atomicRMW instruction only
  ///   synchronizes with other atomics in the same thread. (This is useful for
  ///   interacting with signal handlers.)  Otherwise this atomicRMW is atomic
  ///   with respect to all other code in the system.
  ///
  /// - returns: A value representing the old value of the given pointer before
  ///   the atomic operation was executed.
  public func buildAtomicRMW(
    atomicOp: AtomicReadModifyWriteOperation, ptr: IRValue, value: IRValue,
    ordering: AtomicOrdering, singleThreaded: Bool = false
  ) -> IRValue {
    return LLVMBuildAtomicRMW(llvm, atomicOp.llvm, ptr.asLLVM(), value.asLLVM(), ordering.llvm, singleThreaded.llvm)
  }
}

// MARK: C Standard Library Instructions

extension IRBuilder {
  /// Build a call to the C standard library `malloc` instruction.
  /// ```
  /// (type *)malloc(sizeof(type));
  /// ```
  /// If `count` is provided, it is equivalent to:
  /// ```
  /// (type *)malloc(sizeof(type) * count);
  /// ```
  ///
  /// - parameter type: The intended result type being allocated. The result
  ///                   of the `malloc` will be a pointer to this type.
  /// - parameter count: An optional number of slots to allocate, to simulate a
  ///                    C array.
  /// - parameter name: The intended name for the `malloc`'d value.
  public func buildMalloc(_ type: IRType, count: IRValue? = nil,
                          name: String = "") -> IRInstruction {
    if let count = count {
      return LLVMBuildArrayMalloc(llvm, type.asLLVM(), count.asLLVM(), name)
    } else {
      return LLVMBuildMalloc(llvm, type.asLLVM(), name)
    }
  }

  /// Build a call to the C standard library `free` function, with the provided
  /// pointer.
  ///
  /// - parameter ptr: The pointer to `free`.
  /// - returns: The `free` instruction.
  @discardableResult
  public func buildFree(_ ptr: IRValue) -> IRInstruction {
    return LLVMBuildFree(llvm, ptr.asLLVM())
  }
}

// MARK: Memory Intrinsics

extension IRBuilder {
  /// Builds a call to the `llvm.memset.*` family of intrinsics to fill a
  /// given block of memory with a given byte value.
  ///
  /// - NOTE: Unlike the standard function `memset` defined in libc,
  /// `llvm.memset` does not return a value and may be volatile.  The address
  /// space of the source and destination values need not match.
  ///
  /// - Parameters:
  ///   - dest: A pointer value to the destination that will be filled.
  ///   - value: A byte value to fill the destination with.
  ///   - length: The number of bytes to fill.
  ///   - alignment: The alignment of the destination pointer value.
  ///   - volatile: If true, builds a volatile `llvm.memset` intrinsic, else
  ///     builds a non-volatile `llvm.memset` instrinsic.  The exact behavior of
  ///     volatile memory intrinsics is platform-dependent and should not be
  ///     relied upon to perform consistently.  For more information, see the
  ///     language reference's section on [Volatile Memory
  ///     Access](http://llvm.org/docs/LangRef.html#volatile-memory-accesses).
  @discardableResult
  public func buildMemset(
    to dest: IRValue, of value: IRValue, length: IRValue,
    alignment: Alignment, volatile: Bool = false
  ) -> IRInstruction {
    let instruction = LLVMBuildMemSet(self.llvm, dest.asLLVM(), value.asLLVM(), length.asLLVM(), alignment.rawValue)!
    LLVMSetVolatile(instruction, volatile.llvm)
    return instruction
  }

  /// Builds a call to the `llvm.memcpy.*` family of intrinsics to copy a block
  /// of memory to a given destination memory location from a given source
  /// memory location.
  ///
  /// - WARNING: It is illegal for the destination and source locations to
  ///   overlap each other.
  ///
  /// - NOTE: Unlike the standard function `memcpy` defined in libc,
  /// `llvm.memcpy` does not return a value and may be volatile.  The address
  /// space of the source and destination values need not match.
  ///
  /// - Parameters:
  ///   - dest: A pointer to the destination that will be filled.
  ///   - destAlign: The alignment of the destination pointer value.
  ///   - src: A pointer to the source that will be copied from.
  ///   - srcAlign: The alignment of the source pointer value.
  ///   - length: The number of bytes to fill.
  ///   - volatile: If true, builds a volatile `llvm.memcpy` intrinsic, else
  ///     builds a non-volatile `llvm.memcpy` instrinsic.  The exact behavior of
  ///     volatile memory intrinsics is platform-dependent and should not be
  ///     relied upon to perform consistently.  For more information, see the
  ///     language reference's section on [Volatile Memory
  ///     Access](http://llvm.org/docs/LangRef.html#volatile-memory-accesses).
  @discardableResult
  public func buildMemCpy(
    to dest: IRValue, _ destAlign: Alignment,
    from src: IRValue, _ srcAlign: Alignment,
    length: IRValue, volatile: Bool = false
  ) -> IRInstruction {
    let instruction = LLVMBuildMemCpy(self.llvm, dest.asLLVM(), destAlign.rawValue, src.asLLVM(), srcAlign.rawValue, length.asLLVM())!
    LLVMSetVolatile(instruction, volatile.llvm)
    return instruction
  }

  /// Builds a call to the `llvm.memmove.*` family of intrinsics to move a
  /// block of memory to a given destination memory location from a given source
  /// memory location.
  ///
  /// Unlike `llvm.memcpy.*`, the destination and source memory locations may
  /// overlap with each other.
  ///
  /// - NOTE: Unlike the standard function `memmove` defined in libc,
  /// `llvm.memmove` does not return a value and may be volatile.  The address
  /// space of the source and destination values need not match.
  ///
  /// - Parameters:
  ///   - dest: A pointer to the destination that will be filled.
  ///   - destAlign: The alignment of the destination pointer value.
  ///   - src: A pointer to the source that will be copied from.
  ///   - srcAlign: The alignment of the source pointer value.
  ///   - length: The number of bytes to fill.
  ///   - volatile: If true, builds a volatile `llvm.memmove` intrinsic, else
  ///     builds a non-volatile `llvm.memmove` instrinsic.  The exact behavior of
  ///     volatile memory intrinsics is platform-dependent and should not be
  ///     relied upon to perform consistently.  For more information, see the
  ///     language reference's section on [Volatile Memory
  ///     Access](http://llvm.org/docs/LangRef.html#volatile-memory-accesses).
  @discardableResult
  public func buildMemMove(
    to dest: IRValue, _ destAlign: Alignment,
    from src: IRValue, _ srcAlign: Alignment,
    length: IRValue, volatile: Bool = false
  ) -> IRInstruction {
    let instruction = LLVMBuildMemMove(self.llvm, dest.asLLVM(), destAlign.rawValue, src.asLLVM(), srcAlign.rawValue, length.asLLVM())!
    LLVMSetVolatile(instruction, volatile.llvm)
    return instruction
  }
}

// MARK: Aggregate Instructions

extension IRBuilder {
  /// Build an instruction to insert a value into a member field in an
  /// aggregate value.
  ///
  /// - parameter aggregate: A value of array or structure type.
  /// - parameter element: The value to insert.
  /// - parameter index: The index at which at which to insert the value.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing an aggregate that has been updated with
  ///   the given value at the given index.
  public func buildInsertValue(aggregate: IRValue, element: IRValue, index: Int, name: String = "") -> IRValue {
    return LLVMBuildInsertValue(llvm, aggregate.asLLVM(), element.asLLVM(), UInt32(index), name)
  }

  /// Build an instruction to extract a value from a member field in an
  /// aggregate value.
  ///
  /// An `extract value` instruction differs from a `get element pointer`
  /// instruction because the value being indexed is not a pointer and the first
  /// index is unnecessary (as it is assumed to be zero).
  ///
  /// - parameter aggregate: A value of array or structure type.
  /// - parameter index: The index at which at which to extract a value.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing an aggregate that has been updated with
  ///   the given value at the given index.
  public func buildExtractValue(aggregate: IRValue, index: Int, name: String = "") -> IRValue {
    return LLVMBuildExtractValue(llvm, aggregate.asLLVM(), UInt32(index), name)
  }
}

// MARK: Vector Instructions

extension IRBuilder {
  /// Build a vector insert instruction to nondestructively insert the given
  /// value into the given vector.
  ///
  /// - parameter vector: A value of vector type.
  /// - parameter element: The value to insert.
  /// - parameter index: The index at which to insert the value.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing a vector that has been updated with
  ///   the given value at the given index.
  public func buildInsertElement(vector: IRValue, element: IRValue, index: IRValue, name: String = "") -> IRValue {
    return LLVMBuildInsertElement(llvm, vector.asLLVM(), element.asLLVM(), index.asLLVM(), name)
  }

  /// Build an instruction to extract a single scalar element from a vector at
  /// a specified index.
  ///
  /// - parameter vector: A value of vector type.
  /// - parameter index: The index at which to insert the value.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing a scalar at the given index.
  public func buildExtractElement(vector: IRValue, index: IRValue, name: String = "") -> IRValue {
    return LLVMBuildExtractElement(llvm, vector.asLLVM(), index.asLLVM(), name)
  }

  /// Build a vector shuffle instruction to construct a permutation of elements
  /// from the two given input vectors, returning a vector with the same element
  /// type as the inputs and length that is the same as the shuffle mask.
  ///
  /// The elements of the two input vectors are numbered from left to right
  /// across both of the vectors. The shuffle mask operand specifies, for each
  /// element of the result vector, which element of the two input vectors the
  /// result element gets. If the shuffle mask is `undef`, the result vector is
  /// also `undef`. If any element of the mask operand is `undef`, that element
  /// of the result is `undef`. If the shuffle mask selects an `undef` element
  /// from one of the input vectors, the resulting element is `undef`.
  ///
  /// - parameter vector1: The first vector to shuffle.
  /// - parameter vector2: The second vector to shuffle.
  /// - parameter mask: A constant vector of `i32` values that acts as a mask
  ///   for the shuffled vectors.
  ///
  /// - returns: A value representing a vector with the same element type as the
  ///   inputs and length that is the same as the shuffle mask.
  public func buildShuffleVector(_ vector1: IRValue, and vector2: IRValue, mask: IRValue, name: String = "") -> IRValue {
    guard let maskTy = mask.type as? VectorType, maskTy.elementType is IntType else {
      fatalError("Vector shuffle mask's elements must be 32-bit integers")
    }
    return LLVMBuildShuffleVector(llvm, vector1.asLLVM(), vector2.asLLVM(), mask.asLLVM(), name)
  }
}

// MARK: Global Variable Instructions

extension IRBuilder {
  /// Build a named global of the given type.
  ///
  /// - parameter name: The name of the newly inserted global value.
  /// - parameter type: The type of the newly inserted global value.
  /// - parameter addressSpace: The optional address space where the global
  ///   variable resides.
  ///
  /// - returns: A value representing the newly inserted global variable.
  public func addGlobal(_ name: String, type: IRType, addressSpace: AddressSpace = .zero) -> Global {
    return self.module.addGlobal(name, type: type, addressSpace: addressSpace)
  }

  /// Build a named global of the given type.
  ///
  /// - parameter name: The name of the newly inserted global value.
  /// - parameter initializer: The initial value for the global variable.
  /// - parameter addressSpace: The optional address space where the global
  ///   variable resides.
  ///
  /// - returns: A value representing the newly inserted global variable.
  public func addGlobal(_ name: String, initializer: IRValue, addressSpace: AddressSpace = .zero) -> Global {
    return self.module.addGlobal(name, initializer: initializer, addressSpace: addressSpace)
  }

  /// Build a named global string consisting of an array of `i8` type filled in
  /// with the nul terminated string value.
  ///
  /// - parameter name: The name of the newly inserted global string value.
  /// - parameter value: The character contents of the newly inserted global.
  ///
  /// - returns: A value representing the newly inserted global string variable.
  public func addGlobalString(name: String, value: String) -> Global {
    return self.module.addGlobalString(name: name, value: value)
  }

  /// Build a named global variable containing the characters of the given
  /// string value as an array of `i8` type filled in with the nul terminated
  /// string value.
  ///
  /// - parameter string: The character contents of the newly inserted global.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the newly inserted global string variable.
  public func buildGlobalString(_ string: String, name: String = "") -> Global {
    return Global(llvm: LLVMBuildGlobalString(llvm, string, name))
  }

  /// Build a named global variable containing a pointer to the contents of the
  /// given string value.
  ///
  /// - parameter string: The character contents of the newly inserted global.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing a pointer to the newly inserted global
  ///   string variable.
  public func buildGlobalStringPtr(_ string: String, name: String = "") -> IRValue {
    return LLVMBuildGlobalStringPtr(llvm, string, name)
  }

  /// Build a named alias to a global value or a constant expression.
  ///
  /// Aliases, unlike function or variables, don’t create any new data. They are
  /// just a new symbol and metadata for an existing position.
  ///
  /// - parameter name: The name of the newly inserted alias.
  /// - parameter aliasee: The value or constant to alias.
  /// - parameter type: The type of the aliased value or expression.
  ///
  /// - returns: A value representing the newly created alias.
  public func addAlias(name: String, to aliasee: IRGlobal, type: IRType) -> Alias {
    return self.module.addAlias(name: name, to: aliasee, type: type)
  }
}

// MARK: Inline Assembly

extension IRBuilder {
  /// Build a value representing an inline assembly expression (as opposed to
  /// module-level inline assembly).
  ///
  /// LLVM represents inline assembler as a template string (containing the
  /// instructions to emit), a list of operand constraints (stored as a string),
  /// and some flags.
  ///
  /// The template string supports argument substitution of the operands using
  /// "$" followed by a number, to indicate substitution of the given
  /// register/memory location, as specified by the constraint string.
  /// "${NUM:MODIFIER}" may also be used, where MODIFIER is a target-specific
  /// annotation for how to print the operand (see [Asm Template Argument
  /// Modifiers](https://llvm.org/docs/LangRef.html#inline-asm-modifiers)).
  ///
  /// LLVM’s support for inline asm is modeled closely on the requirements of
  /// Clang’s GCC-compatible inline-asm support. Thus, the feature-set and the
  /// constraint and modifier codes are similar or identical to those in GCC’s
  /// inline asm support.
  ///
  /// However, the syntax of the template and constraint strings is not the
  /// same as the syntax accepted by GCC and Clang, and, while most constraint
  /// letters are passed through as-is by Clang, some get translated to other
  /// codes when converting from the C source to the LLVM assembly.
  ///
  /// - parameter asm: The inline assembly expression template string.
  /// - parameter type: The type of the parameters and return value of the
  ///   assembly expression string.
  /// - parameter constraints: A comma-separated string, each element containing
  ///   one or more constraint codes.
  /// - parameter hasSideEffects: Whether this inline asm expression has
  ///   side effects.  Defaults to `false`.
  /// - parameter needsAlignedStack: Whether the function containing the
  ///   asm needs to align its stack conservatively.  Defaults to `true`.
  ///
  /// - returns: A representation of the newly created inline assembly
  ///   expression.
  public func buildInlineAssembly(
    _ asm: String, dialect: InlineAssemblyDialect, type: FunctionType,
    constraints: String = "",
    hasSideEffects: Bool = true, needsAlignedStack: Bool = true
  ) -> IRValue {
    var asm = asm.utf8CString
    var constraints = constraints.utf8CString
    return asm.withUnsafeMutableBufferPointer { asm in
      return constraints.withUnsafeMutableBufferPointer { constraints in
        return LLVMGetInlineAsm(type.asLLVM(),
                                asm.baseAddress, asm.count,
                                constraints.baseAddress, constraints.count,
                                hasSideEffects.llvm, needsAlignedStack.llvm,
                                dialect.llvm, 1)
      }
    }
  }
}

// MARK: Deprecated APIs

extension IRBuilder {
  /// Build a load instruction that loads a value from the location in the
  /// given value.
  ///
  /// If alignment is not specified, or if zero, the target will choose a default
  /// value that is convenient and compatible with the type.
  ///
  /// - parameter ptr: The pointer value to load from.
  /// - parameter ordering: The ordering effect of the fence for this load,
  ///   if any.  Defaults to a nonatomic load.
  /// - parameter volatile: Whether this is a load from a volatile memory location.
  /// - parameter alignment: The alignment of the access.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the result of a load from the given
  ///   pointer value.
  @available(*, deprecated, message: "Use buildLoad(_:type:ordering:volatile:alignment:name) instead")
  public func buildLoad(_ ptr: IRValue, ordering: AtomicOrdering = .notAtomic, volatile: Bool = false, alignment: Alignment = .zero, name: String = "") -> IRInstruction {
    let loadInst = LLVMBuildLoad(llvm, ptr.asLLVM(), name)!
    LLVMSetOrdering(loadInst, ordering.llvm)
    LLVMSetVolatile(loadInst, volatile.llvm)
    if !alignment.isZero {
      LLVMSetAlignment(loadInst, alignment.rawValue)
    }
    return loadInst
  }

  /// Build a GEP (Get Element Pointer) instruction suitable for indexing into
  /// a struct.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter index: The offset from the base for the index calculation.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   struct value.
  @available(*, deprecated, message: "Use buildStructGEP(_:type:index:name) instead")
  public func buildStructGEP(_ ptr: IRValue, index: Int, name: String = "") -> IRValue {
    return LLVMBuildStructGEP(llvm, ptr.asLLVM(), UInt32(index), name)
  }

  /// Build a GEP (Get Element Pointer) instruction.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  @available(*, deprecated, message: "Use buildGEP(_:type:indices:name) instead")
  public func buildGEP(_ ptr: IRValue, indices: [IRValue], name: String = "") -> IRValue {
    var vals = indices.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildGEP(llvm, ptr.asLLVM(), buf.baseAddress, UInt32(buf.count), name)
    }
  }

  /// Build a `GEP` (Get Element Pointer) instruction with a resultant value
  /// that is undefined if the address is outside the actual underlying
  /// allocated object and not the address one-past-the-end.
  ///
  /// The `GEP` instruction is often the source of confusion.  LLVM [provides a
  /// document](http://llvm.org/docs/GetElementPtr.html) to answer questions
  /// around its semantics and correct usage.
  ///
  /// - parameter ptr: The base address for the index calculation.
  /// - parameter indices: A list of indices that indicate which of the elements
  ///   of the aggregate object are indexed.
  /// - parameter name: The name for the newly inserted instruction.
  ///
  /// - returns: A value representing the address of a subelement of the given
  ///   aggregate data structure value.
  @available(*, deprecated, message: "Use buildInBoundsGEP(_:type:indices:name) instead")
  public func buildInBoundsGEP(_ ptr: IRValue, indices: [IRValue], name: String = "") -> IRValue {
    var vals = indices.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return LLVMBuildInBoundsGEP(llvm, ptr.asLLVM(), buf.baseAddress, UInt32(buf.count), name)
    }
  }
}


private func lowerVector(_ type: IRType) -> IRType {
    guard let vectorType = type as? VectorType else {
        return type
    }

    return vectorType.elementType
}

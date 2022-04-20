//
//  IRValue+Kinds.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

// Automatically generated from the macros in llvm/Core.h

public extension IRValue {

  /// Whether or not the underlying LLVM value is an `Argument`
  var isAArgument: Bool {
    return LLVMIsAArgument(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `BasicBlock`
  var isABasicBlock: Bool {
    return LLVMIsABasicBlock(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is `InlineAsm`
  var isAInlineAsm: Bool {
    return LLVMIsAInlineAsm(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `User`
  var isAUser: Bool {
    return LLVMIsAUser(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `Constant`
  var isAConstant: Bool {
    return LLVMIsAConstant(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `BlockAddress`
  var isABlockAddress: Bool {
    return LLVMIsABlockAddress(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantAggregateZero`
  var isAConstantAggregateZero: Bool {
    return LLVMIsAConstantAggregateZero(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantArray`
  var isAConstantArray: Bool {
    return LLVMIsAConstantArray(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantDataSequential`
  var isAConstantDataSequential: Bool {
    return LLVMIsAConstantDataSequential(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantDataArray`
  var isAConstantDataArray: Bool {
    return LLVMIsAConstantDataArray(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantDataVector`
  var isAConstantDataVector: Bool {
    return LLVMIsAConstantDataVector(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantExpr`
  var isAConstantExpr: Bool {
    return LLVMIsAConstantExpr(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantFP`
  var isAConstantFP: Bool {
    return LLVMIsAConstantFP(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantInt`
  var isAConstantInt: Bool {
    return LLVMIsAConstantInt(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantPointerNull`
  var isAConstantPointerNull: Bool {
    return LLVMIsAConstantPointerNull(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantStruct`
  var isAConstantStruct: Bool {
    return LLVMIsAConstantStruct(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantTokenNone`
  var isAConstantTokenNone: Bool {
    return LLVMIsAConstantTokenNone(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ConstantVector`
  var isAConstantVector: Bool {
    return LLVMIsAConstantVector(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `GlobalValue`
  var isAGlobalValue: Bool {
    return LLVMIsAGlobalValue(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `GlobalAlias`
  var isAGlobalAlias: Bool {
    return LLVMIsAGlobalAlias(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `GlobalObject`
  var isAGlobalObject: Bool {
    return LLVMIsAGlobalObject(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `Function`
  var isAFunction: Bool {
    return LLVMIsAFunction(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `GlobalVariable`
  var isAGlobalVariable: Bool {
    return LLVMIsAGlobalVariable(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `UndefValue`
  var isAUndefValue: Bool {
    return LLVMIsAUndefValue(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `Instruction`
  var isAInstruction: Bool {
    return LLVMIsAInstruction(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `BinaryOperator`
  var isABinaryOperator: Bool {
    return LLVMIsABinaryOperator(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CallInst`
  var isACallInst: Bool {
    return LLVMIsACallInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `IntrinsicInst`
  var isAIntrinsicInst: Bool {
    return LLVMIsAIntrinsicInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `DbgInfoIntrinsic`
  var isADbgInfoIntrinsic: Bool {
    return LLVMIsADbgInfoIntrinsic(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `DbgDeclareInst`
  var isADbgDeclareInst: Bool {
    return LLVMIsADbgDeclareInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `MemIntrinsic`
  var isAMemIntrinsic: Bool {
    return LLVMIsAMemIntrinsic(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `MemCpyInst`
  var isAMemCpyInst: Bool {
    return LLVMIsAMemCpyInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `MemMoveInst`
  var isAMemMoveInst: Bool {
    return LLVMIsAMemMoveInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `MemSetInst`
  var isAMemSetInst: Bool {
    return LLVMIsAMemSetInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CmpInst`
  var isACmpInst: Bool {
    return LLVMIsACmpInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `FCmpInst`
  var isAFCmpInst: Bool {
    return LLVMIsAFCmpInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `ICmpInst`
  var isAICmpInst: Bool {
    return LLVMIsAICmpInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `ExtractElementInst`
  var isAExtractElementInst: Bool {
    return LLVMIsAExtractElementInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `GetElementPtrInst`
  var isAGetElementPtrInst: Bool {
    return LLVMIsAGetElementPtrInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `InsertElementInst`
  var isAInsertElementInst: Bool {
    return LLVMIsAInsertElementInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `InsertValueInst`
  var isAInsertValueInst: Bool {
    return LLVMIsAInsertValueInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `LandingPadInst`
  var isALandingPadInst: Bool {
    return LLVMIsALandingPadInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `PHINode`
  var isAPHINode: Bool {
    return LLVMIsAPHINode(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `SelectInst`
  var isASelectInst: Bool {
    return LLVMIsASelectInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ShuffleVectorInst`
  var isAShuffleVectorInst: Bool {
    return LLVMIsAShuffleVectorInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `StoreInst`
  var isAStoreInst: Bool {
    return LLVMIsAStoreInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `TerminatorInst`
  var isATerminatorInst: Bool {
    return LLVMIsATerminatorInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `BranchInst`
  var isABranchInst: Bool {
    return LLVMIsABranchInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `IndirectBrInst`
  var isAIndirectBrInst: Bool {
    return LLVMIsAIndirectBrInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `InvokeInst`
  var isAInvokeInst: Bool {
    return LLVMIsAInvokeInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ReturnInst`
  var isAReturnInst: Bool {
    return LLVMIsAReturnInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `SwitchInst`
  var isASwitchInst: Bool {
    return LLVMIsASwitchInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `UnreachableInst`
  var isAUnreachableInst: Bool {
    return LLVMIsAUnreachableInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ResumeInst`
  var isAResumeInst: Bool {
    return LLVMIsAResumeInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CleanupReturnInst`
  var isACleanupReturnInst: Bool {
    return LLVMIsACleanupReturnInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CatchReturnInst`
  var isACatchReturnInst: Bool {
    return LLVMIsACatchReturnInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `FuncletPadInst`
  var isAFuncletPadInst: Bool {
    return LLVMIsAFuncletPadInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CatchPadInst`
  var isACatchPadInst: Bool {
    return LLVMIsACatchPadInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CleanupPadInst`
  var isACleanupPadInst: Bool {
    return LLVMIsACleanupPadInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `UnaryInstruction`
  var isAUnaryInstruction: Bool {
    return LLVMIsAUnaryInstruction(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `AllocaInst`
  var isAAllocaInst: Bool {
    return LLVMIsAAllocaInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `CastInst`
  var isACastInst: Bool {
    return LLVMIsACastInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `AddrSpaceCastInst`
  var isAAddrSpaceCastInst: Bool {
    return LLVMIsAAddrSpaceCastInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `BitCastInst`
  var isABitCastInst: Bool {
    return LLVMIsABitCastInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `FPExtInst`
  var isAFPExtInst: Bool {
    return LLVMIsAFPExtInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `FPToSIInst`
  var isAFPToSIInst: Bool {
    return LLVMIsAFPToSIInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `FPToUIInst`
  var isAFPToUIInst: Bool {
    return LLVMIsAFPToUIInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `FPTruncInst`
  var isAFPTruncInst: Bool {
    return LLVMIsAFPTruncInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is an `IntToPtrInst`
  var isAIntToPtrInst: Bool {
    return LLVMIsAIntToPtrInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `PtrToIntInst`
  var isAPtrToIntInst: Bool {
    return LLVMIsAPtrToIntInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `SExtInst`
  var isASExtInst: Bool {
    return LLVMIsASExtInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `SIToFPInst`
  var isASIToFPInst: Bool {
    return LLVMIsASIToFPInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `TruncInst`
  var isATruncInst: Bool {
    return LLVMIsATruncInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `UIToFPInst`
  var isAUIToFPInst: Bool {
    return LLVMIsAUIToFPInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ZExtInst`
  var isAZExtInst: Bool {
    return LLVMIsAZExtInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `ExtractValueInst`
  var isAExtractValueInst: Bool {
    return LLVMIsAExtractValueInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `LoadInst`
  var isALoadInst: Bool {
    return LLVMIsALoadInst(asLLVM()) != nil
  }

  /// Whether or not the underlying LLVM value is a `VAArgInst`
  var isAVAArgInst: Bool {
    return LLVMIsAVAArgInst(asLLVM()) != nil
  }
}

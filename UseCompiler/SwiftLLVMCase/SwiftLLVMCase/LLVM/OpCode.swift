//
//  OpCode.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// Enumerates the opcodes of instructions available in the LLVM IR language.
public enum OpCode: CaseIterable {
  // MARK: Terminator Instructions

  /// The opcode for the `ret` instruction.
  case ret
  /// The opcode for the `br` instruction.
  case br
  /// The opcode for the `switch` instruction.
  case `switch`
  /// The opcode for the `indirectBr` instruction.
  case indirectBr
  /// The opcode for the `invoke` instruction.
  case invoke
  /// The opcode for the `unreachable` instruction.
  case unreachable

  // MARK: Standard Binary Operators

  /// The opcode for the `add` instruction.
  case add
  /// The opcode for the `fadd` instruction.
  case fadd
  /// The opcode for the `sub` instruction.
  case sub
  /// The opcode for the `fsub` instruction.
  case fsub
  /// The opcode for the `mul` instruction.
  case mul
  /// The opcode for the `fmul` instruction.
  case fmul
  /// The opcode for the `udiv` instruction.
  case udiv
  /// The opcode for the `sdiv` instruction.
  case sdiv
  /// The opcode for the `fdiv` instruction.
  case fdiv
  /// The opcode for the `urem` instruction.
  case urem
  /// The opcode for the `srem` instruction.
  case srem
  /// The opcode for the `frem` instruction.
  case frem

  // MARK: Logical Operators

  /// The opcode for the `shl` instruction.
  case shl
  /// The opcode for the `lshr` instruction.
  case lshr
  /// The opcode for the `ashr` instruction.
  case ashr
  /// The opcode for the `and` instruction.
  case and
  /// The opcode for the `or` instruction.
  case or
  /// The opcode for the `xor` instruction.
  case xor

  // MARK: Memory Operators

  /// The opcode for the `alloca` instruction.
  case alloca
  /// The opcode for the `load` instruction.
  case load
  /// The opcode for the `store` instruction.
  case store
  /// The opcode for the `getElementPtr` instruction.
  case getElementPtr

  // MARK: Cast Operators

  /// The opcode for the `trunc` instruction.
  case trunc
  /// The opcode for the `zext` instruction.
  case zext
  /// The opcode for the `sext` instruction.
  case sext
  /// The opcode for the `fpToUI` instruction.
  case fpToUI
  /// The opcode for the `fpToSI` instruction.
  case fpToSI
  /// The opcode for the `uiToFP` instruction.
  case uiToFP
  /// The opcode for the `siToFP` instruction.
  case siToFP
  /// The opcode for the `fpTrunc` instruction.
  case fpTrunc
  /// The opcode for the `fpExt` instruction.
  case fpExt
  /// The opcode for the `ptrToInt` instruction.
  case ptrToInt
  /// The opcode for the `intToPtr` instruction.
  case intToPtr
  /// The opcode for the `bitCast` instruction.
  case bitCast
  /// The opcode for the `addrSpaceCast` instruction.
  case addrSpaceCast

  // MARK: Other Operators

  /// The opcode for the `icmp` instruction.
  case icmp
  /// The opcode for the `fcmp` instruction.
  case fcmp
  /// The opcode for the `PHI` instruction.
  case phi
  /// The opcode for the `call` instruction.
  case call
  /// The opcode for the `select` instruction.
  case select
  /// The opcode for the `userOp1` instruction.
  case userOp1
  /// The opcode for the `userOp2` instruction.
  case userOp2
  /// The opcode for the `vaArg` instruction.
  case vaArg
  /// The opcode for the `extractElement` instruction.
  case extractElement
  /// The opcode for the `insertElement` instruction.
  case insertElement
  /// The opcode for the `shuffleVector` instruction.
  case shuffleVector
  /// The opcode for the `extractValue` instruction.
  case extractValue
  /// The opcode for the `insertValue` instruction.
  case insertValue

  // MARK: Atomic operators

  /// The opcode for the `fence` instruction.
  case fence
  /// The opcode for the `atomicCmpXchg` instruction.
  case atomicCmpXchg
  /// The opcode for the `atomicRMW` instruction.
  case atomicRMW

  // MARK: Exception Handling Operators

  /// The opcode for the `resume` instruction.
  case resume
  /// The opcode for the `landingPad` instruction.
  case landingPad
  /// The opcode for the `cleanupRet` instruction.
  case cleanupRet
  /// The opcode for the `catchRet` instruction.
  case catchRet
  /// The opcode for the `catchPad` instruction.
  case catchPad
  /// The opcode for the `cleanupPad` instruction.
  case cleanupPad
  /// The opcode for the `catchSwitch` instruction.
  case catchSwitch

  /// Creates an `OpCode` from an `LLVMOpcode`
  init(rawValue: LLVMOpcode) {
    switch rawValue {
    case LLVMRet: self = .ret
    case LLVMBr: self = .br
    case LLVMSwitch: self = .switch
    case LLVMIndirectBr: self = .indirectBr
    case LLVMInvoke: self = .invoke
    case LLVMUnreachable: self = .unreachable
    case LLVMAdd: self = .add
    case LLVMFAdd: self = .fadd
    case LLVMSub: self = .sub
    case LLVMFSub: self = .fsub
    case LLVMMul: self = .mul
    case LLVMFMul: self = .fmul
    case LLVMUDiv: self = .udiv
    case LLVMSDiv: self = .sdiv
    case LLVMFDiv: self = .fdiv
    case LLVMURem: self = .urem
    case LLVMSRem: self = .srem
    case LLVMFRem: self = .frem
    case LLVMShl: self = .shl
    case LLVMLShr: self = .lshr
    case LLVMAShr: self = .ashr
    case LLVMAnd: self = .and
    case LLVMOr: self = .or
    case LLVMXor: self = .xor
    case LLVMAlloca: self = .alloca
    case LLVMLoad: self = .load
    case LLVMStore: self = .store
    case LLVMGetElementPtr: self = .getElementPtr
    case LLVMTrunc: self = .trunc
    case LLVMZExt: self = .zext
    case LLVMSExt: self = .sext
    case LLVMFPToUI: self = .fpToUI
    case LLVMFPToSI: self = .fpToSI
    case LLVMUIToFP: self = .uiToFP
    case LLVMSIToFP: self = .siToFP
    case LLVMFPTrunc: self = .fpTrunc
    case LLVMFPExt: self = .fpExt
    case LLVMPtrToInt: self = .ptrToInt
    case LLVMIntToPtr: self = .intToPtr
    case LLVMBitCast: self = .bitCast
    case LLVMAddrSpaceCast: self = .addrSpaceCast
    case LLVMICmp: self = .icmp
    case LLVMFCmp: self = .fcmp
    case LLVMPHI: self = .phi
    case LLVMCall: self = .call
    case LLVMSelect: self = .select
    case LLVMUserOp1: self = .userOp1
    case LLVMUserOp2: self = .userOp2
    case LLVMVAArg: self = .vaArg
    case LLVMExtractElement: self = .extractElement
    case LLVMInsertElement: self = .insertElement
    case LLVMShuffleVector: self = .shuffleVector
    case LLVMExtractValue: self = .extractValue
    case LLVMInsertValue: self = .insertValue
    case LLVMFence: self = .fence
    case LLVMAtomicCmpXchg: self = .atomicCmpXchg
    case LLVMAtomicRMW: self = .atomicRMW
    case LLVMResume: self = .resume
    case LLVMLandingPad: self = .landingPad
    case LLVMCleanupRet: self = .cleanupRet
    case LLVMCatchRet: self = .catchRet
    case LLVMCatchPad: self = .catchPad
    case LLVMCleanupPad: self = .cleanupPad
    case LLVMCatchSwitch: self = .catchSwitch
    default: fatalError("invalid LLVMOpcode \(rawValue)")
    }
  }
}

extension OpCode {
  /// `BinaryOperation` enumerates the subset of opcodes that are binary operations.
  public enum Binary: CaseIterable {
    /// The `add` instruction.
    case add
    /// The `fadd` instruction.
    case fadd
    /// The `sub` instruction.
    case sub
    /// The `fsub` instruction.
    case fsub
    /// The `mul` instruction.
    case mul
    /// The `fmul` instruction.
    case fmul
    /// The `udiv` instruction.
    case udiv
    /// The `sdiv` instruction.
    case sdiv
    /// The `fdiv` instruction.
    case fdiv
    /// The `urem` instruction.
    case urem
    /// The `srem` instruction.
    case srem
    /// The `frem` instruction.
    case frem

    /// The `shl` instruction.
    case shl
    /// The `lshr` instruction.
    case lshr
    /// The `ashr` instruction.
    case ashr
    /// The `and` instruction.
    case and
    /// The `or` instruction.
    case or
    /// The `xor` instruction.
    case xor

    static let binaryOperationMap: [Binary: LLVMOpcode] = [
      .add: LLVMAdd, .fadd: LLVMFAdd, .sub: LLVMSub, .fsub: LLVMFSub,
      .mul: LLVMMul, .fmul: LLVMFMul, .udiv: LLVMUDiv, .sdiv: LLVMSDiv,
      .fdiv: LLVMFDiv, .urem: LLVMURem, .srem: LLVMSRem, .frem: LLVMFRem,
      .shl: LLVMShl, .lshr: LLVMLShr, .ashr: LLVMAShr, .and: LLVMAnd,
      .or: LLVMOr, .xor: LLVMXor,
    ]

    /// Retrieves the corresponding `LLVMOpcode`.
    public var llvm: LLVMOpcode {
      return Binary.binaryOperationMap[self]!
    }

    /// Retrieves the corresponding opcode for this binary operation.
    public var opCode: OpCode {
      return OpCode(rawValue: self.llvm)
    }
  }

  /// `CastOperation` enumerates the subset of opcodes that are cast operations.
  public enum Cast: CaseIterable {
    /// The `trunc` instruction.
    case trunc
    /// The `zext` instruction.
    case zext
    /// The `sext` instruction.
    case sext
    /// The `fpToUI` instruction.
    case fpToUI
    /// The `fpToSI` instruction.
    case fpToSI
    /// The `uiToFP` instruction.
    case uiToFP
    /// The `siToFP` instruction.
    case siToFP
    /// The `fpTrunc` instruction.
    case fpTrunc
    /// The `fpext` instruction.
    case fpext
    /// The `ptrToInt` instruction.
    case ptrToInt
    /// The `intToPtr` instruction.
    case intToPtr
    /// The `bitCast` instruction.
    case bitCast
    /// The `addrSpaceCast` instruction.
    case addrSpaceCast

    static let castOperationMap: [Cast: LLVMOpcode] = [
      .trunc: LLVMTrunc,
      .zext: LLVMZExt,
      .sext: LLVMSExt,
      .fpToUI: LLVMFPToUI,
      .fpToSI: LLVMFPToSI,
      .uiToFP: LLVMUIToFP,
      .siToFP: LLVMSIToFP,
      .fpTrunc: LLVMFPTrunc,
      .fpext: LLVMFPExt,
      .ptrToInt: LLVMPtrToInt,
      .intToPtr: LLVMIntToPtr,
      .bitCast: LLVMBitCast,
      .addrSpaceCast: LLVMAddrSpaceCast,
    ]
    
    /// Retrieves the corresponding `LLVMOpcode`.
    public var llvm: LLVMOpcode {
      return Cast.castOperationMap[self]!
    }

    /// Retrieves the corresponding opcode for this cast operation.
    public var opCode: OpCode {
      return OpCode(rawValue: self.llvm)
    }
  }
}

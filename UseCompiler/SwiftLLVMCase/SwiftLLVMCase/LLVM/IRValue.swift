//
//  IRValue.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// An `IRValue` is a type that is capable of lowering itself to an
/// `LLVMValueRef` object for use with LLVM's C API.
public protocol IRValue {
  /// Retrieves the underlying LLVM value object.
  func asLLVM() -> LLVMValueRef
}

public extension IRValue {
  /// Retrieves the type of this value.
  var type: IRType {
    return convertType(LLVMTypeOf(asLLVM()))
  }

  /// Returns whether this value is a constant.
  var isConstant: Bool {
    return LLVMIsConstant(asLLVM()) != 0
  }

  /// Returns whether this value is an instruction.
  var isInstruction: Bool {
    return LLVMIsAInstruction(asLLVM()) != nil
  }

  /// Returns whether this value has been initialized with the special `undef`
  /// value.
  ///
  /// The `undef` value can be used anywhere a constant is expected, and
  /// indicates that the user of the value may receive an unspecified
  /// bit-pattern.
  var isUndef: Bool {
    return LLVMIsUndef(asLLVM()) != 0
  }

  /// Gets and sets the name for this value.
  var name: String {
    get {
      let ptr = LLVMGetValueName(asLLVM())!
      return String(cString: ptr)
    }
    set {
      LLVMSetValueName(asLLVM(), newValue)
    }
  }

  /// Replaces all uses of this value with the specified value.
  ///
  /// - parameter value: The new value to swap in.
  func replaceAllUses(with value: IRValue) {
    LLVMReplaceAllUsesWith(asLLVM(), value.asLLVM())
  }

  /// Dumps a representation of this value to stderr.
  func dump() {
    LLVMDumpValue(asLLVM())
  }

  /// The kind of this value.
  var kind: IRValueKind {
    return IRValueKind(llvm: LLVMGetValueKind(asLLVM()))
  }
}

/// Enumerates the kinds of values present in LLVM IR.
public enum IRValueKind {
  /// The value is an argument.
  case argument
  /// The value is a basic block.
  case basicBlock
  /// The value is a memory use.
  case memoryUse
  /// The value is a memory definition.
  case memoryDef
  /// The value is a memory phi node.
  case memoryPhi
  /// The value is a function.
  case function
  /// The value is a global alias.
  case globalAlias
  /// The value is an ifunc.
  case globalIFunc
  /// The value is a variable.
  case globalVariable
  /// The value is a block address.
  case blockAddress
  /// The value is a constant expression.
  case constantExpression
  /// The value is a constant array.
  case constantArray
  /// The value is a constant struct.
  case constantStruct
  /// The value is a constant vector.
  case constantVector
  /// The value is undef.
  case undef
  /// The value is a constant aggregate zero.
  case constantAggregateZero
  /// The value is a constant data array.
  case constantDataArray
  /// The value is a constant data vector.
  case constantDataVector
  /// The value is a constant int value.
  case constantInt
  /// The value is a constant floating pointer value.
  case constantFloat
  /// The value is a constant pointer to null.
  ///
  /// Note that this pointer is a zero bit-value pointer.  Its semantics are dependent upon the address space.
  case constantPointerNull
  /// The value is a constant none-token value.
  case constantTokenNone
  /// The value is a metadata-as-value node.
  case metadataAsValue
  /// The value is inline assembly.
  case inlineASM
  /// The value is an instruction.
  case instruction

  init(llvm: LLVMValueKind) {
    switch llvm {
    case LLVMArgumentValueKind: self = .argument
    case LLVMBasicBlockValueKind: self = .basicBlock
    case LLVMMemoryUseValueKind: self = .memoryUse
    case LLVMMemoryDefValueKind: self = .memoryDef
    case LLVMMemoryPhiValueKind: self = .memoryPhi
    case LLVMFunctionValueKind: self = .function
    case LLVMGlobalAliasValueKind: self = .globalAlias
    case LLVMGlobalIFuncValueKind: self = .globalIFunc
    case LLVMGlobalVariableValueKind: self = .globalVariable
    case LLVMBlockAddressValueKind: self = .blockAddress
    case LLVMConstantExprValueKind: self = .constantExpression
    case LLVMConstantArrayValueKind: self = .constantArray
    case LLVMConstantStructValueKind: self = .constantStruct
    case LLVMConstantVectorValueKind: self = .constantVector
    case LLVMUndefValueValueKind: self = .undef
    case LLVMConstantAggregateZeroValueKind: self = .constantAggregateZero
    case LLVMConstantDataArrayValueKind: self = .constantDataArray
    case LLVMConstantDataVectorValueKind: self = .constantDataVector
    case LLVMConstantIntValueKind: self = .constantInt
    case LLVMConstantFPValueKind: self = .constantFloat
    case LLVMConstantPointerNullValueKind: self = .constantPointerNull
    case LLVMConstantTokenNoneValueKind: self = .constantTokenNone
    case LLVMMetadataAsValueValueKind: self = .metadataAsValue
    case LLVMInlineAsmValueKind: self = .inlineASM
    case LLVMInstructionValueKind: self = .instruction
    default: fatalError("unknown IRValue kind \(llvm)")
    }
  }
}

extension LLVMValueRef: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return self
  }
}

// N.B. This conformance is strictly not correct, but LLVM-C chooses to muddy
// the difference between LLVMValueRef and a number of what should be refined
// types.  What matters is that we verify any returned `IRInstruction` values
// are actually instructions.
extension LLVMValueRef: IRInstruction {}

extension Int: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<Int>.size * 8).constant(self).asLLVM()
  }
}

extension Int8: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<Int8>.size * 8).constant(self).asLLVM()
  }
}

extension Int16: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<Int16>.size * 8).constant(self).asLLVM()
  }
}

extension Int32: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<Int32>.size * 8).constant(self).asLLVM()
  }
}

extension Int64: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<Int64>.size * 8).constant(self).asLLVM()
  }
}

extension UInt: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<UInt>.size * 8).constant(self).asLLVM()
  }
}

extension UInt8: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<UInt8>.size * 8).constant(self).asLLVM()
  }
}

extension UInt16: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<UInt16>.size * 8).constant(self).asLLVM()
  }
}

extension UInt32: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<UInt32>.size * 8).constant(self).asLLVM()
  }
}

extension UInt64: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: MemoryLayout<UInt64>.size * 8).constant(self).asLLVM()
  }
}

extension Bool: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return IntType(width: 1).constant(self ? 1 : 0).asLLVM()
  }
}

extension String: IRValue {
  /// Retrieves the underlying LLVM value object.
  public func asLLVM() -> LLVMValueRef {
    return LLVMConstString(self, UInt32(self.utf8.count), 0)
  }
}

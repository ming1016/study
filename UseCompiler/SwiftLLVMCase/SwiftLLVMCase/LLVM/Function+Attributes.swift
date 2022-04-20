//
//  Function+Attributes.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// Enumerates the kinds of attributes of LLVM functions and function parameters.
public enum AttributeKind: String {
  /// This attribute indicates that, when emitting the prologue and epilogue,
  /// the backend should forcibly align the stack pointer.
  case alignstack
  /// This attribute indicates that the annotated function will always return
  /// at least a given number of bytes (or null).
  case allocsize
  /// This attribute indicates that the inliner should attempt to inline this
  /// function into callers whenever possible, ignoring any active inlining
  /// size threshold for this caller.
  case alwaysinline
  /// This indicates that the callee function at a call site should be
  /// recognized as a built-in function, even though the function’s declaration
  /// uses the nobuiltin attribute
  case builtin
  /// This attribute indicates that this function is rarely called.
  case cold
  /// In some parallel execution models, there exist operations that cannot be
  /// made control-dependent on any additional values.
  case convergent
  /// This attribute indicates that the function may only access memory that is
  /// not accessible by the module being compiled.
  case inaccessiblememonly
  /// This attribute indicates that the function may only access memory that is
  /// either not accessible by the module being compiled, or is pointed to by
  /// its pointer arguments.
  case inaccessiblememOrArgmemonly = "inaccessiblemem_or_argmemonly"
  /// This attribute indicates that the source code contained a hint that inlin
  /// inlining this function is desirable (such as the “inline” keyword in
  /// C/C++).
  case inlinehint
  /// This attribute indicates that the function should be added to a
  /// jump-instruction table at code-generation time, and that all
  /// address-taken references to this function should be replaced with a
  /// reference to the appropriate jump-instruction-table function pointer.
  case jumptable
  /// This attribute suggests that optimization passes and code generator
  /// passes make choices that keep the code size of this function as small as
  /// possible and perform optimizations that may sacrifice runtime performance
  /// in order to minimize the size of the generated code.
  case minsize
  /// This attribute disables prologue / epilogue emission for the function.
  case naked
  /// When this attribute is set to true, the jump tables and lookup tables
  /// that can be generated from a switch case lowering are disabled.
  case noJumpTables = "no-jump-tables"
  /// This indicates that the callee function at a call site is not recognized
  /// as a built-in function.
  case nobuiltin
  /// This attribute indicates that calls to the function cannot be duplicated.
  case noduplicate
  /// This attributes disables implicit floating point instructions.
  case noimplicitfloat
  /// This attribute indicates that the inliner should never inline this
  /// function in any situation.
  case noinline
  /// This attribute suppresses lazy symbol binding for the function.
  case nonlazybind
  /// This attribute indicates that the code generator should not use a red
  /// zone, even if the target-specific ABI normally permits it.
  case noredzone
  /// This function attribute indicates that the function never returns
  /// normally.
  case noreturn
  /// This function attribute indicates that the function does not call itself
  /// either directly or indirectly down any possible call path.
  case norecurse
  /// This function attribute indicates that the function never raises an
  /// exception.
  case nounwind
  /// This function attribute indicates that most optimization passes will skip
  /// this function, with the exception of interprocedural optimization passes.
  case optnone
  /// This attribute suggests that optimization passes and code generator
  /// passes make choices that keep the code size of this function low, and
  /// otherwise do optimizations specifically to reduce code size as long as
  /// they do not significantly impact runtime performance.
  case optsize
  /// This attribute indicates that the function computes its result (or
  /// decides to unwind an exception) based strictly on its arguments, without
  /// dereferencing any pointer arguments or otherwise accessing any mutable
  /// state (e.g. memory, control registers, etc) visible to caller functions.
  case readnone
  /// This attribute indicates that the function does not write through any
  /// pointer arguments (including byval arguments) or otherwise modify any
  /// state (e.g. memory, control registers, etc) visible to caller functions.
  case readonly
  /// This attribute indicates that the function may write to but does not read
  /// read from memory.
  case writeonly
  /// This attribute indicates that the only memory accesses inside function
  /// are loads and stores from objects pointed to by its pointer-typed
  /// arguments, with arbitrary offsets.
  case argmemonly
  /// This attribute indicates that this function can return twice.
  case returnsTwice = "returns_twice"
  /// This attribute indicates that SafeStack protection is enabled for this
  /// function.
  case safestack
  /// This attribute indicates that AddressSanitizer checks (dynamic address
  /// safety analysis) are enabled for this function.
  case sanitizeAddress = "sanitize_address"
  /// This attribute indicates that MemorySanitizer checks (dynamic detection
  /// of accesses to uninitialized memory) are enabled for this function.
  case sanitizeMemory = "sanitize_memory"
  /// This attribute indicates that ThreadSanitizer checks (dynamic thread
  /// safety analysis) are enabled for this function.
  case sanitizeThread = "sanitize_thread"
  /// This attribute indicates that HWAddressSanitizer checks (dynamic address
  /// safety analysis based on tagged pointers) are enabled for this function.
  case sanitizeHWAddress = "sanitize_hwaddress"
  /// This function attribute indicates that the function does not have any
  /// effects besides calculating its result and does not have undefined
  /// behavior.
  case speculatable
  /// This attribute indicates that the function should emit a stack smashing
  /// protector.
  case ssp
  /// This attribute indicates that the function should always emit a stack
  /// smashing protector
  case sspreq
  /// This attribute indicates that the function should emit a stack smashing
  /// protector.
  case sspstrong
  /// This attribute indicates that the function was called from a scope that
  /// requires strict floating point semantics.
  case strictfp
  /// This attribute indicates that the ABI being targeted requires that an
  /// unwind table entry be produced for this function even if we can show
  /// that no exceptions passes by it.
  case uwtable
  /// This indicates to the code generator that the parameter or return value
  /// should be zero-extended to the extent required by the target’s ABI by the
  /// caller (for a parameter) or the callee (for a return value).
  case zeroext
  /// This indicates to the code generator that the parameter or return value
  /// should be sign-extended to the extent required by the target’s ABI (which
  /// is usually 32-bits) by the caller (for a parameter) or the callee (for a
  /// return value).
  case signext
  /// This indicates that this parameter or return value should be treated in a
  /// special target-dependent fashion while emitting code for a function call
  /// or return.
  case inreg
  /// This indicates that the pointer parameter should really be passed by
  /// value to the function.
  case byval
  /// The inalloca argument attribute allows the caller to take the address of
  /// outgoing stack arguments
  case inalloca
  /// This indicates that the pointer parameter specifies the address of a
  /// structure that is the return value of the function in the source program.
  case sret
  /// This indicates that the pointer value may be assumed by the optimizer to
  /// have the specified alignment.
  case align
  /// This indicates that objects accessed via pointer values based on the
  /// argument or return value are not also accessed, during the execution of
  /// the function, via pointer values not based on the argument or return
  /// value.
  ///
  /// The `noalias` attribute may appear in one of two location: on arguments
  /// types or on return types. On argument types, `noalias` acts like the
  /// `restrict` keyword in C and C++ and implies that no other pointer value
  /// points to this object.  On return types, `noalias` implies that the
  /// returned pointer is not aliased by any other pointer in the program.
  ///
  /// Practically, this allows LLVM to reorder accesses to this memory.
  case noalias
  /// This indicates that the callee does not make any copies of the pointer
  /// that outlive the callee itself.
  case nocapture
  /// This indicates that the pointer parameter can be excised using the
  /// trampoline intrinsics.
  case nest
  /// This indicates that the function always returns the argument as its
  /// return value.
  case returned
  /// This indicates that the parameter or return pointer is not null.
  case nonnull
  /// This indicates that the parameter or return pointer is dereferenceable.
  case dereferenceable
  /// This indicates that the parameter or return value isn’t both non-null and
  /// non-dereferenceable (up to `n` bytes) at the same time.
  case dereferenceableOrNull = "dereferenceable_or_null"
  /// This indicates that the parameter is the self/context parameter.
  case swiftself
  /// This attribute is motivated to model and optimize Swift error handling.
  case swifterror

  /// ID of the attribute.
  internal var id: UInt32 {
    return LLVMGetEnumAttributeKindForName(rawValue, rawValue.count)
  }
}

/// Represents the possible indices of function attributes.
public enum AttributeIndex: ExpressibleByIntegerLiteral, RawRepresentable {
  /// Represents the function itself.
  case function
  /// Represents the function's return value.
  case returnValue
  /// Represents the function's i-th argument.
  case argument(Int)

  public init(integerLiteral value: UInt32) {
    switch value {
    case ~0: self = .function
    case 0: self = .returnValue
    default: self = .argument(Int(value) - 1)
    }
  }

  public init?(rawValue: RawValue) {
    self.init(integerLiteral: rawValue)
  }

  public var rawValue: UInt32 {
    switch self {
    case .function: return ~0
    case .returnValue: return 0
    case .argument(let i): return UInt32(i) + 1
    }
  }
}

/// An LLVM attribute.
///
/// Functions, return types and each parameter may have a set of attributes
/// associated with them. Such attributes are used to communicate additional
/// information about a function. Attributes are considered to be part of the
/// function, but not of the function type.
public protocol Attribute {
  /// Retrieves the underlying LLVM attribute reference object.
  func asLLVM() -> LLVMAttributeRef
}

/// An "enum" (a.k.a. target-independent) attribute.
public struct EnumAttribute: Attribute {
  internal let llvm: LLVMAttributeRef
  internal init(llvm: LLVMAttributeRef) {
    self.llvm = llvm
  }

  /// The kind ID of the attribute.
  internal var kindID: UInt32 {
    return LLVMGetEnumAttributeKind(llvm)
  }

  /// The value of the attribute.
  public var value: UInt64 {
    return LLVMGetEnumAttributeValue(llvm)
  }

  /// Retrieves the underlying LLVM attribute object.
  public func asLLVM() -> LLVMAttributeRef {
    return llvm
  }
}

/// A "string" (a.k.a. target-dependent) attribute.
public struct StringAttribute: Attribute {
  internal let llvm: LLVMAttributeRef
  internal init(llvm: LLVMAttributeRef) {
    self.llvm = llvm
  }

  /// The name of the attribute.
  public var name: String {
    var length: UInt32 = 0
    let cstring = LLVMGetStringAttributeKind(llvm, &length)
    return String.init(cString: cstring!)
  }

  /// The value of the attribute.
  public var value: String {
    var length: UInt32 = 0
    let cstring = LLVMGetStringAttributeValue(llvm, &length)
    return String.init(cString: cstring!)
  }

  /// Retrieves the underlying LLVM attribute object.
  public func asLLVM() -> LLVMAttributeRef {
    return llvm
  }
}

extension Function {
  /// Adds an enum attribute to the function, its return value or one of its
  /// parameters.
  ///
  /// - parameter attrKind: The kind of the attribute to add.
  /// - parameter value: The optional value of the attribute.
  /// - parameter index: The index representing the function, its return value
  ///   or one of its parameters.
  @discardableResult
  public func addAttribute(_ attrKind: AttributeKind, value: UInt64 = 0, to index: AttributeIndex) -> EnumAttribute {
    let ctx = LLVMGetModuleContext(LLVMGetGlobalParent(llvm))
    let attrRef = LLVMCreateEnumAttribute(ctx, attrKind.id, value)
    LLVMAddAttributeAtIndex(llvm, index.rawValue, attrRef)
    return EnumAttribute(llvm: attrRef!)
  }

  /// Adds a string attribute to the function, its return value or one of its
  /// parameters.
  ///
  /// - parameter name: The name of the attribute to add.
  /// - parameter value: The optional value of the attribute.
  /// - parameter index: The index representing the function, its return value
  ///   or one of its parameters.
  @discardableResult
  public func addAttribute(_ name: String, value: String = "", to index: AttributeIndex) -> StringAttribute {
    let ctx = LLVMGetModuleContext(LLVMGetGlobalParent(llvm))
    let attrRef = name.withCString { cname -> LLVMAttributeRef? in
      return value.withCString { cvalue in
        return LLVMCreateStringAttribute(ctx, cname, UInt32(name.count), cvalue, UInt32(value.count))
      }
    }
    LLVMAddAttributeAtIndex(llvm, index.rawValue, attrRef)
    return StringAttribute(llvm: attrRef!)
  }

  /// Removes an attribute from the function, its return value or one of its
  /// parameters.
  ///
  /// - parameter attr: The attribute to remove.
  /// - parameter index: The index representing the function, its return value
  ///   or one of its parameters.
  public func removeAttribute(_ attr: Attribute, from index: AttributeIndex) {
    switch attr {
    case let enumAttr as EnumAttribute:
      LLVMRemoveEnumAttributeAtIndex(llvm, index.rawValue, enumAttr.kindID)
    case let stringAttr as StringAttribute:
      var length: UInt32 = 0
      let cstring = LLVMGetStringAttributeKind(stringAttr.llvm, &length)
      LLVMRemoveStringAttributeAtIndex(llvm, index.rawValue, cstring, length)
    default:
      fatalError("unexpected attribute type")
    }
  }

  /// Removes an enum attribute from the function, its return value or one of
  /// its parameters.
  ///
  /// - parameter attr: The kind of the attribute to remove.
  /// - parameter index: The index representing the function, its return value
  ///   or one of its parameters.
  public func removeAttribute(_ attrKind: AttributeKind, from index: AttributeIndex) {
    LLVMRemoveEnumAttributeAtIndex(llvm, index.rawValue, attrKind.id)
  }

  /// Removes a string attribute from the function, its return value or one of
  /// its parameters.
  ///
  /// - parameter name: The name of the attribute to remove.
  /// - parameter index: The index representing the function, its return value
  ///   or one of its parameters.
  public func removeAttribute(_ name: String, from index: AttributeIndex) {
    name.withCString {
      LLVMRemoveStringAttributeAtIndex(llvm, index.rawValue, $0, UInt32(name.count))
    }
  }

  /// Gets the attributes of the function, its return value or its parameters.
  public func attributes(at index: AttributeIndex) -> [Attribute] {
    let attrCount = LLVMGetAttributeCountAtIndex(llvm, index.rawValue)
    var attrRefs: [LLVMAttributeRef?] = Array(repeating: nil, count: Int(attrCount))
    LLVMGetAttributesAtIndex(llvm, index.rawValue, &attrRefs)
    return attrRefs.map { attrRef -> Attribute in
      if LLVMIsEnumAttribute(attrRef) != 0 {
        return EnumAttribute(llvm: attrRef!)
      } else {
        return StringAttribute(llvm: attrRef!)
      }
    }
  }
}

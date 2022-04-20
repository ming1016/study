//
//  StructType.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// `StructType` is used to represent a collection of data members together in
/// memory. The elements of a structure may be any type that has a size.
///
/// Structures in memory are accessed using `load` and `store` by getting a
/// pointer to a field with the ‘getelementptr‘ instruction. Structures in
/// registers are accessed using the `extractvalue` and `insertvalue`
/// instructions.
///
/// Structures may optionally be "packed" structures, which indicate that the
/// alignment of the struct is one byte, and that there is no padding between
/// the elements. In non-packed structs, padding between field types is inserted
/// as defined by the `DataLayout` of the module, which is required to match
/// what the underlying code generator expects.
///
/// Structures can either be "literal" or "identified". A literal structure is
/// defined inline with other types (e.g. {i32, i32}*) whereas identified types
/// are always defined at the top level with a name. Literal types are uniqued
/// by their contents and can never be recursive or opaque since there is no way
/// to write one. Identified types can be recursive, can be opaqued, and are
/// never uniqued.
public struct StructType: IRType {
  internal let llvm: LLVMTypeRef

  /// Initializes a structure type from the given LLVM type object.
  public init(llvm: LLVMTypeRef) {
    self.llvm = llvm
  }

  /// Creates a structure type from an array of component element types.
  ///
  /// - parameter elementTypes: A list of types of members of this structure.
  /// - parameter isPacked: Whether or not this structure is 1-byte aligned with
  ///   no packing between fields.  Defaults to `false`.
  /// - parameter context: The context to create this type in
  /// - SeeAlso: http://llvm.org/docs/ProgrammersManual.html#achieving-isolation-with-llvmcontext
  public init(elementTypes: [IRType], isPacked: Bool = false, in context: Context = Context.global) {
    var irTypes = elementTypes.map { $0.asLLVM() as Optional }
    self.llvm = irTypes.withUnsafeMutableBufferPointer { buf in
      return LLVMStructTypeInContext(context.llvm, buf.baseAddress, UInt32(buf.count), isPacked.llvm)
    }
  }

  /// Invalidates and resets the member types of this structure.
  ///
  /// - parameter types: A list of types of members of this structure.
  /// - parameter isPacked: Whether or not this structure is 1-byte aligned with
  ///   no packing between fields.  Defaults to `false`.
  public func setBody(_ types: [IRType], isPacked: Bool = false) {
    var _types = types.map { $0.asLLVM() as Optional }
    _types.withUnsafeMutableBufferPointer { buf in
      LLVMStructSetBody(asLLVM(), buf.baseAddress, UInt32(buf.count), isPacked.llvm)
    }
  }

  /// Creates a constant value of this structure type initialized with the given
  /// list of values.
  ///
  /// - precondition: values.count == aggregate.elementCount
  /// - parameter values: A list of values of members of this structure.
  ///
  /// - returns: A value representing a constant value of this structure type.
  public func constant(values: [IRValue]) -> Constant<Struct> {
    assert(numericCast(values.count) == LLVMCountStructElementTypes(llvm),
           "The number of values must match the number of elements in the aggregate")
    var vals = values.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return Constant(llvm: LLVMConstNamedStruct(asLLVM(),
                                                 buf.baseAddress,
                                                 UInt32(buf.count)))
    }
  }

  /// Creates an constant struct value initialized with the given list of values.
  ///
  /// - parameter values: A list of values of members of this structure.
  /// - parameter isPacked: Whether or not this structure is 1-byte aligned with
  ///   no packing between fields.  Defaults to `false`.
  ///
  /// - returns: A value representing a constant struct value with given the values.
  public static func constant(values: [IRValue], isPacked: Bool = false) -> Constant<Struct> {
    var vals = values.map { $0.asLLVM() as Optional }
    return vals.withUnsafeMutableBufferPointer { buf in
      return Constant(llvm: LLVMConstStruct(buf.baseAddress,
                                            UInt32(buf.count),
                                            isPacked.llvm))
    }
  }

  /// Retrieves the name associated with this structure type, or the empty
  /// string if this type is unnamed.
  public var name: String {
    guard let sname = LLVMGetStructName(self.llvm) else { return "" }
    return String(cString: sname)
  }

  /// Retrieves the element types associated with this structure type.
  public var elementTypes: [IRType] {
    var params = [IRType]()
    let count = Int(LLVMCountStructElementTypes(self.llvm))
    let paramsPtr = UnsafeMutablePointer<LLVMTypeRef?>.allocate(capacity: count)
    defer { free(paramsPtr) }
    LLVMGetStructElementTypes(self.llvm, paramsPtr)
    for i in 0..<count {
      let ty = paramsPtr[i]!
      params.append(convertType(ty))
    }
    return params
  }

  /// Retrieves the underlying LLVM type object.
  public func asLLVM() -> LLVMTypeRef {
    return llvm
  }

  /// Return true if this is a struct type with an identity that has an
  /// unspecified body.
  ///
  /// Opaque struct types print as `opaque` in serialized .ll files.
  public var isOpaque: Bool {
    return LLVMIsOpaqueStruct(self.llvm) != 0
  }

  /// Returns true if this is a packed struct type.
  ///
  /// A packed struct type includes no padding between fields and is thus
  /// laid out in one contiguous region of memory with its elements laid out
  /// one after the other.  A non-packed struct type includes padding according
  /// to the data layout of the target.
  public var isPacked: Bool {
    return LLVMIsPackedStruct(self.llvm) != 0
  }

  /// Returns true if this is a literal struct type.
  ///
  /// A literal struct type is uniqued by structural equivalence - that is,
  /// regardless of how it is named, two literal structures are equal if
  /// their fields are equal.
  public var isLiteral: Bool {
    return LLVMIsLiteralStruct(self.llvm) != 0
  }
}

extension StructType: Equatable {
  public static func == (lhs: StructType, rhs: StructType) -> Bool {
    return lhs.asLLVM() == rhs.asLLVM()
  }
}

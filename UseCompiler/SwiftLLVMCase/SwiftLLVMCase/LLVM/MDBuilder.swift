//
//  MDBuilder.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// An `MDBuilder` object provides a convenient way to build common metadata
/// nodes.
public final class MDBuilder {
  /// The context used to intialize this metadata builder.
  public let context: Context

  /// Creates a metadata builder with the given context.
  ///
  /// - Parameters:
  ///   - context: The context in which to create metadata.
  public init(in context: Context = .global) {
    self.context = context
  }
}

// MARK: Floating Point Accuracy Metadata

extension MDBuilder {
  /// Builds metadata describing the accuracy of a floating-point computation
  /// using the given accuracy value.
  ///
  /// - Parameters:
  ///   - accuracy: The accuracy value.
  /// - Returns: A metadata node describing the accuracy of a floating-point
  ///   computation.
  public func buildFloatingPointMathTag(_ accuracy: Float) -> MDNode? {
    guard accuracy > 0.0 else {
      return nil
    }
    let op = MDNode(constant: FloatType(kind: .float, in: self.context).constant(Double(accuracy)))
    return MDNode(in: self.context, operands: [ op ])
  }
}

// MARK: Branch Prediction Metadata

extension MDBuilder {
  /// Builds branch weight metadata for a set of branch targets of a `branch`,
  /// `select,` `switch`, or `call` instruction.
  ///
  /// - Parameters:
  ///   - weights: The weights of the branches.
  /// - Returns: A metadata node containing the given branch-weight information.
  public func buildBranchWeights(_ weights: [Int]) -> MDNode {
    precondition(weights.count >= 1, "Branch weights must have at least one value")
    var ops = [IRMetadata]()
    ops.reserveCapacity(weights.count + 1)
    ops.append(MDString("branch_weights"))
    let int32Ty = IntType(width: 32, in: self.context)
    for weight in weights {
      ops.append(MDNode(constant: int32Ty.constant(weight)))
    }
    return MDNode(in: self.context, operands: ops)
  }

  /// Builds branch metadata that expresses that the flow of control is
  /// unpredictable in a given `branch` or `switch` instruction.
  ///
  /// - Returns: A metadata node representing unpredictable branch metadata.
  public func buildUnpredictable() -> MDNode {
    return MDNode(in: self.context, operands: [])
  }
}

// MARK: Section Prefix Metadata

extension MDBuilder {
  /// Builds section prefix metadata.
  ///
  /// LLVM allows an explicit section to be specified for functions. If the
  /// target supports it, it will emit functions to the section specified.
  /// Additionally, the function can be placed in a COMDAT.
  ///
  /// - Parameters:
  ///   - section: The section into which functions annotated with this
  ///     metadata should be emitted.
  /// - Returns: A metadata node representing the section prefix metadata.
  public func buildFunctionSectionPrefix(_ section: String) -> MDNode {
    return MDNode(in: self.context, operands: [
      MDString("function_section_prefix"),
      MDString(section),
    ])
  }
}

// MARK: Range Metadata

extension MDBuilder {
  /// Builds range metadata.
  ///
  /// Range metadata may be attached only to load, call and invoke of integer
  /// types. It expresses the possible ranges the loaded value or the value
  /// returned by the called function at this call site is in. If the loaded
  /// or returned value is not in the specified range, the behavior is
  /// undefined.
  ///
  /// - Parameters:
  ///   - lo: The lower bound on the range.
  ///   - hi: The upper bound on the range.
  /// - Returns: A metadata node representing the newly created range metadata.
  public func buildRange(_ lo: APInt, _ hi: APInt) -> MDNode? {
    precondition(lo.bitWidth == hi.bitWidth, "Bitwidth of range limits must match!")
    guard lo != hi else {
      return nil
    }

    return MDNode(in: self.context, operands: [
      MDNode(llvm: LLVMValueAsMetadata(lo.asLLVM())),
      MDNode(llvm: LLVMValueAsMetadata(hi.asLLVM())),
    ])
  }
}

// MARK: Callee Metadata

extension MDBuilder {
  /// Build callees metadata.
  ///
  /// Callees metadata may be attached to indirect call sites. If callees
  /// metadata is attached to a call site, and any callee is not among the
  /// set of functions provided by the metadata, the behavior is undefined.
  ///
  /// - Parameters:
  ///   - callees: An array of callee function values.
  /// - Returns: A metadata node representing the newly created callees metadata.
  public func buildCallees(_ callees: [Function]) -> MDNode {
    var ops = [IRMetadata]()
    ops.reserveCapacity(callees.count)
    for callee in callees {
      ops.append(MDNode(constant: callee))
    }
    return MDNode(in: self.context, operands: ops)
  }
}

// MARK: Callback Metadata

extension MDBuilder {
  /// Build Callback metadata.
  ///
  /// Callback metadata may be attached to a function declaration, or
  /// definition. The metadata describes how the arguments of a call to a
  /// function are in turn passed to the callback function specified by the
  /// metadata. Thus, the callback metadata provides a partial description of
  /// a call site inside the function with regards to the arguments of a call
  /// to the function. The only semantic restriction on the function itself is
  /// that it is not allowed to inspect or modify arguments referenced in the
  /// callback metadata as pass-through to the callback function.
  ///
  /// - Parameters:
  ///   - callbackIndex: The argument index of the callback.
  ///   - argumentIndices: An array of argument indices in the caller that
  ///     are passed to the callback function.
  ///   - passVariadicArguments: If true, denotes that all variadic arguments
  ///     of the function are passed to the callback.
  /// - Returns: A metadata node representing the newly created callees metadata.
  public func buildCallbackEncoding(
    _ callbackIndex: UInt, _ argumentIndices: [Int],
    passVariadicArguments: Bool = false
  ) -> MDNode {
    var ops = [IRMetadata]()
    let int64 = IntType(width: 64, in: self.context)
    ops.append(MDNode(constant: int64.constant(callbackIndex)))
    for argNo in argumentIndices {
      ops.append(MDNode(constant: int64.constant(argNo)))
    }
    ops.append(MDNode(constant: IntType(width: 1, in: self.context).constant(passVariadicArguments ? 1 : 0)))
    return MDNode(in: self.context, operands: ops)
  }
}

// MARK: Function Entry Count Metadata

extension MDBuilder {
  /// Build function entry count metadata.
  ///
  /// Function entry count metadata can be attached to function definitions to
  /// record the number of times the function is called. Used with
  /// block frequency information, it is also used to derive the basic block
  /// profile count.
  ///
  /// - Parameters:
  ///   - count: The number of times a function is called.
  ///   - imports: The GUID of global values that should be imported along with
  ///     this function when running PGO.
  ///   - synthetic: Whether the entry count is synthetic.  User-created
  ///     metadata should not be synthetic outside of PGO passes.
  /// - Returns: A metadata node representing the newly created entry count metadata.
  public func buildFunctionEntryCount(
    _ count: UInt, imports: Set<UInt64> = [], synthetic: Bool = false
  ) -> MDNode {
    let int64 = IntType(width: 64, in: self.context)
    var ops = [IRMetadata]()
    if synthetic {
      ops.append(MDString("synthetic_function_entry_count"))
    } else {
      ops.append(MDString("function_entry_count"))
    }
    ops.append(MDNode(constant: int64.constant(count)))
    for id in imports.sorted() {
      ops.append(MDNode(constant: int64.constant(id)))
    }
    return MDNode(in: self.context, operands: ops)
  }
}

// MARK: TBAA Metadata

/// Represents a single field in a (C or C++) struct.
public struct TBAAStructField {
  /// The offset of this struct field in bytes.
  public let offset: Size
  /// This size of this struct field in bytes.
  public let size: Size
  /// The type metadata node for this struct field.
  public let type: MDNode

  /// Create a new TBAA struct field.
  ///
  /// - Parameters:
  ///   - The offsset of this field relative to its parent in bytes.
  ///   - The size of this field in bytes.
  ///   - TBAA type metadata for the field.
  public init(offset: Size, size: Size, type: MDNode) {
    self.offset = offset
    self.size = size
    self.type = type
  }
}

extension MDBuilder {
  /// Build a metadata node for the root of a TBAA hierarchy with the given
  /// name.
  ///
  /// The root node of a TBAA hierarchy describes a boundary for a source
  /// language's type system.  For the purposes of optimization, a TBAA analysis
  /// pass must consider ancestors of two different root systems `mayalias`.
  ///
  /// - Parameters:
  ///   - name: The name of the TBAA root node.
  /// - Returns: A metadata node representing a TBAA hierarchy root.
  public func buildTBAARoot(_ name: String = "") -> MDNode {
    guard !name.isEmpty else {
      return self.buildAnonymousAARoot()
    }
    return MDNode(in: self.context, operands: [ MDString(name) ])
  }

  /// Build a metadata node suitable for an `alias.scope` metadata attachment.
  ///
  /// When evaluating an aliasing query, if for some domain, the set of scopes
  /// with that domain in one instruction’s alias.scope list is a subset of (or
  /// equal to) the set of scopes for that domain in another instruction’s
  /// noalias list, then the two memory accesses are assumed not to alias.
  ///
  /// Because scopes in one domain don’t affect scopes in other domains,
  /// separate domains can be used to compose multiple independent noalias
  /// sets. This is used for example during inlining. As the noalias function
  /// parameters are turned into noalias scope metadata, a new domain is used
  /// every time the function is inlined.
  ///
  /// - Parameters:
  ///   - name: The name of the alias scope domain.
  ///   - domain: The domain of the alias scope, if any.
  /// - Returns: A metadata node representing a TBAA alias scope.
  public func buildAliasScopeDomain(_ name: String = "", _ domain: MDNode? = nil) -> MDNode {
    if name.isEmpty {
      if let domain = domain {
        return self.buildAnonymousAARoot(name, domain)
      }
      return self.buildAnonymousAARoot(name)
    } else {
      if let domain = domain {
        return MDNode(in: self.context, operands: [ MDString(name), domain ])
      }
      return MDNode(in: self.context, operands: [ MDString(name) ])
    }
  }

  /// Builds a metadata node suitable for a `tbaa.struct` metadata attachment.
  ///
  /// `tbaa.struct` metadata can describe which memory subregions in a
  /// `memcpy` are padding and what the TBAA tags of the struct are.
  ///
  /// Note that the fields need not be contiguous. In the following example,
  /// there is a 4 byte gap between the two fields. This gap represents padding
  /// which does not carry useful data and need not be preserved.
  ///
  ///     !4 = !{ i64 0, i64 4, !1, i64 8, i64 4, !2 }
  ///
  /// - Parameters:
  ///   - fields: The fields of the struct.
  /// - Returns: A metadata node representing a TBAA struct descriptor.
  public func buildTBAAStructNode(_ fields: [TBAAStructField]) -> MDNode {
    var ops = [IRMetadata]()
    ops.reserveCapacity(fields.count * 3)
    let int64 = IntType(width: 64, in: self.context)
    for field in fields {
      ops.append(MDNode(constant: int64.constant(field.offset.rawValue)))
      ops.append(MDNode(constant: int64.constant(field.size.rawValue)))
      ops.append(field.type)
    }
    return MDNode(in: self.context, operands: ops)
  }

  /// Builds a TBAA Type Descriptor.
  ///
  /// Type descriptors describe the type system of the higher level language
  /// being compiled and come in two variants:
  ///
  /// Scalar Type Descriptors
  /// =======================
  ///
  /// Scalar type descriptors describe types that do not contain other types,
  /// such as fixed-width integral and floating-point types.  A scalar type
  /// has a single parent, which is required to be another scalar type or
  /// the TBAA root node.  For example, in C, `int32_t` would be described be
  /// a scalar type node with a parent pointer to `unsigned char` which, in
  /// turn, points to the root for C.
  ///
  /// ```
  /// +----------+   +------+   +-----------+
  /// |          |   |      |   |           |
  /// | uint32_t +---> char +---> TBAA Root |
  /// |          |   |      |   |           |
  /// +----------+   +------+   +-----------+
  /// ```
  ///
  /// Struct Type Descriptors
  /// =======================
  ///
  /// Struct type descriptors describe types that contain a sequence of other
  /// type descriptors, at known offsets, as fields. These field type
  /// descriptors can either be struct type descriptors themselves or scalar
  /// type descriptors.
  ///
  /// ```
  ///               +----------+
  ///               |          |
  ///       +-------> uint32_t +----+
  ///       |       |          |    |
  ///       |       +----------+    |
  /// +------------+            +---v--+   +-----------+
  /// |            |            |      |   |           |
  /// | SomeStruct |            | char +---> TBAA Root |
  /// |            |            |      |   |           |
  /// +------------+            +---^--+   +-----------+
  ///       |          +-------+    |
  ///       |          |       |    |
  ///       +----------> float +----+
  ///                  |       |
  ///                  +-------+
  /// ```
  ///
  /// - Parameters:
  ///   - parent: The parent type node of this type node or the TBAA root node
  ///     if it is a top-level entity.
  ///   - size: The size of the type in bytes.
  ///   - id: The metadata node whose identity uniquely identifies this node as
  ///     well.  These are often `MDString` values.
  ///   - fields: The fields of the type, if any.
  /// - Returns: A metadata node representing a TBAA type descriptor.
  public func buildTBAATypeNode(
    _ id: IRMetadata, parent: MDNode, size: Size, fields: [TBAAStructField] = []
  ) -> MDNode {
    var ops = [IRMetadata]()
    ops.reserveCapacity(3 + fields.count * 3)
    let int64 = IntType(width: 64, in: self.context)
    ops.append(parent)
    ops.append(MDNode(constant: int64.constant(size.rawValue)))
    ops.append(id)
    for field in fields {
      ops.append(field.type)
      ops.append(MDNode(constant: int64.constant(field.offset.rawValue)))
      ops.append(MDNode(constant: int64.constant(field.size.rawValue)))
    }
    return MDNode(in: self.context, operands: ops)
  }

  /// Builds a TBAA Access Tag.
  ///
  /// Access tags are metadata nodes attached to `load` and `store`
  /// instructions. Access tags use type descriptors to describe the
  /// location being accessed in terms of the type system of the higher
  /// level language. Access tags are tuples consisting of a base type,
  /// an access type and an offset. The base type is a scalar type
  /// descriptor or a struct type descriptor, the access type is a
  /// scalar type descriptor, and the offset is a constant integer.
  ///
  /// Tag Structure
  /// =============
  ///
  /// The access tag `(BaseTy, AccessTy, Offset)` can describe one of two
  /// things:
  ///
  /// - If `BaseTy` is a struct type, the tag describes a memory access
  ///   (`load` or `store`) of a value of type `AccessTy` contained in
  ///   the struct type `BaseTy` at offset `Offset`.
  /// - If `BaseTy` is a scalar type, `Offset` must be 0 and `BaseTy` and
  ///   `AccessTy` must be the same; and the access tag describes a scalar
  ///   access with scalar type `AccessTy`.
  ///
  /// - Parameters:
  ///   - baseType: The base type of the access.  This is the structure or
  ///     scalar type that corresponds to the type of the source value in a
  ///     `load` instruction, or the type of the destination value in a `store`
  ///     instruction.
  ///   - accessType: The type of the accessed value.  This is the type that
  ///     corresponds to the type of the destination value in a `load`
  ///     instruction, or the type of the source value in a `store` instruction.
  ///   - offset: The ofset of the memory access into the base type.  If the
  ///     base type is scalar, this value must be 0.
  ///   - size: The size of the access in bytes.
  ///   - immutable: If true, accesses to this memory are never writes.
  ///     This corresponds to the `const` memory qualifier in C and C++.
  /// - Returns: A metadata node representing a TBAA access tag.
  public func buildTBAAAccessTag(
    baseType: MDNode, accessType: MDNode,
    offset: Size, size: Size, immutable: Bool = false
  ) -> MDNode {
    let int64 = IntType(width: 64, in: self.context)
    let offNode = MDNode(constant: int64.constant(offset.rawValue))
    let sizeNode = MDNode(constant: int64.constant(size.rawValue))
    if immutable {
      return MDNode(in: self.context, operands: [
        baseType,
        accessType,
        offNode,
        sizeNode,
        MDNode(constant: int64.constant(1)),
      ])
    }
    return MDNode(in: self.context, operands: [
      baseType,
      accessType,
      offNode,
      sizeNode,
    ])
  }

  private func buildAnonymousAARoot(_ name: String = "", _ extra: MDNode? = nil) -> MDNode {
    // To ensure uniqueness the root node is self-referential.
    let dummy = TemporaryMDNode(in: self.context, operands: [])
    var ops = [IRMetadata]()
    if let extra = extra {
      ops.append(extra)
    }
    if !name.isEmpty {
      ops.append(MDString(name))
    }
    let root = MDNode(in: self.context, operands: ops)
    // At this point we have
    //   !0 = metadata !{}            <- dummy
    //   !1 = metadata !{metadata !0} <- root
    // Replace the dummy operand with the root node itself and delete the dummy.
    dummy.replaceAllUses(with: root)
    // We now have
    //   !1 = metadata !{metadata !1} <- self-referential root
    return root
  }
}

// MARK: Irreducible Loop Metadata

extension MDBuilder {
  /// Builds irreducible loop metadata.
  ///
  /// - Parameters:
  ///   - weight: The weight of a loop header.
  /// - Returns: A metadata node representing the newly created
  ///   irreducible loop metadata.
  public func buildIrreducibleLoopHeaderWeight(_ weight: UInt) -> MDNode {
    return MDNode(in: self.context, operands: [
      MDString("loop_header_weight"),
      MDNode(constant: IntType(width: 64, in: self.context).constant(weight))
    ])
  }
}

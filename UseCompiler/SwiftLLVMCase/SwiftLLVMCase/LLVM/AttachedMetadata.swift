//
//  AttachedMetadata.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

extension Context {
  /// Searches for and retrieves a metadata kind with the given name in this
  /// context.  If none is found, one with that name is created and its unique
  /// identifier is returned.
  public func metadataKind(named name: String, in context: Context = .global) -> UInt32 {
    return LLVMGetMDKindIDInContext(context.llvm, name, UInt32(name.count))
  }
}

extension IRGlobal {
  /// Retrieves all metadata entries attached to this global value.
  public var metadata: AttachedMetadata {
    var count = 0
    let ptr = LLVMGlobalCopyAllMetadata(self.asLLVM(), &count)
    return AttachedMetadata(llvm: ptr, bounds: count)
  }

  /// Sets a metadata attachment, erasing the existing metadata attachment if
  /// it already exists for the given kind.
  ///
  /// - Parameters:
  ///   - metadata: The metadata to attach to this global value.
  ///   - kind: The kind of metadata to attach.
  public func addMetadata(_ metadata: IRMetadata, kind: AttachedMetadata.PinnedKind) {
    LLVMGlobalSetMetadata(self.asLLVM(), kind.rawValue, metadata.asMetadata())
  }

  /// Sets a metadata attachment, erasing the existing metadata attachment if
  /// it already exists for the given kind.
  ///
  /// - Parameters:
  ///   - metadata: The metadata to attach to this global value.
  ///   - kind: The kind of metadata to attach.
  public func addMetadata(_ metadata: IRMetadata, kind: UInt32) {
    LLVMGlobalSetMetadata(self.asLLVM(), kind, metadata.asMetadata())
  }

  /// Removes all metadata attachments from this value.
  public func removeAllMetadata() {
    LLVMGlobalClearMetadata(self.asLLVM())
  }

  /// Erases a metadata attachment of the given kind if it exists.
  ///
  /// - Parameter kind: The kind of the metadata to remove.
  public func eraseAllMetadata(of kind: UInt32) {
    LLVMGlobalEraseMetadata(self.asLLVM(), kind)
  }
}

extension IRInstruction {
  /// Retrieves all metadata entries attached to this instruction.
  public var metadata: AttachedMetadata {
    var count = 0
    let ptr = LLVMGlobalCopyAllMetadata(self.asLLVM(), &count)
    return AttachedMetadata(llvm: ptr, bounds: count)
  }

  /// Sets a metadata attachment, erasing the existing metadata attachment if
  /// it already exists for the given kind.
  ///
  /// - Parameters:
  ///   - metadata: The metadata to attach to this global value.
  ///   - kind: The kind of metadata to attach.
  public func addMetadata(_ metadata: IRMetadata, kind: AttachedMetadata.PinnedKind) {
    LLVMSetMetadata(self.asLLVM(), kind.rawValue, LLVMMetadataAsValue(self.type.context.llvm, metadata.asMetadata()))
  }

  /// Sets a metadata attachment, erasing the existing metadata attachment if
  /// it already exists for the given kind.
  ///
  /// - Parameters:
  ///   - metadata: The metadata to attach to this global value.
  ///   - kind: The kind of metadata to attach.
  public func addMetadata(_ metadata: IRMetadata, kind: UInt32) {
    LLVMSetMetadata(self.asLLVM(), kind, LLVMMetadataAsValue(self.type.context.llvm, metadata.asMetadata()))
  }
}

/// Represents a sequence of metadata entries attached to a global value that
/// are uniqued by kind.
public class AttachedMetadata {
  /// Metadata kinds that are known to LLVM.
  public enum PinnedKind: UInt32 {
    /// Debug information metadata.
    ///
    /// `dbg` metadata is used to record primary debugging source-level
    /// debugging information for values and functions.
    case dbg = 0
    /// Type Based Alias Analysis metadata.
    ///
    /// In LLVM IR, memory does not have types, so LLVM’s own type system is not
    /// suitable for doing type based alias analysis (TBAA). Instead, metadata
    /// is added to the IR to describe a type system of a higher level language.
    /// This can be used to implement C/C++ strict type aliasing rules, but it
    /// can also be used to implement custom alias analysis behavior for other
    /// languages.
    ///
    /// To read more about how to do TBAA in LLVM, see the
    /// [Language Reference](https://llvm.org/docs/LangRef.html#tbaa-metadata).
    case tbaa = 1
    /// Profiling metadata.
    ///
    /// `prof` metadata is used to record profile data in the IR. The first
    /// operand of the metadata node indicates the profile metadata type. There
    /// are currently 3 types: `branch_weights`, `function_entry_count`,
    /// and `VP`.
    ///
    /// Branch weight metadata attached to a `branch`, `select`, `switch` or
    /// `call` instruction represents the likeliness of the associated branch
    /// being taken.
    ///
    /// Function entry count metadata can be attached to function definitions to
    /// record the number of times the function is called. Used with
    /// block frequency information, it is also used to derive the basic block
    /// profile count.
    ///
    /// VP (value profile) metadata can be attached to instructions that have
    /// value profile information. Currently this is indirect calls (where it
    /// records the hottest callees) and calls to memory intrinsics such as
    /// `memcpy`, `memmove`, and `memset` (where it records the hottest byte
    /// lengths).
    ///
    /// Each VP metadata node contains the “VP” string, then an unsigned 32-bit
    /// value for the value profiling kind, an unsigned 64-bit value for the
    /// total number of times the instruction is executed, followed by an
    /// unsigned 64-bit value and execution count pairs. The value profiling
    /// kind is 0 for indirect call targets and 1 for memory operations. For
    /// indirect call targets, each profile value is a hash of the callee
    /// function name, and for memory operations each value is the byte length.
    ///
    /// Note that the value counts do not need to add up to the total count
    /// listed in the third operand (in practice only the top hottest values
    /// are tracked and reported).
    ///
    /// For example:
    ///
    ///     call void %f(), !prof !1
    ///     !1 = !{!"VP", i32 0, i64 1600, i64 7651369219802541373, i64 1030, i64 -4377547752858689819, i64 410}
    ///
    /// Note that the VP type is 0 (the second operand), which indicates this is
    /// an indirect call value profile data. The third operand indicates that
    /// the indirect call executed 1600 times. The 4th and 6th operands give the
    /// hashes of the 2 hottest target functions’ names (this is the same hash
    /// used to represent function names in the profile database), and the 5th
    /// and 7th operands give the execution count that each of the respective
    /// prior target functions was called.
    case prof = 2
    /// Floating-point math metadata.
    ///
    /// `fpmath` metadata may be attached to any instruction of floating-point
    /// type. It can be used to express the maximum acceptable error in the
    /// result of that instruction, in ULPs, thus potentially allowing the
    /// compiler to use a more efficient but less accurate method of computing
    /// it. ULP is defined as follows:
    ///
    /// If `x` is a real number that lies between two finite consecutive
    /// floating-point numbers `a` and `b`, without being equal to one of them,
    /// then `ulp(x) = |b - a|`, otherwise `ulp(x)` is the distance between the
    /// two non-equal finite floating-point numbers nearest `x`.
    /// Moreover, `ulp(NaN)` is `NaN`.
    ///
    /// The metadata node shall consist of a single positive float type number
    /// representing the maximum relative error, for example:
    ///
    ///     !0 = !{ float 2.5 } ; maximum acceptable inaccuracy is 2.5 ULPs
    case fpmath = 3
    /// Range metadata.
    ///
    /// Range metadata may be attached only to load, call and invoke of integer
    /// types. It expresses the possible ranges the loaded value or the value
    /// returned by the called function at this call site is in. If the loaded
    /// or returned value is not in the specified range, the behavior is
    /// undefined. The ranges are represented with a flattened list of integers.
    /// The loaded value or the value returned is known to be in the union of
    /// the ranges defined by each consecutive pair. Each pair has the
    /// following properties:
    ///
    /// - The type must match the type loaded by the instruction.
    /// - The pair `a,b` represents the range `[a,b)`.
    /// - Both `a` and `b` are constants.
    /// - The range is allowed to wrap.
    /// - The range should not represent the full or empty set.
    ///   That is, `a != b`.
    /// - In addition, the pairs must be in signed order of the lower bound and
    ///   they must be non-contiguous.
    ///
    /// For example:
    ///
    ///     %a = load i8, i8* %x, align 1, !range !0 ; Can only be 0 or 1
    ///     %b = load i8, i8* %y, align 1, !range !1 ; Can only be 255 (-1), 0 or 1
    ///     %c = call i8 @foo(),       !range !2 ; Can only be 0, 1, 3, 4 or 5
    ///     %d = invoke i8 @bar() to label %cont
    ///     unwind label %lpad, !range !3 ; Can only be -2, -1, 3, 4 or 5
    ///     ...
    ///     !0 = !{ i8 0, i8 2 }
    ///     !1 = !{ i8 255, i8 2 }
    ///     !2 = !{ i8 0, i8 2, i8 3, i8 6 }
    ///     !3 = !{ i8 -2, i8 0, i8 3, i8 6 }
    case range = 4
    /// Type Based Alias Analysis struct metadata.
    ///
    /// The `llvm.memcpy.*` family of instrinsics is often used to implement
    /// aggregate assignment operations in C and similar languages, however it
    /// is defined to copy a contiguous region of memory, which is more than
    /// strictly necessary for aggregate types which contain holes due to
    /// padding. Also, it doesn’t contain any TBAA information about the fields
    /// of the aggregate.
    ///
    /// `tbaa.struct` metadata can describe which memory subregions in a
    /// `memcpy` are padding and what the TBAA tags of the struct are.
    ///
    /// The current metadata format is very simple. `tbaa.struct` metadata nodes
    /// are a list of operands which are in conceptual groups of three. For each
    /// group of three, the first operand gives the byte offset of a field in
    /// bytes, the second gives its size in bytes, and the third gives its
    /// tbaa tag. e.g.:
    ///
    ///     !4 = !{ i64 0, i64 4, !1, i64 8, i64 4, !2 }
    ///
    /// This describes a struct with two fields: The first is at offset 0 bytes
    /// with size 4 bytes, and has tbaa tag `!1`. The second is at offset 8
    /// bytes and has size 4 bytes and has tbaa tag !2.
    ///
    /// Note that the fields need not be contiguous. In this example, there is a
    /// 4 byte gap between the two fields. This gap represents padding which
    /// does not carry useful data and need not be preserved.
    case tbaaStruct = 5
    /// Load addreess invariance metadata.
    ///
    /// If a load instruction tagged with the `invariant.load` metadata is
    /// executed, the optimizer may assume the memory location referenced by the
    /// load contains the same value at all points in the program where the
    /// memory location is known to be dereferenceable; otherwise, the
    /// behavior is undefined.
    case invariantLoad = 6
    /// Alias scope metadata.
    ///
    /// `alias.scope` metadata provide the ability to specify generic `noalias`
    /// memory-access sets. This means that some collection of memory access
    /// instructions (loads, stores, memory-accessing calls, etc.) that carry
    /// `noalias` metadata can specifically be specified not to alias with some
    /// other collection of memory access instructions that carry `alias.scope`
    /// metadata. Each type of metadata specifies a list of scopes where each
    /// scope has an id and a domain.
    ///
    /// When evaluating an aliasing query, if for some domain, the set of scopes
    /// with that domain in one instruction’s `alias.scope` list is a subset of
    /// (or equal to) the set of scopes for that domain in another instruction’s
    /// noalias list, then the two memory accesses are assumed not to alias.
    ///
    /// Because scopes in one domain don’t affect scopes in other domains,
    /// separate domains can be used to compose multiple independent noalias
    /// sets. This is used for example during inlining. As the noalias function
    /// parameters are turned into noalias scope metadata, a new domain is used
    /// every time the function is inlined.
    ///
    /// The metadata identifying each domain is itself a list containing one or
    /// two entries. The first entry is the name of the domain. Note that if the
    /// name is a string then it can be combined across functions and
    /// translation units. A self-reference can be used to create globally
    /// unique domain names. A descriptive string may optionally be provided as
    /// a second list entry.
    ///
    /// The metadata identifying each scope is also itself a list containing two
    /// or three entries. The first entry is the name of the scope. Note that if
    /// the name is a string then it can be combined across functions and
    /// translation units. A self-reference can be used to create globally
    /// unique scope names. A metadata reference to the scope’s domain is the
    /// second entry. A descriptive string may optionally be provided as a third
    /// list entry.
    ///
    /// For example:
    ///
    ///     ; Two scope domains:
    ///     !0 = !{!0}
    ///     !1 = !{!1}
    ///
    ///     ; Some scopes in these domains:
    ///     !2 = !{!2, !0}
    ///     !3 = !{!3, !0}
    ///     !4 = !{!4, !1}
    ///
    ///     ; Some scope lists:
    ///     !5 = !{!4} ; A list containing only scope !4
    ///     !6 = !{!4, !3, !2}
    ///     !7 = !{!3}
    ///
    ///     ; These two instructions don't alias:
    ///     %0 = load float, float* %c, align 4, !alias.scope !5
    ///     store float %0, float* %arrayidx.i, align 4, !noalias !5
    ///
    ///     ; These two instructions also don't alias (for domain !1, the set of scopes
    ///     ; in the !alias.scope equals that in the !noalias list):
    ///     %2 = load float, float* %c, align 4, !alias.scope !5
    ///     store float %2, float* %arrayidx.i2, align 4, !noalias !6
    ///
    ///     ; These two instructions may alias (for domain !0, the set of scopes in
    ///     ; the !noalias list is not a superset of, or equal to, the scopes in the
    ///     ; !alias.scope list):
    ///     %2 = load float, float* %c, align 4, !alias.scope !6
    ///     store float %0, float* %arrayidx.i, align 4, !noalias !7
    case aliasScope = 7
    /// No-alias metadata.
    ///
    /// `noalias` metadata provide the ability to specify generic `noalias`
    /// memory-access sets. This means that some collection of memory access
    /// instructions (loads, stores, memory-accessing calls, etc.) that carry
    /// `noalias` metadata can specifically be specified not to alias with some
    /// other collection of memory access instructions that carry `alias.scope`
    /// metadata. Each type of metadata specifies a list of scopes where each
    /// scope has an id and a domain.
    case noalias = 8
    /// Temporal metadata.
    ///
    /// The existence of the !nontemporal metadata on the instruction tells the
    /// optimizer and code generator that this load is not expected to be reused
    /// in the cache. The code generator may select special instructions to save
    /// cache bandwidth, such as the `MOVNT` instruction on x86.
    case nontemporal = 9
    /// Loop memory access metadata.
    ///
    /// If certain memory accesses within a loop are independent of each other
    /// (that is, they have no loop-carried dependencies), and if these are the
    /// only accesses in the loop, then tagging load/store instructions with
    /// `llvm.mem.parallel_loop_access` signals to the optimizer that those
    /// accesses can be vectorized.
    case memParallelLoopAccess = 10
    /// Non-null metadata.
    ///
    /// This indicates that the parameter or return pointer is not null. This
    /// attribute may only be applied to pointer typed parameters. This is not
    /// checked or enforced by LLVM; if the parameter or return pointer is null,
    /// the behavior is undefined.
    ///
    /// Note that the concept of a "null" pointer is address space dependent.  it is
    /// not necessarily the 0 bit-pattern.
    case nonnull = 11
    /// Dereferenceable metadata.
    ///
    /// This indicates that the parameter or return pointer is dereferenceable.
    /// This attribute may only be applied to pointer typed parameters. A
    /// pointer that is dereferenceable can be loaded from speculatively without
    /// a risk of trapping. The number of bytes known to be dereferenceable must
    /// be provided in parentheses. It is legal for the number of bytes to be
    /// less than the size of the pointee type. The `nonnull` attribute does not
    /// imply dereferenceability (consider a pointer to one element past the end
    /// of an array), however `dereferenceable` does imply `nonnull` in
    /// the default address space.
    case dereferenceable = 12
    /// Dereferenceable or null metadata.
    ///
    /// This indicates that the parameter or return value isn’t both non-null
    /// and non-dereferenceable (up to a given number of bytes) at the same
    /// time. All non-null pointers tagged with `dereferenceable_or_null` are
    /// `dereferenceable`. For address space 0, `dereferenceable_or_null`
    /// implies that a pointer is exactly one of `dereferenceable` or `null`,
    /// and in other address spaces `dereferenceable_or_null` implies that a
    /// pointer is at least one of `dereferenceable` or `null` (i.e. it may be
    /// both `null` and `dereferenceable`). This attribute may only be applied
    /// to pointer typed parameters.
    case dereferenceableOrNull = 13
    /// Implicit checks metadata.
    ///
    /// Making null checks implicit is an aggressive optimization, and it can be
    /// a net performance pessimization if too many memory operations end up
    /// faulting because of it. A language runtime typically needs to ensure
    /// that only a negligible number of implicit null checks actually fault
    /// once the application has reached a steady state. A standard way of doing
    /// this is by healing failed implicit null checks into explicit null checks
    /// via code patching or recompilation. It follows that there are two
    /// requirements an explicit null check needs to satisfy for it to be
    /// profitable to convert it to an implicit null check:
    ///
    /// - The case where the pointer is actually null (i.e. the “failing” case)
    ///   is extremely rare.
    /// - The failing path heals the implicit null check into an explicit null
    ///   check so that the application does not repeatedly page fault.
    ///
    /// The frontend is expected to mark branches that satisfy both conditions
    /// using a `make.implicit` metadata node (the actual content of the
    /// metadata node is ignored). Only branches that are marked with
    /// `make.implicit` metadata are considered as candidates for conversion
    /// into implicit null checks.
    case makeImplicit = 14
    /// Unpredictable metadata.
    ///
    /// Unpredictable metadata may be attached to any `branch` or `switch`
    /// instruction. It can be used to express the unpredictability of control
    /// flow. Similar to the `llvm.expect` intrinsic, it may be used to alter
    /// optimizations related to compare and branch instructions. The metadata
    /// is treated as a boolean value; if it exists, it signals that the branch
    /// or switch that it is attached to is completely unpredictable.
    case unpredictable = 15
    /// Invariant group metadata.
    ///
    /// The experimental `invariant.group` metadata may be attached to
    /// load/store instructions referencing a single metadata with no entries.
    /// The existence of `invariant.group` metadata on the instruction tells the
    /// optimizer that every load and store to the same pointer operand can be
    /// assumed to load or store the same value.
    ///
    /// Pointers returned by `bitcast` or `getelementptr` with only zero indices
    /// are considered the same.
    ///
    /// Examples:
    ///
    ///     @unknownPtr = external global i8
    ///     ...
    ///     %ptr = alloca i8
    ///     store i8 42, i8* %ptr, !invariant.group !0
    ///     call void @foo(i8* %ptr)
    ///
    ///     %a = load i8, i8* %ptr, !invariant.group !0 ; Can assume that value under %ptr didn't change
    ///     call void @foo(i8* %ptr)
    ///
    ///     %newPtr = call i8* @getPointer(i8* %ptr)
    ///     %c = load i8, i8* %newPtr, !invariant.group !0 ; Can't assume anything, because we only have information about %ptr
    ///
    ///     %unknownValue = load i8, i8* @unknownPtr
    ///     store i8 %unknownValue, i8* %ptr, !invariant.group !0 ; Can assume that %unknownValue == 42
    ///
    ///     call void @foo(i8* %ptr)
    ///     %newPtr2 = call i8* @llvm.launder.invariant.group(i8* %ptr)
    ///     %d = load i8, i8* %newPtr2, !invariant.group !0  ; Can't step through launder.invariant.group to get value of %ptr
    ///
    ///     ...
    ///     declare void @foo(i8*)
    ///     declare i8* @getPointer(i8*)
    ///     declare i8* @llvm.launder.invariant.group(i8*)
    ///
    ///     !0 = !{}
    ///
    /// The `invariant.group` metadata must be dropped when replacing one pointer
    /// by another based on aliasing information. This is because
    /// `invariant.group` is tied to the SSA value of the pointer operand.
    ///
    ///     %v = load i8, i8* %x, !invariant.group !0
    ///     ; if %x mustalias %y then we can replace the above instruction with
    ///     %v = load i8, i8* %y
    ///
    /// Note that this is an experimental feature, which means that its
    /// semantics might change in the future.
    case invariantGroup = 16
    /// Alignment metadata.
    ///
    /// This indicates that the pointer value may be assumed by the optimizer to
    /// have the specified alignment. If the pointer value does not have the
    /// specified alignment, behavior is undefined.
    case align = 17
    /// Loop identifier metadata.
    ///
    /// It is sometimes useful to attach information to loop constructs.
    /// Currently, loop metadata is implemented as metadata attached to the
    /// branch instruction in the loop latch block. This type of metadata refer
    /// to a metadata node that is guaranteed to be separate for each loop. The
    /// loop identifier metadata is specified with the name `llvm.loop`.
    ///
    /// The loop identifier metadata is implemented using a metadata that
    /// refers to itself to avoid merging it with any other identifier
    /// metadata, e.g., during module linkage or function inlining. That is,
    /// each loop should refer to their own identification metadata even if
    /// they reside in separate functions. The following example contains loop
    /// identifier metadata for two separate loop constructs:
    ///
    ///     !0 = !{!0}
    ///     !1 = !{!1}
    ///
    /// The loop identifier metadata can be used to specify additional per-loop
    /// metadata. Any operands after the first operand can be treated as
    /// user-defined metadata. For example the `llvm.loop.unroll.count`
    /// suggests an unroll factor to the loop unroller:
    ///
    ///     br i1 %exitcond, label %._crit_edge, label %.lr.ph, !llvm.loop !0
    ///     ...
    ///     !0 = !{!0, !1}
    ///     !1 = !{!"llvm.loop.unroll.count", i32 4}
    case loop = 18
    /// Type metadata.
    ///
    /// Type metadata is a mechanism that allows IR modules to co-operatively
    /// build pointer sets corresponding to addresses within a given set of
    /// globals. LLVM’s control flow integrity implementation uses this metadata
    /// to efficiently check (at each call site) that a given address
    /// corresponds to either a valid vtable or function pointer for a given
    /// class or function type, and its whole-program devirtualization pass uses
    /// the metadata to identify potential callees for a given virtual call.
    ///
    /// For more information, see [Type Metadata](https://www.llvm.org/docs/TypeMetadata.html).
    case type = 19
    /// Section prefix metadata.
    ///
    /// LLVM allows an explicit section to be specified for functions. If the
    /// target supports it, it will emit functions to the section specified.
    /// Additionally, the function can be placed in a COMDAT.
    case sectionPrefix = 20
    /// Absolute symbol metadata.
    ///
    /// `absolute_symbol` metadata may be attached to a global variable
    /// declaration. It marks the declaration as a reference to an absolute
    /// symbol, which causes the backend to use absolute relocations for the
    /// symbol even in position independent code, and expresses the possible
    /// ranges that the global variable’s address (not its value) is in, in the
    /// same format as range metadata, with the extension that the pair
    /// `all-ones,all-ones` may be used to represent the full set.
    ///
    /// For example (assuming 64-bit pointers):
    ///
    ///     @a = external global i8, !absolute_symbol !0 ; Absolute symbol in range [0,256)
    ///     @b = external global i8, !absolute_symbol !1 ; Absolute symbol in range [0,2^64)
    ///     ...
    ///     !0 = !{ i64 0, i64 256 }
    ///     !1 = !{ i64 -1, i64 -1 }
    case absoluteSymbol = 21
    /// Associated metadata.
    ///
    /// `associated` metadata may be attached to a global object declaration
    /// with a single argument that references another global object.
    ///
    /// This metadata prevents discarding of the global object in linker GC
    /// unless the referenced object is also discarded. The linker support for
    /// this feature is spotty. For best compatibility, globals carrying this
    /// metadata may also:
    ///
    /// - Be in a comdat with the referenced global.
    /// - Be in `@llvm.compiler.used`.
    /// - Have an explicit section with a name which is a valid C identifier.
    ///
    /// It does not have any effect on non-ELF targets.
    ///
    /// For example:
    ///
    ///     $a = comdat any
    ///     @a = global i32 1, comdat $a
    ///     @b = internal global i32 2, comdat $a, section "abc", !associated !0
    ///     !0 = !{i32* @a}
    case associated = 22
    /// Callees metadata.
    ///
    /// Callees metadata may be attached to indirect call sites. If callees
    /// metadata is attached to a call site, and any callee is not among the
    /// set of functions provided by the metadata, the behavior is undefined.
    ///
    /// The intent of this metadata is to facilitate optimizations such as
    /// indirect-call promotion. For example, in the code below, the call
    /// instruction may only target the add or sub functions:
    ///
    ///     %result = call i64 %binop(i64 %x, i64 %y), !callees !0
    ///     ...
    ///     !0 = !{i64 (i64, i64)* @add, i64 (i64, i64)* @sub}
    case callees = 23
    /// Irreducible loop metadata.
    ///
    /// `irr_loop` metadata may be attached to the terminator instruction of a
    /// basic block that’s an irreducible loop header (note that an irreducible
    /// loop has more than once header basic blocks.) If `irr_loop` metadata is
    /// attached to the terminator instruction of a basic block that is not
    /// really an irreducible loop header, the behavior is undefined.
    ///
    /// The intent of this metadata is to improve the accuracy of the block
    /// frequency propagation. For example, in the code below, the block
    /// `header0` may have a loop header weight (relative to the other headers
    /// of the irreducible loop) of 100:
    ///
    ///     header0:
    ///     ...
    ///     br i1 %cmp, label %t1, label %t2, !irr_loop !0
    ///     ...
    ///     !0 = !{"loop_header_weight", i64 100}
    ///
    /// Irreducible loop header weights are typically based on profile data.
    case irrLoop = 24
    /// Memory access group metadata.
    ///
    /// `llvm.access.group` metadata can be attached to any instruction that
    /// potentially accesses memory. It can point to a single distinct metadata
    /// node, which we call access group. This node represents all memory access
    /// instructions referring to it via `llvm.access.group`.
    ///
    /// When an instruction belongs to multiple access groups, it can also point
    /// to a list of accesses groups, illustrated by the following example:
    ///
    ///     %val = load i32, i32* %arrayidx, !llvm.access.group !0
    ///     ...
    ///     !0 = !{!1, !2}
    ///     !1 = distinct !{}
    ///     !2 = distinct !{}
    ///
    /// It is illegal for the list node to be empty since it might be confused
    /// with an access group.
    ///
    /// The access group metadata node must be `distinct` to avoid collapsing
    /// multiple access groups by content. An access group metadata node must
    /// always be empty which can be used to distinguish an access group
    /// metadata node from a list of access groups. Being empty avoids the
    /// situation that the content must be updated which, because metadata is
    /// immutable by design, would required finding and updating all references
    /// to the access group node.
    ///
    /// The access group can be used to refer to a memory access instruction
    /// without pointing to it directly (which is not possible in global
    /// metadata). Currently, the only metadata making use of it is
    /// `llvm.loop.parallel_accesses`.
    case accessGroup = 25
    /// Callback metadata.
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
    /// The function is not required to actually invoke the callback function
    /// at runtime. However, the assumptions about not inspecting or modifying
    /// arguments that would be passed to the specified callback function
    /// still hold, even if the callback function is not dynamically invoked.
    /// The function is allowed to invoke the callback function more than once
    /// per invocation. The function is also allowed to invoke (directly or
    /// indirectly) the function passed as a callback through another use.
    /// Finally, the function is also allowed to relay the callback callee
    /// invocation to a different thread.
    ///
    /// The metadata is structured as follows: At the outer level, callback
    /// metadata is a list of callback encodings. Each encoding starts with a
    /// constant `i64` which describes the argument position of the callback
    /// function in the call to the function. The following elements, except
    /// the last, describe what arguments are passed to the callback function.
    /// Each element is again an `i64` constant identifying the argument of the
    /// broker that is passed through, or `i64 -1` to indicate an unknown or
    /// inspected argument. The order in which they are listed has to be the
    /// same in which they are passed to the callback callee. The last element
    /// of the encoding is a boolean which specifies how variadic arguments of
    /// the broker are handled. If it is true, all variadic arguments of the
    /// broker are passed through to the callback function after the arguments
    /// encoded explicitly before.
    ///
    /// In the code below, the `pthread_create` function is marked as such a
    /// function through the `!callback !1` metadata. In the example, there is
    /// only one callback encoding, namely `!2`, associated with it. This
    /// encoding identifies the callback function as the second argument
    /// `(i64 2)` and the sole argument of the callback function
    /// as the third `(i64 3)`.
    ///
    ///     declare !callback !1 dso_local i32 @pthread_create(i64*, %union.pthread_attr_t*, i8* (i8*)*, i8*)
    ///     ...
    ///     !2 = !{i64 2, i64 3, i1 false}
    ///     !1 = !{!2}
    /// Another example is shown below. The callback callee is the second
    /// argument of the `__kmpc_fork_call` function `(i64 2)`. The callee is
    /// given two unknown values (each identified by a `i64 -1`) and afterwards
    /// all variadic arguments that are passed to the `__kmpc_fork_call` call
    /// (due to the final i1 true).
    ///
    ///     declare !callback !0 dso_local void @__kmpc_fork_call(%struct.ident_t*, i32, void (i32*, i32*, ...)*, ...)
    ///     ...
    ///     !1 = !{i64 2, i64 -1, i64 -1, i1 true}
    ///     !0 = !{!1}
    case callback = 26
  }

  /// Represents an entry in the module flags structure.
  public struct Entry {
    fileprivate let base: AttachedMetadata
    fileprivate let index: UInt32

    /// The metadata kind associated with this global metadata.
    public var kind: UInt32 {
      return LLVMValueMetadataEntriesGetKind(self.base.llvm, self.index)
    }

    /// The metadata value associated with this entry.
    public var metadata: IRMetadata {
      return AnyMetadata(llvm: LLVMValueMetadataEntriesGetMetadata(self.base.llvm, self.index))
    }
  }

  private let llvm: OpaquePointer?
  private let bounds: Int
  fileprivate init(llvm: OpaquePointer?, bounds: Int) {
    self.llvm = llvm
    self.bounds = bounds
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    guard let ptr = llvm else { return }
    LLVMDisposeValueMetadataEntries(ptr)
  }

  /// Retrieves a flag at the given index.
  ///
  /// - Parameter index: The index to retrieve.
  ///
  /// - Returns: An entry describing the flag at the given index.
  public subscript(_ index: Int) -> Entry {
    precondition(index >= 0 && index < self.bounds, "Index out of bounds")
    return Entry(base: self, index: UInt32(index))
  }

  /// Returns the number of metadata entries.
  public var count: Int {
    return self.bounds
  }
}

//
//  DWARFExpression.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// DWARF expressions describe how to compute a value or specify a location.
/// They are expressed in terms of DWARF operations that operate on a stack of
/// values.
///
/// A DWARF expression is encoded as a stream of operations, each consisting of
/// an opcode followed by zero or more literal operands.
public enum DWARFExpression {
  // MARK: Literals

  /// Encodes a single machine address value whose size is the size of an
  /// address on the target machine.
  case addr(UInt64)

  /// Encodes the unsigned literal value 0.
  case lit0
  /// Encodes the unsigned literal value 1.
  case lit1
  /// Encodes the unsigned literal value 2.
  case lit2
  /// Encodes the unsigned literal value 3.
  case lit3
  /// Encodes the unsigned literal value 4.
  case lit4
  /// Encodes the unsigned literal value 5.
  case lit5
  /// Encodes the unsigned literal value 6.
  case lit6
  /// Encodes the unsigned literal value 7.
  case lit7
  /// Encodes the unsigned literal value 8.
  case lit8
  /// Encodes the unsigned literal value 9.
  case lit9
  /// Encodes the unsigned literal value 10.
  case lit10
  /// Encodes the unsigned literal value 11.
  case lit11
  /// Encodes the unsigned literal value 12.
  case lit12
  /// Encodes the unsigned literal value 13.
  case lit13
  /// Encodes the unsigned literal value 14.
  case lit14
  /// Encodes the unsigned literal value 15.
  case lit15
  /// Encodes the unsigned literal value 16.
  case lit16
  /// Encodes the unsigned literal value 17.
  case lit17
  /// Encodes the unsigned literal value 18.
  case lit18
  /// Encodes the unsigned literal value 19.
  case lit19
  /// Encodes the unsigned literal value 20.
  case lit20
  /// Encodes the unsigned literal value 21.
  case lit21
  /// Encodes the unsigned literal value 22.
  case lit22
  /// Encodes the unsigned literal value 23.
  case lit23
  /// Encodes the unsigned literal value 24.
  case lit24
  /// Encodes the unsigned literal value 25.
  case lit25
  /// Encodes the unsigned literal value 26.
  case lit26
  /// Encodes the unsigned literal value 27.
  case lit27
  /// Encodes the unsigned literal value 28.
  case lit28
  /// Encodes the unsigned literal value 29.
  case lit29
  /// Encodes the unsigned literal value 30.
  case lit30
  /// Encodes the unsigned literal value 31.
  case lit31

  /// Encodes a 1-byte unsigned integer constant.
  case const1u(UInt8)
  /// Encodes a 1-byte signed integer constant.
  case const1s(Int8)
  /// Encodes a 2-byte unsigned integer constant.
  case const2u(UInt16)
  /// Encodes a 2-byte signed integer constant.
  case const2s(Int16)
  /// Encodes a 4-byte unsigned integer constant.
  case const4u(UInt32)
  /// Encodes a 4-byte signed integer constant.
  case const4s(Int32)
  /// Encodes a 8-byte unsigned integer constant.
  case const8u(UInt64)
  /// Encodes a 8-byte signed integer constant.
  case const8s(Int64)
  /// Encodes a little-endian base-128 unsigned integer constant.
  case constu(UInt64)
  /// Encodes a little-endian base-128 signed integer constant.
  case consts(Int64)
  /// Encodes an unsigned little-endian base-128 value, which is a zero-based
  /// index into the `.debug_addr` section where a machine address is stored.
  /// This index is relative to the value of the `DW_AT_addr_base` attribute
  /// of the associated compilation unit.
  case addrx(UInt64)
  /// Encodes an unsigned little-endian base-128 value, which is a zero-based
  /// index into the `.debug_addr` section where a constant, the size of a
  /// machine address, is stored.  This index is relative to the value of the
  /// `DW_AT_addr_base` attribute of the associated compilation unit.
  ///
  /// This operation is provided for constants that require link-time relocation
  /// but should not be interpreted by the consumer as a relocatable address (
  /// for example, offsets to thread-local storage).
  case constx(UInt64)

  // MARK: Register Values

  /// Provides a signeed little-endian base-128 offset from the address
  /// specified by the location description in the `DW_AT_frame_base` attribute
  /// of the current function.
  case fbreg(Int64)

  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 0.
  case breg0(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 1.
  case breg1(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 2.
  case breg2(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 3.
  case breg3(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 4.
  case breg4(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 5.
  case breg5(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 6.
  case breg6(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 7.
  case breg7(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 8.
  case breg8(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 9.
  case breg9(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 10.
  case breg10(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 11.
  case breg11(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 12.
  case breg12(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 13.
  case breg13(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 14.
  case breg14(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 15.
  case breg15(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 16.
  case breg16(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 17.
  case breg17(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 18.
  case breg18(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 19.
  case breg19(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 20.
  case breg20(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 21.
  case breg21(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 22.
  case breg22(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 23.
  case breg23(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 24.
  case breg24(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 25.
  case breg25(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 26.
  case breg26(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 27.
  case breg27(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 28.
  case breg28(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 29.
  case breg29(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 30.
  case breg30(Int64)
  /// The single operand of the breg operation provides a signed little-endian
  /// base-128 offset from the contents of register 31.
  case breg31(Int64)

  /// Provides the sum of two values specified by its two operands.  The first
  /// operand being a register number which is in unsigned little-endian
  /// base-128 form.  The second being an offset in signed little-endian
  /// base-128 form.
  case bregx(UInt64, Int64)

  /// Provides an operation with three operands: The first is an unsigned
  /// little-endian base-128 integer that represents the offset of a debugging
  /// information entry in the current compilation unit, which must be
  /// a base type entry that provides the type of the constant provided.
  /// The second operand is a 1-byte unsigned integer that specifies the
  /// size of the constant value, which is the same size as the base type
  /// referenced by the first operand.  The third operand is a sequence of bytes
  /// of the given size that is interpreted as a value of the referenced type.
  case constType(DIAttributeTypeEncoding, UInt8, [UInt8])

  /// Provides the contents of a given register interpreted as a value of a
  /// given type.  The first operand is an unsigned little-endian base-128
  /// number which identifies a register whose contents are pushed onto the
  /// stack.  The second operand is an unsigned little-endian base-128 number
  /// that represents the offset of a debugging information entry in the current
  /// compilation unit which must have base type.
  case regvalType(UInt64, DIAttributeTypeEncoding)

  // MARK: Stack Operations

  /// Duplicates the value (including its type identifier) at the top of the
  /// stack.
  case dup
  /// Pops the value (including its type identifier) at the top of the stack.
  case drop
  /// Provides a 1-byte index that is used to index into the stack.  A copy of
  /// stack entry at that index is pushed onto the stack.
  case pick(UInt8)
  /// Duplicates the entry currently second in the stack and pushes it onto the
  /// stack.
  ///
  /// This operation is equivalent to `.pick(1)`.
  case over
  /// Swaps the top two stack entries.  The entry at the top of the stack
  /// (including its type identifier) becomes the second stack entry, and the
  /// second entry (including its type identifier) becomes the top of the stack.
  case swap
  /// Rotates the first three stack entries.  The entry at the top of the stack
  /// (including its type identifier) becomes the third stack entry, the second
  /// stack entry (including its type identifier) becomes the top of the stack,
  /// and the third entry (including its type identifier) becomes the second
  /// entry.
  case rot
  /// Pops the top stack entry and treats it as an address.
  ///
  /// The popped value must have an integral type.  The value retrieved from
  /// that address is pushed, and has the generic type.  The size of the data
  /// retrieved from the dereferenced address is the size of an address on the
  /// target machine.
  case deref
  /// Pops the top stack entry and treats it as an address.
  ///
  /// The popped value must have an integral type.  The value retrieved from
  /// that address is pushed, and has the generic type.  The size of the data
  /// retrieved from the dereferenced address is specified by the
  /// operand, whose value is a 1-byte unsigned integral constant.  The data
  /// retrieved is zero-extended to the size of an address on the target machine
  /// before being pushed onto the expression stack.
  case derefSize(UInt8)
  /// Pops the top stack entry and treats it as an address.
  ///
  /// The popped value must have an integral type. The size of the data
  /// retrieved from the dereferenced address is specified by the first
  /// operand, whose value is a 1-byte unsigned integral constant.  The data
  /// retrieved is zero-extended to the size of an address on the target machine
  /// before being pushed onto the expression stack.  The second operand is an
  /// unsigned little-endian base-128 integer that represents the offset of a
  /// debugging information entry in the current compilation unit which must
  /// have a base type entry that provides the type of the data pushed.
  case derefType(UInt8, UInt64)
  /// Provides an extended dereference mechanism.
  ///
  /// The entry at the top of the stack is treated as an address.  The second
  /// stack entry is treated as an "address space identifier" for those
  /// architectures that support multiple address spaces.  Both of these
  /// entries must have integral type identifiers.
  ///
  /// The top two stack elements are popped, and a data item is retrieved
  /// through an implementation-defined address calculation and pushed as the
  /// new stack top together with the generic type identifier.  The size of the
  /// data retrieved from the dereferenced address is the size of the
  /// generic type.
  case xderef
  /// Provides an extended dereference mechanism.
  ///
  /// The entry at the top of the stack is treated as an address.  The second
  /// stack entry is treated as an "address space identifier" for those
  /// architectures that support multiple address spaces.  Both of these
  /// entries must have integral type identifiers.
  ///
  /// The top two stack elements are popped, and a data item is retrieved
  /// through an implementation-defined address calculation and pushed as the
  /// new stack top together with the generic type identifier.  The size of the
  /// data retrieved from the dereferenced address is specified by the
  /// operand, whose value is a 1-byte unsigned integral constant.  The data
  /// retrieved is zero-extended to the size of an address on the target machine
  /// before being pushed onto the expression stack.
  case xderefSize(UInt8)
  /// Pops the top two stack entries, treats them as an address and an address
  /// space identifier, and pushes the value retrieved.
  /// The size of the data retrieved from the dereferenced address is specified
  /// by the first operand, whose value is a 1-byte unsigned integral constant.
  /// The data retrieved is zero-extended to the size of an address on the
  /// target machine before being pushed onto the expression stack.  The second
  /// operand is an unsigned little-endian base-128 integer that represents the
  /// offset of a debugging information entry in the current compilation unit,
  /// which must have base type that provides the type of the data pushed.
  case xderefType(UInt8, UInt64)

  /// Pushes the address of the object currently being evaluated as part of
  /// evaluationo of a user-presented expression.  The object may correspond
  /// to an indepdendent variable deescribed by its own debugging information
  /// entry or it may be a component of an array, structure, or class whose
  /// address has been dynamically determined by an earlier step during
  /// user expression evaluation.
  case pushObjectAddress
  /// Pops a value from the stack, which must have an integral type identifier,
  /// translates this value into an address in the thread-local storage for a
  /// thread, and pushes the addreess onto the stack together with the generic
  /// type identifier.  The meaning of the value on the top of the stack prior
  /// to this operation is defined by the run-time environment.  If the run-time
  /// environment supports multiple thread-local storage blocks for a single
  /// thread, then the block corresponding to the executable or shared library
  /// containing this DWARF expreession is used.
  case formTLSAddress
  /// Pushes the value of the Canonical Frame Address (CFA), obtained from the
  /// Call Frame Information.
  case callFrameCFA

  // MARK: Arithmetic and Logical Operations

  /// Pops the top stack entry, interprets it as a signed value and pushes its
  /// absolute value.  If the absolute value cannot be represented, the result
  /// is undefined.
  case abs
  /// Pops the top two stack values, performs a bitwise and operation on the
  /// two, and pushes the result.
  case and
  /// Pops the top two stack values, divides the former second entry by the
  /// former top of the stack using signed division, and pushes the result.
  case div
  /// Pops the top two stack values, subtracts the former second entry by the
  /// former top of the stack, and pushes the result.
  case minus
  /// Pops the top two stack values, performs a modulo operation on the
  /// two, and pushes the result.
  case mod
  /// Pops the top two stack values, multiplies the former second entry by the
  /// former top of the stack, and pushes the result.
  case mul
  /// Pops the top stack entry, interprets it as a signed value, and pushes its
  /// negation.  If the negation cannot be represented, the result is undefined.
  case neg
  /// Pops the top stack entry, and pushes its bitwise complement.
  case not
  /// Pops the top two stack entries, performs a bitwise or operation on the
  /// two, and pushes the result.
  case or
  /// Pops the top two stack entries, adds them together, and pushes the result.
  case plus
  /// Pops the top stack entry, adds it to the unsigned little-endian base-128
  /// constant operand interpreted as the same type as the operand popped from
  /// the top of the stack and pushes the result.
  case plus_uconst(UInt64)
  /// Pops the top twoo stack entries, shifts the former second entry left
  /// (filling with zero bits) by the number of bits specified by the former
  /// top of the stack, and pushes the result.
  case shl
  /// Pops the top two stack entries, shifts the former second entry right
  /// logically (filling with zero bits) by the number of bits specified by
  /// the former top of the stack, and pushes the result.
  case shr
  /// Pops the top two stack entries, shifts the former second entry right
  /// arithmetically (divides the magnitude by 2, keeps the same sign for the
  /// result) by the number of bits specified by the former top of the stack,
  /// and pushes the result.
  case shra
  /// Pops the top two stack entries, performs a bitwise exclusive-or operation
  /// on the two, and pushes the result.
  case xor

  // MARK: Control Flow Operations

  /// Pops the top two stack values, which must have the same type, either
  /// the base type or the generic type, compares them using the `=` relational
  /// operator, and pushes the constant 1 onto the stack if the result is
  /// true, else pushes the constnat value 0 if the result is false.
  case eq
  /// Pops the top two stack values, which must have the same type, either
  /// the base type or the generic type, compares them using the `>=` relational
  /// operator, and pushes the constant 1 onto the stack if the result is
  /// true, else pushes the constnat value 0 if the result is false.
  case ge
  /// Pops the top two stack values, which must have the same type, either
  /// the base type or the generic type, compares them using the `>` relational
  /// operator, and pushes the constant 1 onto the stack if the result is
  /// true, else pushes the constnat value 0 if the result is false.
  case gt
  /// Pops the top two stack values, which must have the same type, either
  /// the base type or the generic type, compares them using the `<=` relational
  /// operator, and pushes the constant 1 onto the stack if the result is
  /// true, else pushes the constnat value 0 if the result is false.
  case le
  /// Pops the top two stack values, which must have the same type, either
  /// the base type or the generic type, compares them using the `<` relational
  /// operator, and pushes the constant 1 onto the stack if the result is
  /// true, else pushes the constnat value 0 if the result is false.
  case lt
  /// Pops the top two stack values, which must have the same type, either
  /// the base type or the generic type, compares them using the `!=` relational
  /// operator, and pushes the constant 1 onto the stack if the result is
  /// true, else pushes the constnat value 0 if the result is false.
  case ne
  /// Unconditionally branches forward or backward by the number of bytes
  /// specified in its operand.
  case skip(Int16)
  /// Conditionally branches forward or backward by the number of bytes
  /// specified in its operand according to the value at the top of the stack.
  /// The top of the stack is popped, and if it is non-zero then the branch is
  /// performed.
  case bra(Int16)

  /// Performs a DWARF procedure call during the evaluation of a DWARF
  /// expression or location description.  The operand is the 2-byte unsigned
  /// offset of a debugging information entry in the current compilation unit.
  ///
  /// For references from one executable or shared object file to another,
  /// the relocation must be performed by the consumer.
  ///
  /// This operation transfers control of DWARF expression evaluation to the
  /// `DW_AT_location` attribute of the referenced debugging information entry.
  /// If there is no such attribute, then there is no effect.  Execution
  /// returns to the point following the call when the end of the attribute
  /// is reached.
  case call2(UInt16)
  /// Performs a DWARF procedure call during the evaluation of a DWARF
  /// expression or location description.  The operand is the 4-byte unsigned
  /// offset of a debugging information entry in the current compilation unit.
  ///
  /// For references from one executable or shared object file to another,
  /// the relocation must be performed by the consumer.
  ///
  /// This operation transfers control of DWARF expression evaluation to the
  /// `DW_AT_location` attribute of the referenced debugging information entry.
  /// If there is no such attribute, then there is no effect.  Execution
  /// returns to the point following the call when the end of the attribute
  /// is reached.
  case call4(UInt32)
  /// Performs a DWARF procedure call during the evaluation of a DWARF
  /// expression or location description.  The operand is used as the offset of
  /// a debugging information entry in a `.debug_info` section which may be
  /// contained in an executable or shared object file rather than that
  /// containing the operator.
  ///
  /// For references from one executable or shared object file to another,
  /// the relocation must be performed by the consumer.
  ///
  /// This operation transfers control of DWARF expression evaluation to the
  /// `DW_AT_location` attribute of the referenced debugging information entry.
  /// If there is no such attribute, then there is no effect.  Execution
  /// returns to the point following the call when the end of the attribute
  /// is reached.
  case callRef(UInt64)

  // MARK: Type Conversions

  /// Pops the top stack entry, converts it to a different type, then pushes the
  /// result.
  ///
  /// The operand is an unsigned little-endian base-128 integer that represents
  /// the offset of a debugging information entry in the current compilation
  /// unit, or value 0 which represents the generic type.  If the operand is
  /// non-zero, the referenced entry must be a base type entry that provides the
  /// type to which the value is converted.
  case convert(UInt64)
  /// Pops the top stack entry, reinterprets the bits in its value as a value of
  /// a different type, then pushes the result.
  ///
  /// The operand is an unsigned little-endian base-128 integer that represents
  /// the offset of a debugging information entry in the current compilation
  /// unit, or value 0 which represents the generic type.  If the operand is
  /// non-zero, the referenced entry must be a base type entry that provides the
  /// type to which the value is converted.
  case reinterpret(UInt64)


  // MARK: Special Operations

  /// This operation has no effect on the location stack or any of its values.
  case nop
  /// Pushes the value that the described location held upon entering the
  /// current subprogram.  The first operand is an unsigned little-endian
  /// base-128 number expressing the length of the second operand in bytes.  The
  /// second operand is a block containing a DWARF expression or a register
  /// location description.
  indirect case entryValue(UInt64, DWARFExpression)

  // MARK: Location Descriptions

  /// Encodes the name of the register numbered 0.
  case reg0
  /// Encodes the name of the register numbered 1.
  case reg1
  /// Encodes the name of the register numbered 2.
  case reg2
  /// Encodes the name of the register numbered 3.
  case reg3
  /// Encodes the name of the register numbered 4.
  case reg4
  /// Encodes the name of the register numbered 5.
  case reg5
  /// Encodes the name of the register numbered 6.
  case reg6
  /// Encodes the name of the register numbered 7.
  case reg7
  /// Encodes the name of the register numbered 8.
  case reg8
  /// Encodes the name of the register numbered 9.
  case reg9
  /// Encodes the name of the register numbered 10.
  case reg10
  /// Encodes the name of the register numbered 11.
  case reg11
  /// Encodes the name of the register numbered 12.
  case reg12
  /// Encodes the name of the register numbered 13.
  case reg13
  /// Encodes the name of the register numbered 14.
  case reg14
  /// Encodes the name of the register numbered 15.
  case reg15
  /// Encodes the name of the register numbered 16.
  case reg16
  /// Encodes the name of the register numbered 17.
  case reg17
  /// Encodes the name of the register numbered 18.
  case reg18
  /// Encodes the name of the register numbered 19.
  case reg19
  /// Encodes the name of the register numbered 20.
  case reg20
  /// Encodes the name of the register numbered 21.
  case reg21
  /// Encodes the name of the register numbered 22.
  case reg22
  /// Encodes the name of the register numbered 23.
  case reg23
  /// Encodes the name of the register numbered 24.
  case reg24
  /// Encodes the name of the register numbered 25.
  case reg25
  /// Encodes the name of the register numbered 26.
  case reg26
  /// Encodes the name of the register numbered 27.
  case reg27
  /// Encodes the name of the register numbered 28.
  case reg28
  /// Encodes the name of the register numbered 29.
  case reg29
  /// Encodes the name of the register numbered 30.
  case reg30
  /// Encodes the name of the register numbered 31.
  case reg31

  /// Contains a single unsigned little-endian base-128 literal operand that
  /// encodes the name of a register.
  case regx(UInt64)

  // MARK: Implicit Location Descriptionos

  /// Specifies an immediate value using two operands: an unsigned little-endian
  /// base-128 length, followed by a sequence of bytes of the given length that
  /// contain the value.
  case implicitValue(UInt64, [UInt8])

  /// Specifies that the object does not exist in memory, but its value is
  /// nonetheless known and is at the top of the DWARF expression stack.  In
  /// this form of location description, the DWARF expression represents the
  /// actual value of the object, rather than its location.
  ///
  /// `stackValue` acts as an expression terminator.
  case stackValue

  // MARK: Composite Location Descriptions

  /// Takes a single operand in little-endian base-128 form.  This operand
  /// describes the size in bytes of the piece of the object referenced by the
  /// preceding simple location description.  If the piece is located in a
  /// register, but does not occupy the entire register, the placement of
  /// the piece within that register is defined by the ABI.
  case piece(UInt64)
  /// Takes two operands, an unsigned little-endian base-128 form number that
  /// gives the size in bits of the piece.  The second is an unsigned little-
  /// endian base-128 number that gives the offset in bits from the location
  /// defined by the preceding DWARF location description.
  ///
  /// `bitPiece` is used instead of `piece` when the piece to be assembled into
  /// a value or assigned to is not byte-sized or is not at the start of a
  /// register or addressable unit of memory.
  ///
  /// Interpretation of the offset depends on the location description. If the
  /// location description is empty, the offset doesn’t matter and the
  /// `bitPiece` operation describes a piece consisting of the given number of
  /// bits whose values are undefined. If the location is a register, the offset
  /// is from the least significant bit end of the register. If the location is
  /// a memory address, the `bitPiece` operation describes a sequence of bits
  /// relative to the location whose address is on the top of the DWARF stack
  /// using the bit numbering and direction conventions that are appropriate to
  /// the current language on the target system. If the location is any implicit
  /// value or stack value, the `bitPiece` operation describes a sequence of
  /// bits using the least significant bits of that value.
  case bitPiece(UInt64, UInt64)

  /// Specifies that the object is a pointer that cannot be represented as a
  /// real pointer, even though the value it would point to can be described.
  ///
  /// In this form of location description, the DWARF expression refers to a
  /// debugging information entry that represents the actual value of the object
  /// to which the pointer would point. Thus, a consumer of the debug
  /// information would be able to show the value of the dereferenced pointer,
  /// even when it cannot show the value of the pointer itself.
  ///
  /// The first operand is used as the offset of a debugging information entry
  /// in a `.debug_info` section, which may be contained in an executable or
  /// shared object file other than that containing the operator.
  ///
  /// For references from one executable or shared object file to another, the
  /// relocation must be performed by the consumer.
  case implicitPointer(UInt64, Int64)
}

extension DWARFExpression {
  var rawValue: [UInt64] {
    switch self {
    case let .addr(val):
      return [ 0x03, val ]
    case .deref:
      return [ 0x06 ]
    case let .const1u(val):
      return [ 0x08, UInt64(val) ]
    case let .const1s(val):
      return [ 0x09, UInt64(bitPattern: Int64(val)) ]
    case let .const2u(val):
      return [ 0x0a, UInt64(val) ]
    case let .const2s(val):
      return [ 0x0b, UInt64(bitPattern: Int64(val)) ]
    case let .const4u(val):
      return [ 0x0c, UInt64(val) ]
    case let .const4s(val):
      return [ 0x0d, UInt64(bitPattern: Int64(val)) ]
    case let .const8u(val):
      return [ 0x0e, val ]
    case let .const8s(val):
      return [ 0x0f, UInt64(bitPattern: Int64(val)) ]
    case let .constu(val):
      return [ 0x10, val ]
    case let .consts(val):
      return [ 0x11, UInt64(bitPattern: val) ]
    case .dup:
      return [ 0x12 ]
    case .drop:
      return [ 0x13 ]
    case .over:
      return [ 0x14 ]
    case let .pick(val):
      return [ 0x15, UInt64(val) ]
    case .swap:
      return [ 0x16 ]
    case .rot:
      return [ 0x17 ]
    case .xderef:
      return [ 0x18 ]
    case .abs:
      return [ 0x19 ]
    case .and:
      return [ 0x1a ]
    case .div:
      return [ 0x1b ]
    case .minus:
      return [ 0x1c ]
    case .mod:
      return [ 0x1d ]
    case .mul:
      return [ 0x1e ]
    case .neg:
      return [ 0x1f ]
    case .not:
      return [ 0x20 ]
    case .or:
      return [ 0x21 ]
    case .plus:
      return [ 0x22 ]
    case let .plus_uconst(val):
      return [ 0x23, val ]
    case .shl:
      return [ 0x24 ]
    case .shr:
      return [ 0x25 ]
    case .shra:
      return [ 0x26 ]
    case .xor:
      return [ 0x27 ]
    case .skip:
      return [ 0x2f ]
    case .bra:
      return [ 0x28 ]
    case .eq:
      return [ 0x29 ]
    case .ge:
      return [ 0x2a ]
    case .gt:
      return [ 0x2b ]
    case .le:
      return [ 0x2c ]
    case .lt:
      return [ 0x2d ]
    case .ne:
      return [ 0x2e ]
    case .lit0:
      return [ 0x30 ]
    case .lit1:
      return [ 0x31 ]
    case .lit2:
      return [ 0x32 ]
    case .lit3:
      return [ 0x33 ]
    case .lit4:
      return [ 0x34 ]
    case .lit5:
      return [ 0x35 ]
    case .lit6:
      return [ 0x36 ]
    case .lit7:
      return [ 0x37 ]
    case .lit8:
      return [ 0x38 ]
    case .lit9:
      return [ 0x39 ]
    case .lit10:
      return [ 0x3a ]
    case .lit11:
      return [ 0x3b ]
    case .lit12:
      return [ 0x3c ]
    case .lit13:
      return [ 0x3d ]
    case .lit14:
      return [ 0x3e ]
    case .lit15:
      return [ 0x3f ]
    case .lit16:
      return [ 0x40 ]
    case .lit17:
      return [ 0x41 ]
    case .lit18:
      return [ 0x42 ]
    case .lit19:
      return [ 0x43 ]
    case .lit20:
      return [ 0x44 ]
    case .lit21:
      return [ 0x45 ]
    case .lit22:
      return [ 0x46 ]
    case .lit23:
      return [ 0x47 ]
    case .lit24:
      return [ 0x48 ]
    case .lit25:
      return [ 0x49 ]
    case .lit26:
      return [ 0x4a ]
    case .lit27:
      return [ 0x4b ]
    case .lit28:
      return [ 0x4c ]
    case .lit29:
      return [ 0x4d ]
    case .lit30:
      return [ 0x4e ]
    case .lit31:
      return [ 0x4f ]
    case .reg0:
      return [ 0x50 ]
    case .reg1:
      return [ 0x51 ]
    case .reg2:
      return [ 0x52 ]
    case .reg3:
      return [ 0x53 ]
    case .reg4:
      return [ 0x54 ]
    case .reg5:
      return [ 0x55 ]
    case .reg6:
      return [ 0x56 ]
    case .reg7:
      return [ 0x57 ]
    case .reg8:
      return [ 0x58 ]
    case .reg9:
      return [ 0x59 ]
    case .reg10:
      return [ 0x5a ]
    case .reg11:
      return [ 0x5b ]
    case .reg12:
      return [ 0x5c ]
    case .reg13:
      return [ 0x5d ]
    case .reg14:
      return [ 0x5e ]
    case .reg15:
      return [ 0x5f ]
    case .reg16:
      return [ 0x60 ]
    case .reg17:
      return [ 0x61 ]
    case .reg18:
      return [ 0x62 ]
    case .reg19:
      return [ 0x63 ]
    case .reg20:
      return [ 0x64 ]
    case .reg21:
      return [ 0x65 ]
    case .reg22:
      return [ 0x66 ]
    case .reg23:
      return [ 0x67 ]
    case .reg24:
      return [ 0x68 ]
    case .reg25:
      return [ 0x69 ]
    case .reg26:
      return [ 0x6a ]
    case .reg27:
      return [ 0x6b ]
    case .reg28:
      return [ 0x6c ]
    case .reg29:
      return [ 0x6d ]
    case .reg30:
      return [ 0x6e ]
    case .reg31:
      return [ 0x6f ]
    case let .breg0(val):
      return [ 0x70, UInt64(bitPattern: val)]
    case let .breg1(val):
      return [ 0x71, UInt64(bitPattern: val) ]
    case let .breg2(val):
      return [ 0x72, UInt64(bitPattern: val) ]
    case let .breg3(val):
      return [ 0x73, UInt64(bitPattern: val) ]
    case let .breg4(val):
      return [ 0x74, UInt64(bitPattern: val) ]
    case let .breg5(val):
      return [ 0x75, UInt64(bitPattern: val) ]
    case let .breg6(val):
      return [ 0x76, UInt64(bitPattern: val) ]
    case let .breg7(val):
      return [ 0x77, UInt64(bitPattern: val) ]
    case let .breg8(val):
      return [ 0x78, UInt64(bitPattern: val) ]
    case let .breg9(val):
      return [ 0x79, UInt64(bitPattern: val) ]
    case let .breg10(val):
      return [ 0x7a, UInt64(bitPattern: val) ]
    case let .breg11(val):
      return [ 0x7b, UInt64(bitPattern: val) ]
    case let .breg12(val):
      return [ 0x7c, UInt64(bitPattern: val) ]
    case let .breg13(val):
      return [ 0x7d, UInt64(bitPattern: val) ]
    case let .breg14(val):
      return [ 0x7e, UInt64(bitPattern: val) ]
    case let .breg15(val):
      return [ 0x7f, UInt64(bitPattern: val) ]
    case let .breg16(val):
      return [ 0x80, UInt64(bitPattern: val) ]
    case let .breg17(val):
      return [ 0x81, UInt64(bitPattern: val) ]
    case let .breg18(val):
      return [ 0x82, UInt64(bitPattern: val) ]
    case let .breg19(val):
      return [ 0x83, UInt64(bitPattern: val) ]
    case let .breg20(val):
      return [ 0x84, UInt64(bitPattern: val) ]
    case let .breg21(val):
      return [ 0x85, UInt64(bitPattern: val) ]
    case let .breg22(val):
      return [ 0x86, UInt64(bitPattern: val) ]
    case let .breg23(val):
      return [ 0x87, UInt64(bitPattern: val) ]
    case let .breg24(val):
      return [ 0x88, UInt64(bitPattern: val) ]
    case let .breg25(val):
      return [ 0x89, UInt64(bitPattern: val) ]
    case let .breg26(val):
      return [ 0x8a, UInt64(bitPattern: val) ]
    case let .breg27(val):
      return [ 0x8b, UInt64(bitPattern: val) ]
    case let .breg28(val):
      return [ 0x8c, UInt64(bitPattern: val) ]
    case let .breg29(val):
      return [ 0x8d, UInt64(bitPattern: val) ]
    case let .breg30(val):
      return [ 0x8e, UInt64(bitPattern: val) ]
    case let .breg31(val):
      return [ 0x8f, UInt64(bitPattern: val) ]
    case let .regx(val):
      return [ 0x90, val ]
    case let .fbreg(val):
      return [ 0x91, UInt64(bitPattern: val) ]
    case let .bregx(val1, val2):
      return [ 0x92, val1 , UInt64(bitPattern: val2) ]
    case let .piece(val):
      return [ 0x93, val ]
    case let .derefSize(val):
      return [ 0x94, UInt64(val) ]
    case let .xderefSize(val):
      return [ 0x95, UInt64(val) ]
    case .nop:
      return [ 0x96 ]
    case .pushObjectAddress:
      return [ 0x97 ]
    case let .call2(val):
      return [ 0x98, UInt64(val) ]
    case let .call4(val):
      return [ 0x99, UInt64(val) ]
    case let .callRef(val):
      return [ 0x9a, val ]
    case .formTLSAddress:
      return [ 0x9b ]
    case .callFrameCFA:
      return [ 0x9c ]
    case let .bitPiece(val1, val2):
      return [ 0x9d, val1, val2 ]
    case let .implicitValue(val, bytes):
      return [ 0x9e, val ] + packBytes(bytes)
    case .stackValue:
      return [ 0x9f ]
    case let .implicitPointer(val1, val2):
      return [ 0xa0, val1, UInt64(bitPattern: val2) ]
    case let .addrx(val):
      return [ 0xa1, val ]
    case let .constx(val):
      return [ 0xa2, val ]
    case let .entryValue(val1, val2):
      return [ 0xa3, val1 ] + val2.rawValue
    case let .constType(ate, n, bytes):
      assert(Int(n) == bytes.count)
      return [ 0xa4, UInt64(ate.llvm), UInt64(n) ] + packBytes(bytes)
    case let .regvalType(reg, ate):
      return [ 0xa5, reg, UInt64(ate.llvm) ]
    case let .derefType(val, ty):
      return [ 0xa6, UInt64(val), ty ]
    case let .xderefType(val, ty):
      return [ 0xa7, UInt64(val), ty ]
    case let .convert(ty):
      return [ 0xa7, ty ]
    case let .reinterpret(ty):
      return [ 0xa7, ty ]
    }
  }
}

private func packBytes(_ bytes: [UInt8]) -> [UInt64] {
  guard !bytes.isEmpty else {
    return []
  }

  var res = [UInt64]()
  res.reserveCapacity(bytes.count/MemoryLayout<UInt64>.size)
  var accum: UInt64 = 0
  for (idx, val) in bytes.enumerated() {
    // If we've packed all the way through the accumulator, append it and
    // start afresh.
    if idx != 0 && idx % MemoryLayout<UInt64>.size == 0 {
      res.append(accum)
      accum = 0
    }

    accum <<= MemoryLayout<UInt64>.size
    accum |= UInt64(val)
  }

  // Pack on the straggler if we're not packing a perfect multiple.
  if bytes.count % MemoryLayout<UInt64>.size != 0 {
    res.append(accum)
  }
  return res
}

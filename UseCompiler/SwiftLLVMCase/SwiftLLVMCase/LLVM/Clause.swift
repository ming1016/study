//
//  Clause.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// Enumerates the supported kind of clauses.
public enum LandingPadClause: IRValue {
  /// This clause means that the landingpad block should be entered if the
  /// exception being thrown matches or is a subtype of its type.
  ///
  /// For C++, the type is a pointer to the `std::type_info` object
  /// (an RTTI object) representing the C++ exception type.
  ///
  /// If the type is `null`, any exception matches, so the landing pad should
  /// always be entered. This is used for C++ catch-all blocks (`catch (...)`).
  ///
  /// When this clause is matched, the selector value will be equal to the value
  /// returned by `@llvm.eh.typeid.for(i8* @ExcType)`. This will always be a
  /// positive value.
  case `catch`(IRGlobal)
  /// This clause means that the landing pad should be entered if the exception
  /// being thrown does not match any of the types in the list (which, for C++,
  /// are again specified as `std::type_info pointers`).
  ///
  /// C++ front-ends use this to implement C++ exception specifications, such as
  /// `void foo() throw (ExcType1, ..., ExcTypeN) { ... }`.
  ///
  /// When this clause is matched, the selector value will be negative.
  ///
  /// The array argument to filter may be empty; for example, `[0 x i8**] undef`.
  /// This means that the landing pad should always be entered. (Note that such
  /// a filter would not be equivalent to `catch i8* null`, because filter and
  /// catch produce negative and positive selector values respectively.)
  case filter(IRType, [IRGlobal])

  public func asLLVM() -> LLVMValueRef {
    switch self {
    case let .`catch`(val):
      return val.asLLVM()
    case let .filter(ty, arr):
      return ArrayType.constant(arr, type: ty).asLLVM()
    }
  }
}


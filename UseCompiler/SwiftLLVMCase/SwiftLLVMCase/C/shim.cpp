//
//  shim.c
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

#include "llvm-c/Core.h"
#include "llvm-c/Object.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/GlobalsModRef.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/DIBuilder.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Object/MachOUniversal.h"
#include "llvm/Object/ObjectFile.h"
#include "llvm/Support/ARMTargetParser.h"
#include "llvm/Transforms/Utils.h"
#include "llvm/Transforms/IPO.h"

extern "C" {
  // Not to be upstreamed: They support the hacks that power our dynamic member
  // lookup machinery for intrinsics.
  const char *LLVMSwiftGetIntrinsicAtIndex(size_t index);
  size_t LLVMSwiftCountIntrinsics(void);

  // Not to be upstreamed: There's no value in this without a full Triple
  // API.  And we have chosen to port instead of wrap.
  const char *LLVMGetARMCanonicalArchName(const char *Name, size_t NameLen);

  typedef enum {
    LLVMARMProfileKindInvalid = 0,
    LLVMARMProfileKindA,
    LLVMARMProfileKindR,
    LLVMARMProfileKindM
  } LLVMARMProfileKind;

  LLVMARMProfileKind LLVMARMParseArchProfile(const char *Name, size_t NameLen);
  unsigned LLVMARMParseArchVersion(const char *Name, size_t NameLen);

  // Not to be upstreamed: It's not clear there's value in having this outside
  // of PGO passes.
  uint64_t LLVMGlobalGetGUID(LLVMValueRef Global);

  // https://reviews.llvm.org/D66237
  void LLVMAddGlobalsAAWrapperPass(LLVMPassManagerRef PM);

  // https://reviews.llvm.org/D66061
  typedef enum {
    LLVMTailCallKindNone,
    LLVMTailCallKindTail,
    LLVMTailCallKindMustTail,
    LLVMTailCallKindNoTail
  } LLVMTailCallKind;

  LLVMTailCallKind LLVMGetTailCallKind(LLVMValueRef CallInst);
  void LLVMSetTailCallKind(LLVMValueRef CallInst, LLVMTailCallKind TCK);
}

using namespace llvm;
using namespace llvm::object;

size_t LLVMSwiftCountIntrinsics(void) {
  return llvm::Intrinsic::num_intrinsics;
}

const char *LLVMSwiftGetIntrinsicAtIndex(size_t index) {
  return llvm::Intrinsic::getName(static_cast<llvm::Intrinsic::ID>(index)).data();
}

LLVMARMProfileKind LLVMARMParseArchProfile(const char *Name, size_t NameLen) {
  return static_cast<LLVMARMProfileKind>(llvm::ARM::parseArchProfile({Name, NameLen}));
}

unsigned LLVMARMParseArchVersion(const char *Name, size_t NameLen) {
  return llvm::ARM::parseArchVersion({Name, NameLen});
}

const char *LLVMGetARMCanonicalArchName(const char *Name, size_t NameLen) {
  return llvm::ARM::getCanonicalArchName({Name, NameLen}).data();
}

uint64_t LLVMGlobalGetGUID(LLVMValueRef Glob) {
  return unwrap<GlobalValue>(Glob)->getGUID();
}

void LLVMAddGlobalsAAWrapperPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createGlobalsAAWrapperPass());
}

LLVMTailCallKind LLVMGetTailCallKind(LLVMValueRef Call) {
  switch (unwrap<CallInst>(Call)->getTailCallKind()) {
  case CallInst::TailCallKind::TCK_None:
    return LLVMTailCallKindNone;
  case CallInst::TailCallKind::TCK_Tail:
    return LLVMTailCallKindTail;
  case CallInst::TailCallKind::TCK_MustTail:
    return LLVMTailCallKindMustTail;
  case CallInst::TailCallKind::TCK_NoTail:
    return LLVMTailCallKindNoTail;
  }
}

void LLVMSetTailCallKind(LLVMValueRef Call, LLVMTailCallKind TCK) {
  CallInst::TailCallKind kind;
  switch (TCK) {
  case LLVMTailCallKindNone:
    kind = CallInst::TailCallKind::TCK_None;
    break;
  case LLVMTailCallKindTail:
    kind = CallInst::TailCallKind::TCK_Tail;
    break;
  case LLVMTailCallKindMustTail:
    kind = CallInst::TailCallKind::TCK_MustTail;
    break;
  case LLVMTailCallKindNoTail:
    kind = CallInst::TailCallKind::TCK_NoTail;
    break;
  }

  unwrap<CallInst>(Call)->setTailCallKind(kind);
}

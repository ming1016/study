//
//  shim.h
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

#include <stddef.h>
#include "llvm-c/Types.h"
#include "llvm-c/Object.h"
#include "llvm-c/DebugInfo.h"

#ifndef shim_h
#define shim_h

size_t LLVMSwiftCountIntrinsics(void);
const char *LLVMSwiftGetIntrinsicAtIndex(size_t index);
const char *LLVMGetARMCanonicalArchName(const char *Name, size_t NameLen);

typedef enum {
  LLVMARMProfileKindInvalid = 0,
  LLVMARMProfileKindA,
  LLVMARMProfileKindR,
  LLVMARMProfileKindM
} LLVMARMProfileKind;
LLVMARMProfileKind LLVMARMParseArchProfile(const char *Name, size_t NameLen);
unsigned LLVMARMParseArchVersion(const char *Name, size_t NameLen);

uint64_t LLVMGlobalGetGUID(LLVMValueRef Global);

void LLVMAddGlobalsAAWrapperPass(LLVMPassManagerRef PM);

typedef enum {
  LLVMTailCallKindNone,
  LLVMTailCallKindTail,
  LLVMTailCallKindMustTail,
  LLVMTailCallKindNoTail
} LLVMTailCallKind;

LLVMTailCallKind LLVMGetTailCallKind(LLVMValueRef CallInst);
void LLVMSetTailCallKind(LLVMValueRef CallInst, LLVMTailCallKind TCK);

#endif /* shim_h */

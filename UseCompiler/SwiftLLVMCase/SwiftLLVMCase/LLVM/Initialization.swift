//
//  Initialization.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// initializer that calls LLVM initialization functions only once.
public func initializeLLVM() {
  _ = llvmInitializer
}

/// Calls all the LLVM functions to initialize:
///
/// - Targets
/// - Target Infos
/// - ASM Printers
/// - ASM Parsers
/// - Target MCs
/// - Disassemblers
let llvmInitializer: Void = {
  LLVMInitializeAllTargets()
  LLVMInitializeAllTargetInfos()

  LLVMInitializeAllAsmPrinters()
  LLVMInitializeAllAsmParsers()

  LLVMInitializeAllTargetMCs()

  LLVMInitializeAllDisassemblers()
}()

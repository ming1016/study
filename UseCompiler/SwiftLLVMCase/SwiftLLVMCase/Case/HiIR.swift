//
//  HiIR.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import Foundation
import llvm

func hiIR() {
    let module = LLVMModuleCreateWithName("HiModule")
    LLVMDumpModule(module)
    LLVMDisposeModule(module)
}

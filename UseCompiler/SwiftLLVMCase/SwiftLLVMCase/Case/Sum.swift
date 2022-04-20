//
//  Sum.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import Foundation
import llvm

func sum() {
    let module = LLVMModuleCreateWithName("Sum")
    let int32 = LLVMInt32Type()
    let paramTypes = [int32, int32]
    
//    var paramTypesRef = UnsafeMutablePointer<LLVMTypeRef>.allocate(capacity: paramTypes.count)
//    paramTypesRef.initialize(from: UnsafePointer<LLVMTypeRef>, count: <#T##Int#>)
    let returnType = int32
//    let functionType = LLVMFunctionType(returnType, paramTypes, UInt32(paramTypes.count), 0)
}

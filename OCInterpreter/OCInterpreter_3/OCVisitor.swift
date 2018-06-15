//
//  OCVisitor.swift
//  HTN
//
//  Created by DaiMing on 2018/6/11.
//

import Foundation

protocol OCVisitor: class {
    func visit(node: OCAST)
    func visit(number: OCNumber)
    func visit(binOp: OCBinOp)
}

extension OCVisitor {
    func visit(node: OCAST) {
        switch node {
        case let number as OCNumber:
            visit(number: number)
        case let binOp as OCBinOp:
            visit(binOp: binOp)
        default:
            fatalError("Error: Visitor type error")
        }
    }
    
    func visit(number _: OCNumber)  {
        
    }
    func visit(binOp: OCBinOp) {
        visit(node: binOp.left)
        visit(node: binOp.right)
    }
}

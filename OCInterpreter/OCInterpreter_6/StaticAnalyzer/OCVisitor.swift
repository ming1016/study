//
//  OCVisitor.swift
//  HTN
//
//  Created by DaiMing on 2018/6/11.
//

import Foundation

protocol OCVisitor: class {
    func visit(node: OCAST)
    func visit(program: OCProgram)
    func visit(interface: OCInterface)
    func visit(propertyDeclaration: OCPropertyDeclaration)
    func visit(propertyAttribute: OCPropertyAttribute)
    func visit(implementation: OCImplementation)
    func visit(method: OCMethod)
    func visit(compoundStatement: OCCompoundStatement)
    func visit(identifier: OCIdentifier)
    func visit(assign: OCAssign)
    func visit(variable: OCVar)
    func visit(number: OCNumber)
    func visit(unaryOperation: OCUnaryOperation)
    func visit(binOp: OCBinOp)
    func visit(noOp: OCNoOp)
    func visit(variableDeclaration: OCVariableDeclaration)
}

extension OCVisitor {
    func visit(node: OCAST) {
        switch node {
        case let program as OCProgram:
            visit(program: program)
        case let interface as OCInterface:
            visit(interface: interface)
        case let propertyDeclaration as OCPropertyDeclaration:
            visit(propertyDeclaration: propertyDeclaration)
        case let propertyAttribute as OCPropertyAttribute:
            visit(propertyAttribute: propertyAttribute)
        case let implementation as OCImplementation:
            visit(implementation: implementation)
        case let method as OCMethod:
            visit(method: method)
        case let compoundStatement as OCCompoundStatement:
            visit(compoundStatement: compoundStatement)
        case let identifier as OCIdentifier:
            visit(identifier: identifier)
        case let assign as OCAssign:
            visit(assign: assign)
        case let variable as OCVar:
            visit(variable: variable)
        case let number as OCNumber:
            visit(number: number)
        case let unaryOperation as OCUnaryOperation:
            visit(unaryOperation: unaryOperation)
        case let binOp as OCBinOp:
            visit(binOp: binOp)
        case let noOp as OCNoOp:
            visit(noOp: noOp)
        case let variableDeclaration as OCVariableDeclaration:
            visit(variableDeclaration: variableDeclaration)
        default:
            fatalError("Error: Visitor type error")
        }
    }
    
    func visit(program: OCProgram) {
        visit(interface: program.interface)
        visit(implementation: program.implementation)
    }
    
    func visit(interface: OCInterface) {
        for property in interface.propertyList {
            visit(propertyDeclaration: property)
        }
    }
    
    func visit(propertyDeclaration: OCPropertyDeclaration) {
        for propertyAttribute in propertyDeclaration.propertyAttributesList {
            visit(propertyAttribute: propertyAttribute)
        }
    }
    
    func visit(propertyAttribute: OCPropertyAttribute) {
        
    }
    
    func visit(implementation: OCImplementation) {
        for method in implementation.methodList {
            visit(method: method)
        }
    }
    
    func visit(method: OCMethod) {
        for statement in method.statements {
            visit(node: statement)
        }
    }
    
    func visit(compoundStatement: OCCompoundStatement) {
        
    }
    
    func visit(identifier: OCIdentifier) {
        
    }
    
    func visit(assign: OCAssign) {
        visit(node: assign.left)
        visit(node: assign.right)
    }
    
    func visit(variable: OCVar) {
        
    }
    
    func visit(variableDeclaration: OCVariableDeclaration) {
        visit(node: variableDeclaration.variable)
        visit(node: variableDeclaration.right)
    }
    
    /*--------- 运算符 --------*/
    
    func visit(number _: OCNumber)  {
        
    }
    
    func visit(unaryOperation: OCUnaryOperation) {
        visit(node: unaryOperation.operand)
    }
    
    func visit(binOp: OCBinOp) {
        visit(node: binOp.left)
        visit(node: binOp.right)
    }
    func visit(noOp: OCNoOp) {
        
    }
}

//
//  OCInterpreter.swift
//  HTN
//
//  Created by DaiMing on 2018/6/5.
//

import Foundation

public class OCInterpreter {
    
    private let ast: OCAST
    private var scopes: [String: OCValue]
    
    public init(_ input: String) {
        let parser = OCParser(input)
        ast = parser.parse()
        scopes = [String: OCValue]()
        print(ast)
        eval(node: ast)
        print("scope is:")
        print(scopes)
        
        let sa = OCStaticAnalyzer()
        let symtb = sa.analyze(node: ast)
        
        print(symtb)
    }
    
    @discardableResult public func eval(node: OCAST) -> OCValue {
        switch node {
        case let program as OCProgram:
            return eval(program: program)
        case let implementation as OCImplementation:
            return eval(implementation: implementation)
        case let method as OCMethod:
            return eval(method: method)
        case let assign as OCAssign:
            return eval(assign: assign)
        case let variable as OCVar:
            return eval(variable: variable)
        case let variableDeclaration as OCVariableDeclaration:
            return eval(variableDeclaration: variableDeclaration)
        case let number as OCNumber:
            return eval(number: number)
        case let unaryOperation as OCUnaryOperation:
            return eval(unaryOperation: unaryOperation)
        case let binOp as OCBinOp:
            return eval(binOp: binOp)
        default:
            return .none
        }
    }
    
    func eval(program: OCProgram) -> OCValue {
        return eval(implementation: program.implementation)
    }
    
    func eval(implementation: OCImplementation) -> OCValue {
        for method in implementation.methodList {
            eval(method: method)
        }
        return .none
    }
    
    @discardableResult func eval(method: OCMethod) -> OCValue {
        for statement in method.statements {
            eval(node: statement)
        }
        return .none
    }
    
    func eval(assign: OCAssign) -> OCValue {
        scopes[assign.left.name] = eval(node: assign.right)
        return .none
    }
    
    func eval(variable: OCVar) -> OCValue {
        guard let value = scopes[variable.name] else {
            fatalError("Error: eval var")
        }
        return value
    }
    
    func eval(variableDeclaration: OCVariableDeclaration) -> OCValue {
        scopes[variableDeclaration.variable.name] = eval(node: variableDeclaration.right)
        return .none
    }
    
    /*--------- eval 运算符 ----------*/
    func eval(number: OCNumber) -> OCValue {
        return .number(number)
    }
    
    func eval(binOp: OCBinOp) -> OCValue {
        guard case let .number(leftResult) = eval(node: binOp.left), case let .number(rightResult) = eval(node: binOp.right) else {
            fatalError("Error! binOp is wrong")
        }
        
        switch binOp.operation {
        case .plus:
            return .number(leftResult + rightResult)
        case .minus:
            return .number(leftResult - rightResult)
        case .mult:
            return .number(leftResult * rightResult)
        case .intDiv:
            return .number(leftResult / rightResult)
        }
    }
    
    func eval(unaryOperation: OCUnaryOperation) -> OCValue {
        guard case let .number(result) = eval(node: unaryOperation.operand) else {
            fatalError("Error: eval unaryOperation")
        }
        switch unaryOperation.operation {
        case .plus:
            return .number(+result)
        case .minus:
            return .number(-result)
        }
    }
    
}

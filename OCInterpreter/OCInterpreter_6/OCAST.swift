//
//  OCAST.swift
//  HTN
//
//  Created by DaiMing on 2018/6/10.
//

import Foundation

public protocol OCAST {}
public protocol OCDeclaration: OCAST {}

class OCProgram: OCAST {
    let interface: OCInterface
    let implementation: OCImplementation
    init(interface:OCInterface, implementation: OCImplementation) {
        self.interface = interface
        self.implementation = implementation
    }
}

class OCInterface: OCAST {
    let name: String
    let propertyList: [OCPropertyDeclaration]
    init(name: String, propertyList: [OCPropertyDeclaration]) {
        self.name = name
        self.propertyList = propertyList
    }
}

class OCPropertyDeclaration: OCAST {
    let propertyAttributesList: [OCPropertyAttribute]
    let type: String
    let name: String
    init(propertyAttributesList: [OCPropertyAttribute], type: String, name: String) {
        self.propertyAttributesList = propertyAttributesList
        self.type = type
        self.name = name
    }
}

class OCPropertyAttribute: OCAST {
    let name :String
    init(name: String) {
        self.name = name
    }
}

class OCImplementation: OCAST {
    let name: String
    let methodList: [OCMethod]
    init(name: String, methodList: [OCMethod]) {
        self.name = name
        self.methodList = methodList
    }
}

class OCMethod: OCAST {
    let returnIdentifier: String
    let methodName: String
    let statements: [OCAST]
    init(returnIdentifier: String, methodName: String, statements:[OCAST]) {
        self.returnIdentifier = returnIdentifier
        self.methodName = methodName
        self.statements = statements
    }
}

class OCCompoundStatement: OCAST {
    let children: [OCAST]
    init(children: [OCAST]) {
        self.children = children
    }
}

class OCVariableDeclaration: OCDeclaration {
    let variable: OCVar
    let type: String
    let right: OCAST
    
    init(variable: OCVar, type: String, right: OCAST) {
        self.variable = variable
        self.type = type
        self.right = right
    }
}

class OCIdentifier: OCAST {
    let identifier: String
    init(identifier: String) {
        self.identifier = identifier
    }
}

class OCAssign: OCAST {
    let left: OCVar
    let right: OCAST
    
    init(left: OCVar, right: OCAST) {
        self.left = left
        self.right = right
    }
}

class OCVar: OCAST {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

class OCNoOp: OCAST {}

/*--------- 运算符 ---------*/
public enum OCBinOpType {
    case plus
    case minus
    case mult
    case intDiv
}

public enum OCUnaryOperationType {
    case plus
    case minus
}

public enum OCNumber: OCAST {
    case integer(Int)
    case float(Float)
}

class OCUnaryOperation: OCAST {
    let operation: OCUnaryOperationType
    let operand: OCAST
    
    init(operation: OCUnaryOperationType, operand: OCAST) {
        self.operation = operation
        self.operand = operand
    }
}

class OCBinOp: OCAST {
    let left: OCAST
    let operation: OCBinOpType
    let right: OCAST
    
    init(left: OCAST, operation: OCBinOpType, right: OCAST) {
        self.left = left
        self.operation = operation
        self.right = right
    }
}

extension OCNumber: Equatable {
    public static func == (lhs: OCNumber, rhs: OCNumber) -> Bool {
        switch (lhs, rhs) {
        case let (.integer(left), .integer(right)):
            return left == right
        case let (.float(left), .float(right)):
            return left == right
        case let (.float(left), .integer(right)):
            return left == Float(right)
        case let (.integer(left), .float(right)):
            return Float(left) == right
        }
    }
}









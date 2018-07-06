//
//  OCToken.swift
//  HTN
//
//  Created by DaiMing on 2018/6/10.
//

import Foundation

public enum OCValue {
    case none
    case number(OCNumber)
    case boolean(Bool)
    case string(String)
}

public enum OCConstant {
    case integer(Int)
    case float(Float)
    case boolean(Bool)
    case string(String)
}

public enum OCOperation {
    case plus
    case minus
    case mult
    case intDiv
}

public enum OCDirection {
    case left
    case right
}

public enum OCToken {
    case eof
    case whiteSpaceAndNewLine
    case constant(OCConstant)   // int float string bool
    case operation(OCOperation) // + - * /
    case paren(OCDirection)     // ( )
    case brace(OCDirection)     // { }
    case asterisk               // *
    case interface
    case end
    case implementation
    case id(String)             // string
    case semi
    case assign
    case `return`
}

extension OCConstant: Equatable {
    public static func == (lhs: OCConstant, rhs: OCConstant) -> Bool {
        switch (lhs, rhs) {
        case let (.integer(left), .integer(right)):
            return left == right
        case let (.float(left), .float(right)):
            return left == right
        case let (.boolean(left), .boolean(right)):
            return left == right
        case let (.string(left), .string(right)):
            return left == right
        default:
            return false
        }
    }
}

extension OCOperation: Equatable {
    public static func == (lhs: OCOperation, rhs: OCOperation) -> Bool {
        switch (lhs, rhs) {
        case (.plus, .plus):
            return true
        case (.minus, .minus):
            return true
        case (.mult, .mult):
            return true
        case (.intDiv, .intDiv):
            return true
        default:
            return false
        }
    }
}

extension OCDirection: Equatable {
    public static func == (lhs: OCDirection, rhs: OCDirection) -> Bool {
        switch (lhs, rhs) {
        case (.left, .left):
            return true
        case (.right, .right):
            return true
        default:
            return false
        }
    }
}

extension OCToken: Equatable {
    public static func == (lhs: OCToken, rhs: OCToken) -> Bool {
        switch (lhs, rhs) {
        case let (.constant(left), .constant(right)):
            return left == right
        case let (.operation(left), .operation(right)):
            return left == right
        case (.eof, .eof):
            return true
        case (.whiteSpaceAndNewLine, .whiteSpaceAndNewLine):
            return true
        case let (.paren(left), .paren(right)):
            return left == right
        case let (.brace(left), .brace(right)):
            return left == right
        case (.interface, .interface):
            return true
        case (.end, .end):
            return true
        case (.implementation, .implementation):
            return true
        case let (.id(left), .id(right)):
            return left == right
        case (.semi, .semi):
            return true
        case (.assign, .assign):
            return true
        case (.return, .return):
            return true
        default:
            return false
        }
    }
}

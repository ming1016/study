//
//  OCAST.swift
//  HTN
//
//  Created by DaiMing on 2018/6/10.
//

import Foundation

public protocol OCAST {}

public enum OCBinOpType {
    case plus
    case minus
    case mult
    case intDiv
}

public enum OCNumber: OCAST {
    case integer(Int)
    case float(Float)
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









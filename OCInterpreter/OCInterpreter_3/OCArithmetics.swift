//
//  OCArithmetics.swift
//  HTN
//
//  Created by DaiMing on 2018/6/11.
//

import Foundation

extension OCNumber {
    // binOp
    static func + (left: OCNumber, right: OCNumber) -> OCNumber {
        switch (left, right) {
        case let (.integer(left), .integer(right)):
            return .integer(left + right)
        case let (.float(left), .float(right)):
            return .float(left + right)
        case let (.float(left), .integer(right)):
            return .float(left + Float(right))
        case let (.integer(left), .float(right)):
            return .float(Float(left) + right)
        }
    }
    
    static func - (left: OCNumber, right: OCNumber) -> OCNumber {
        switch (left, right) {
        case let (.integer(left), .integer(right)):
            return .integer(left - right)
        case let (.float(left), .float(right)):
            return .float(left - right)
        case let (.float(left), .integer(right)):
            return .float(left - Float(right))
        case let (.integer(left), .float(right)):
            return .float(Float(left) - right)
        }
    }
    
    static func * (left: OCNumber, right: OCNumber) -> OCNumber {
        switch (left, right) {
        case let (.integer(left), .integer(right)):
            return .integer(left * right)
        case let (.float(left), .float(right)):
            return .float(left * right)
        case let (.float(left), .integer(right)):
            return .float(left * Float(right))
        case let (.integer(left), .float(right)):
            return .float(Float(left) * right)
        }
    }
    
    static func / (left: OCNumber, right: OCNumber) -> OCNumber {
        switch (left, right) {
        case let (.integer(left), .integer(right)):
            return .integer(left / right)
        case let (.float(left), .float(right)):
            return .float(left / right)
        case let (.float(left), .integer(right)):
            return .float(left / Float(right))
        case let (.integer(left), .float(right)):
            return .float(Float(left) / right)
        }
    }
        
}

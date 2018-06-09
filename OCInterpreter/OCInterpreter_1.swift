//
//  OCInterpreter.swift
//  HTN
//
//  Created by DaiMing on 2018/6/5.
//

import Foundation

public enum OCConstant {
    case integer(Int)
    case float(Float)
    case boolean(Bool)
    case string(String)
}

public enum OCOperation {
    case plus
}

public enum OCToken {
    case constant(OCConstant)
    case operation(OCOperation)
    case eof
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
        default:
            return false
        }
    }
}

public class OCInterpreter {
    private let text: String
    private var currentIndex: Int
    private var currentCharacter: Character
    
    private var currentTk: OCToken
    
    public init(_ input: String) {
        if input.count == 0 {
            fatalError("Error! input can't be empty")
        }
        self.text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
        currentTk = .eof
    }
    
    // 流程函数
    func nextTk() -> OCToken {
        if currentIndex > self.text.count - 1 {
            return .eof
        }
        
        if CharacterSet.decimalDigits.contains(currentCharacter.unicodeScalars.first!) {
            let tk = OCToken.constant(.integer(Int(String(currentCharacter))!))
            advance()
            return tk
        }
        
        if currentCharacter == "+" {
            advance()
            return .operation(.plus)
        }
        advance()
        return .eof
    }
    
    public func expr() -> Int {
        currentTk = nextTk()
        
        guard case let .constant(.integer(left)) = currentTk else {
            return 0
        }
        eat(currentTk)
        
        eat(.operation(.plus))
        
        guard case let .constant(.integer(right)) = currentTk else {
            return 0
        }
        eat(currentTk)
        
        return left + right
    }
    
    // 辅助函数
    func advance() {
        currentIndex += 1
        guard currentIndex < text.count else {
            return
        }
        currentCharacter = text[text.index(text.startIndex, offsetBy: currentIndex)]
    }
    
    func eat(_ token: OCToken) {
        if  currentTk == token {
            currentTk = nextTk()
        } else {
            error()
        }
    }
    
    func error() {
        fatalError("Error!")
    }
}

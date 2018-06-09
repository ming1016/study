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
    case minus
    case mult
    case intDiv
}

public enum OCToken {
    case constant(OCConstant)
    case operation(OCOperation)
    case eof
    case whiteSpaceAndNewLine
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
        default:
            return false
        }
    }
}

public class OCInterpreter {
    private let text: String
    private var currentIndex: Int
    private var currentCharacter: Character?
    
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
        
        if CharacterSet.whitespacesAndNewlines.contains((currentCharacter?.unicodeScalars.first!)!) {
            skipWhiteSpaceAndNewLines()
            return .whiteSpaceAndNewLine
        }
        
        if CharacterSet.decimalDigits.contains((currentCharacter?.unicodeScalars.first!)!) {
            return number()
        }
        
        if currentCharacter == "+" {
            advance()
            return .operation(.plus)
        }
        if currentCharacter == "-" {
            advance()
            return .operation(.minus)
        }
        if currentCharacter == "*" {
            advance()
            return .operation(.mult)
        }
        if currentCharacter == "/" {
            advance()
            return .operation(.intDiv)
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
        
        let op = currentTk
        eat(currentTk)
        
        guard case let .constant(.integer(right)) = currentTk else {
            return 0
        }
        eat(currentTk)
        
        if op == .operation(.plus) {
            return left + right
        } else if op == .operation(.minus) {
            return left - right
        } else if op == .operation(.mult) {
            return left * right
        } else if op == .operation(.intDiv) {
            return left / right
        }
        return left + right
    }
    
    // 数字处理
    private func number() -> OCToken {
        var numStr = ""
        while let character = currentCharacter,  CharacterSet.decimalDigits.contains((character.unicodeScalars.first!)) {
            numStr += String(character)
            advance()
        }
        
        return .constant(.integer(Int(numStr)!))
    }
    
    // 辅助函数
    private func advance() {
        currentIndex += 1
        guard currentIndex < text.count else {
            currentCharacter = nil
            return
        }
        currentCharacter = text[text.index(text.startIndex, offsetBy: currentIndex)]
    }
    
    // 往前探一个字符，不改变当前字符
    private func peek() -> Character? {
        let peekIndex = currentIndex + 1
        guard peekIndex < text.count else {
            return nil
        }
        return text[text.index(text.startIndex, offsetBy: peekIndex)]
    }
    
    private func skipWhiteSpaceAndNewLines() {
        while let character = currentCharacter, CharacterSet.whitespacesAndNewlines.contains((character.unicodeScalars.first!)) {
            advance()
        }
    }
    
    private func eat(_ token: OCToken) {
        if  currentTk == token {
            currentTk = nextTk()
            if currentTk == OCToken.whiteSpaceAndNewLine {
                currentTk = nextTk()
            }
        } else {
            error()
        }
    }
    
    func error() {
        fatalError("Error!")
    }
}

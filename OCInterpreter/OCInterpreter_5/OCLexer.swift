//
//  OCLexer.swift
//  HTN
//
//  Created by DaiMing on 2018/6/10.
//

import Foundation

public class OCLexer {
    private let text: String
    private var currentIndex: Int
    private var currentCharacter: Character?
    
    private let keywords: [String: OCToken] = [
        "return": .return
    ]
    
    public init(_ input: String) {
        if input.count == 0 {
            fatalError("Error! input can't be empty")
        }
        self.text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
    }
    
    // 流程函数
    func nextTk() -> OCToken {
        // 到文件末
        if currentIndex > self.text.count - 1 {
            return .eof
        }
        
        // 空格换行
        if CharacterSet.whitespacesAndNewlines.contains((currentCharacter?.unicodeScalars.first!)!) {
            skipWhiteSpaceAndNewLines()
            //return .whiteSpaceAndNewLine
        }
        
        // 数字
        if CharacterSet.decimalDigits.contains((currentCharacter?.unicodeScalars.first!)!) {
            return number()
        }
        
        // identifier
        if CharacterSet.alphanumerics.contains((currentCharacter?.unicodeScalars.first!)!) {
            return id()
        }
        
        // 符号
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
            // 处理可能的注释的情况
            if peek() == "/" {
                advance()
                advance()
                return commentsFromDoubleSlash()
            } else if peek() == "*" {
                advance()
                advance()
                return commentsFromSlashAsterisk()
            } else {
                advance()
                return .operation(.intDiv)
            }
            
        }
        if currentCharacter == "(" {
            advance()
            return .paren(.left)
        }
        if currentCharacter == ")" {
            advance()
            return .paren(.right)
        }
        if currentCharacter == "@" {
            return at()
        }
        if currentCharacter == ";" {
            advance()
            return .semi
        }
        if currentCharacter == "=" {
            advance()
            return .assign
        }
        if currentCharacter == "{" {
            advance()
            return .brace(.left)
        }
        if currentCharacter == "}" {
            advance()
            return .brace(.right)
        }
        if currentCharacter == "*" {
            advance()
            return .asterisk
        }
        if currentCharacter == "," {
            advance()
            return .comma
        }
        advance()
        return .eof
    }
    
    // identifier and keywords
    private func id() -> OCToken {
        var idStr = ""
        while let character = currentCharacter, CharacterSet.alphanumerics.contains(character.unicodeScalars.first!) {
            idStr += String(character)
            advance()
        }
        
        // 关键字
        if let token = keywords[idStr] {
            return token
        }
        
        return .id(idStr)
    }
    
    // @符号的处理
    private func at() -> OCToken {
        advance()
        var atStr = ""
        while let character = currentCharacter,  CharacterSet.alphanumerics.contains((character.unicodeScalars.first!)) {
            atStr += String(character)
            advance()
        }
        if atStr == "interface" {
            return .interface
        }
        if atStr == "end" {
            return .end
        }
        if atStr == "implementation" {
            return .implementation
        }
        if atStr == "property" {
            return .property
        }
        
        fatalError("Error: at string not support")
    }
    // 数字处理
    private func number() -> OCToken {
        var numStr = ""
        while let character = currentCharacter,  CharacterSet.decimalDigits.contains(character.unicodeScalars.first!) {
            numStr += String(character)
            advance()
        }
        
        if let character = currentCharacter, character == ".", peek() != "." {
            numStr += "."
            advance()
            while let character = currentCharacter, CharacterSet.decimalDigits.contains(character.unicodeScalars.first!) {
                numStr += String(character)
                advance()
            }
            return .constant(.float(Float(numStr)!))
        }
        
        return .constant(.integer(Int(numStr)!))
    }
    
    // --------- 辅助函数 --------
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
    
    // 过滤 // 这种注释
    private func commentsFromDoubleSlash() -> OCToken {
        var cStr = ""
        while let character = currentCharacter, !CharacterSet.newlines.contains(character.unicodeScalars.first!) {
            advance()
            cStr += String(character)
        }
        return .comments(cStr)
    }
    
    // 过滤 /* */ 这样的注释
    private func commentsFromSlashAsterisk() -> OCToken {
        var cStr = ""
        while let character = currentCharacter {
            if character == "*" && peek() == "/" {
                advance()
                advance()
                break
            } else {
                advance()
                cStr += String(character)
            }
            
        }
        return .comments(cStr)
    }
    
    private func skipWhiteSpaceAndNewLines() {
        while let character = currentCharacter, CharacterSet.whitespacesAndNewlines.contains(character.unicodeScalars.first!) {
            advance()
        }
    }
}

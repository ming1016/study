//
//  OCParser.swift
//  HTN
//
//  Created by DaiMing on 2018/7/4.
//

import Foundation

public class OCParser {
    private var tkIndex = 0
    private var tks: [OCToken]
    
    private var currentTk: OCToken {
        return tks[tkIndex]
    }
    private var nextTk: OCToken {
        return tks[tkIndex + 1]
    }
    
    public init(_ input: String) {
        let lexer = OCLexer(input)
        var tk = lexer.nextTk()
        var all = [tk]
        while tk != .eof {
            tk = lexer.nextTk()
            all.append(tk)
        }
        tks = all
    }
    
    public func debug() {
        //        while currentTk != .eof {
        //            print(currentTk)
        //            eat(currentTk)
        //        }
        //        eat(.whiteSpaceAndNewLine)
        let pgm = program()
        print(pgm)
        
    }
    
    public func parse() -> OCAST {
        let node = program()
        if currentTk != .eof {
            fatalError("Error: no reached end")
        }
        return node
    }
    
    private func program() -> OCProgram {
        return OCProgram(interface: interface(), implementation: implementation())
    }
    
    private func interface() -> OCInterface {
        eat(.interface)
        guard case let .id(name) = currentTk else {
            fatalError("Error interface")
        }
        eat(.id(name))
        eat(.end)
        return OCInterface(name: name)
    }
    
    private func implementation() -> OCImplementation {
        eat(.implementation)
        guard case let .id(name) = currentTk else {
            fatalError("Error implementation")
        }
        eat(.id(name))
        let methodListNode = methodList()
        eat(.end)
        return OCImplementation(name: name, methodList: methodListNode)
    }
    
    private func methodList() -> [OCMethod] {
        var methods = [OCMethod]()
        while currentTk == .operation(.plus) || currentTk == .operation(.minus) {
            eat(currentTk)
            methods.append(method())
        }
        return methods
    }
    
    private func method() -> OCMethod {
        eat(.paren(.left))
        guard case let .id(reStr) = currentTk else {
            fatalError("Error reStr")
        }
        eat(.id(reStr))
        eat(.paren(.right))
        guard case let .id(methodName) = currentTk else {
            fatalError("Error methodName")
        }
        eat(.id(methodName))
        eat(.brace(.left))
        let statementsNode = statements()
        eat(.brace(.right))
        return OCMethod(returnIdentifier: reStr, methodName: methodName, statements: statementsNode)
    }
    
    private func statements() -> [OCAST] {
        let sNode = statement()
        var statements = [sNode]
        while currentTk == .semi {
            eat(.semi)
            statements.append(statement())
        }
        return statements
    }
    
    private func statement() -> OCAST {
        switch currentTk {
        case .id:
            return assignStatement()
        default:
            return empty()
        }
    }
    
    private func assignStatement() -> OCAssign {
        let left = variable()
        eat(.assign)
        let right = expr()
        return OCAssign(left: left, right: right)
    }
    
    private func variable() -> OCVar {
        guard case let .id(name) = currentTk else {
            fatalError("Error: var was wrong")
        }
        eat(.id(name))
        
        return OCVar(name: name)
    }
    
    private func empty() -> OCNoOp {
        return OCNoOp()
    }
    
    /*--------- 运算符 --------*/
    
    public func expr() -> OCAST {
        var node = term()
        
        while [.operation(.plus), .operation(.minus)].contains(currentTk) {
            let tk = currentTk
            eat(currentTk)
            if tk == .operation(.plus) {
                node = OCBinOp(left: node, operation: .plus, right: term())
            } else if tk == .operation(.minus) {
                node = OCBinOp(left: node, operation: .minus, right: term())
            }
        }
        return node
    }
    
    
    // 语法解析中对数字的处理
    private func term() -> OCAST {
        var node = factor()
        
        while [.operation(.mult), .operation(.intDiv)].contains(currentTk) {
            let tk = currentTk
            eat(currentTk)
            if tk == .operation(.mult) {
                node = OCBinOp(left: node, operation: .mult, right: factor())
            } else if tk == .operation(.intDiv) {
                node = OCBinOp(left: node, operation: .intDiv, right: factor())
            }
        }
        return node
    }
    
    private func factor() -> OCAST {
        let tk = currentTk
        switch tk {
        case .operation(.plus):
            eat(.operation(.plus))
            return OCUnaryOperation(operation: .plus, operand: factor())
        case .operation(.minus):
            eat(.operation(.minus))
            return OCUnaryOperation(operation: .minus, operand: factor())
        case let .constant(.integer(result)):
            eat(.constant(.integer(result)))
            return OCNumber.integer(result)
        case .paren(.left):
            eat(.paren(.left))
            let result = expr()
            eat(.paren(.right))
            return result
        default:
            return variable()
        }
    }
    
    private func eat(_ token: OCToken) {
        if  currentTk == token {
            tkIndex += 1
        } else {
            fatalError("Error: eat wrong")
        }
    }
    
    
    
}

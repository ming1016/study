//
//  JParser.swift
//  HTN
//
//  Created by DaiMing on 2018/4/28.
//

import Foundation
// Base
public enum JNodeType:String {
    case None
    case Root
    case Identifier
    case NumberLiteral
    case CallExpression
    case ExpressionStatement
}
public protocol JNodeBase {
    var type: JNodeType {get}
}
// NumberLiteral
public enum JNumberType:String {
    case int,float
}
public protocol JNodeNumberLiteral {
    var numberType: JNumberType {get}
    var intValue: Int {get}
    var floatValue: Float {get}
}
// CallExpression 测试用，未定结构
public protocol JNodeCallExpression {
    //TODO: 将 add subtract 做成枚举类型加到这里
    var name: String {get}
    var params: [JNode] {get}
    
    // other ast 用
//    var callee: JNodeCallee {get}
//    var arguments: [JNode] {get}
}

// ExpressionStatement
public protocol JNodeExpressionStatement {
    var expressions: [JNode] {get}
}
// Struct
public class JNode:JNodeBase,
    JNodeNumberLiteral,
    JNodeCallExpression,
    JNodeExpressionStatement {
    public var type = JNodeType.None
    // CallExpression
    public var name = ""
    public var params = [JNode]()
    
    // NumberLiteral
    public var numberType = JNumberType.int
    public var intValue:Int = 0
    public var floatValue:Float = 0
    // ExpressionStatement
    public var expressions = [JNode]()
    // Expression
    public var callee = JNodeCallee()
    public var arguments = [JNode]()
}
// Callee
public class JNodeCallee:JNodeBase {
    public var type = JNodeType.None
    public var name = ""
}

// 解析类
public class JParser {
    private var _tokens: [JToken]
    private var _current: Int
    
    public init(_ input:String) {
        _tokens = JTokenizer(input).tokenizer()
        _current = 0
    }
    public func parser() -> [JNode] {
        _current = 0
        var nodeTree = [JNode]()
        while _current < _tokens.count {
            nodeTree.append(walk())
        }
        _current = 0 //用完重置
        //打印
        print("Before transform AST:")
        JParser.astPrintable(nodeTree)
        return nodeTree
    }
    
    private func walk() -> JNode {
        var tk = _tokens[_current]
        let jNode = JNode()
        //检查是不是数字类型节点
        if tk.type == "int" || tk.type == "float" {
            _current += 1
            jNode.type = .NumberLiteral
            if tk.type == "int", let intV = Int(tk.value) {
                jNode.intValue = intV
                jNode.numberType = .int
            }
            if tk.type == "float", let floatV = Float(tk.value) {
                jNode.floatValue = floatV
                jNode.numberType = .float
            }
            return jNode
            
        }
        //检查是否是 CallExpressions 类型
        if tk.type == "paren" && tk.value == "(" {
            //跳过符号
            _current += 1
            tk = _tokens[_current]
            
            jNode.type = .CallExpression
            jNode.name = tk.value
            _current += 1
            while tk.type != "paren" || (tk.type == "paren" && tk.value != ")") {
                //递归
                jNode.params.append(walk())
                tk = _tokens[_current]
            }
            //跳到下一个
            _current += 1
            return jNode
        }
        _current += 1
        return jNode
    }
    
}
//专门打印用
extension JParser {
    // --------- 打印 AST，方便调试 ---------
    static func astPrintable(_ tree:[JNode]) {
        for aNode in tree {
            recDesNode(aNode, level: 0)
        }
    }
    static func recDesNode(_ node:JNode, level:Int) {
        let nodeTypeStr = node.type
        var preSpace = ""
        for _ in 0...level {
            if level > 0 {
                preSpace += "   "
            }
        }
        var dataStr = ""
        switch node.type {
        case .Root:
            dataStr = "Root"
        case .Identifier:
            dataStr = "name is \(node.name)"
        case .NumberLiteral:
            var numberStr = ""
            if node.numberType == .float {
                numberStr = "\(node.floatValue)"
            }
            if node.numberType == .int {
                numberStr = "\(node.intValue)"
            }
            dataStr = "number type is \(node.numberType) number is \(numberStr)"
        case .CallExpression:
            
            if node.callee.name.count > 0 {
                dataStr = "expression is \(node.type)(\(node.callee.name))"
            } else {
                dataStr = "expression is \(node.type)(\(node.name))"
            }
        case .ExpressionStatement:
            dataStr = ""
        case .None:
            dataStr = ""
        }
        print("\(preSpace) \(nodeTypeStr) \(dataStr)")
        
        if node.type == .CallExpression {
            if node.params.count > 0 {
                for aNode in node.params {
                    recDesNode(aNode, level: level + 1)
                }
            } else if node.arguments.count > 0 {
                for aNode in node.arguments {
                    recDesNode(aNode, level: level + 1)
                }
            }
        }
        if node.type == .ExpressionStatement {
            if node.expressions.count > 0 {
                for aNode in node.expressions {
                    recDesNode(aNode, level: level + 1)
                }
            }
            
        }
    }
}

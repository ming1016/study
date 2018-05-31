//
//  JTransformer.swift
//  HTN
//
//  Created by DaiMing on 2018/5/2.
// 

import Foundation

public class JTransformer {
    public var ast:[JNode]
    
    public init(_ input:String) {
        ast = [JNode]()
        var currentParent = JNode() //当前的父节点
        let numberLiteralClosure:VisitorClosure = { (node,parent) in
            if currentParent.type == .ExpressionStatement {
                currentParent.expressions[0].arguments.append(node)
            }
            if currentParent.type == .CallExpression {
                currentParent.arguments.append(node)
            }
        }
        let callExpressionClosure:VisitorClosure = { (node,parent) in
            let exp = JNode()
            exp.type = .CallExpression
            
            let callee = JNodeCallee()
            callee.type = .Identifier
            callee.name = node.name
            exp.callee = callee
            
            if parent.type != .CallExpression {
                let exps = JNode()
                exps.type = .ExpressionStatement
                exps.expressions.append(exp)
                if parent.type == .Root {
                    self.ast.append(exps)
                }
                currentParent = exps
            } else {
                currentParent.expressions[0].arguments.append(exp)
                currentParent = exp
            }
        }
        let vDic = ["NumberLiteral": numberLiteralClosure, "CallExpression" : callExpressionClosure]
        
        JTraverser(input).traverser(visitor: vDic)
        print("After transform AST:")
        JParser.astPrintable(ast)
    }
}

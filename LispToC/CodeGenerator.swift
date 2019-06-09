//
//  CodeGeneratorFromJSToOC.swift
//  HTN
//
//  Created by DaiMing on 2018/5/2.
//

import Foundation

public class CodeGenerator {
    public var code = ""
    public init(_ input:String) {
        print("Input code is:")
        print(input)
        let ast = JTransformer(input).ast
        for aNode in ast {
            code.append(recGeneratorCode(aNode))
        }
        print("The code generated:")
        print(code)
    }
    
    public func recGeneratorCode(_ node:JNode) -> String {
        var code = ""
        if node.type == .ExpressionStatement {
            for aExp in node.expressions {
                code.append(recGeneratorCode(aExp))
            }
        }
        if node.type == .CallExpression {
            code.append(node.callee.name)
            code.append("(")
            if node.arguments.count > 0 {
                for (index,arg) in node.arguments.enumerated() {
                    code.append(recGeneratorCode(arg))
                    if index != node.arguments.count - 1 {
                        code.append(", ")
                    }
                }
            }
            code.append(")")
        }
        if node.type == .Identifier {
            code.append(node.name)
        }
        if node.type == .NumberLiteral {
            switch node.numberType {
            case .float:
                code.append(String(node.floatValue))
            case .int:
                code.append(String(node.intValue))
            }
        }
        
        return code
    }
}

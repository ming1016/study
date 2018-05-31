//
//  JTraverser.swift
//  HTN
//
//  Created by DaiMing on 2018/5/2.
//

import Foundation

public typealias VisitorClosure = (_ node:JNode,_ parent:JNode) -> Void

public class JTraverser {
    
    private var _ast: [JNode]
    public init(_ input:String) {
        _ast = JParser(input).parser()
    }
    public func traverser(visitor:[String:VisitorClosure]) {
        
        func traverseChildNode(childrens:[JNode], parent:JNode) {
            for child in childrens {
                traverseNode(node: child, parent: parent)
            }
        }
        
        func traverseNode(node:JNode, parent:JNode) {
            //会执行外部传入的 Closure
            if visitor.keys.contains(node.type.rawValue) {
                if let closure:VisitorClosure = visitor[node.type.rawValue] {
                    closure(node,parent)
                }
            }
            //看是否有子节点需要继续遍历
            if node.params.count > 0 {
                traverseChildNode(childrens: node.params, parent: node)
            }
        }
        let rootNode = JNode()
        rootNode.type = .Root
        traverseChildNode(childrens: _ast, parent: rootNode)
    }
}

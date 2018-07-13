//
//  OCStaticAnalyzer.swift
//  HTN
//
//  Created by DaiMing on 2018/7/4.
//

import Foundation

public class OCStaticAnalyzer: OCVisitor {
    private var currentScope: OCSymbolTable?
    private var scopes: [String: OCSymbolTable] = [:]
//    private var symbolTable = OCSymbolTable(name: "global")
    
    public init() {
        
    }
    
    public func analyze(node: OCAST) -> [String: OCSymbolTable] {
        visit(node: node)
        return scopes
    }
    
    func visit(program: OCProgram) {
        let globalScope = OCSymbolTable(name: "global", level: 1, enclosingScope: nil)
        scopes[globalScope.name] = globalScope
        currentScope = globalScope
        visit(interface: program.interface)
        visit(implementation: program.implementation)
        currentScope = nil
    }
    
    func visit(variableDeclaration: OCVariableDeclaration) {
        guard let scope = currentScope else {
            fatalError("Error: out of a scope")
        }
        
        guard scope.lookup(variableDeclaration.variable.name, currentScopeOnly: true) == nil else {
            fatalError("Error: Doplicate identifier")
        }
        
        guard let symbolType = scope.lookup(variableDeclaration.type) else {
            fatalError("Error: type not found")
        }
        
        scope.define(OCVariableSymbol(name: variableDeclaration.variable.name, type: symbolType))
        visit(node: variableDeclaration.variable)
        visit(node: variableDeclaration.right)
    }
    
    func visit(method: OCMethod) {
        let scope = OCSymbolTable(name: method.methodName, level: (currentScope?.level ?? 0) + 1, enclosingScope: currentScope)
        scopes[scope.name] = scope
        currentScope = scope
        
        for statement in method.statements {
            visit(node: statement)
        }
        
        currentScope = currentScope?.enclosingScope
    }
    
    func visit(propertyDeclaration: OCPropertyDeclaration) {
        guard let scope = currentScope else {
            fatalError("Error: out of a scope")
        }
        guard scope.lookup(propertyDeclaration.name) == nil else {
            fatalError("Error: duplicate identifier \(propertyDeclaration.name) found")
        }
        
        guard let symbolType = scope.lookup(propertyDeclaration.type) else {
            fatalError("Error: \(propertyDeclaration.type) type not found")
        }
        
        scope.define(OCVariableSymbol(name: propertyDeclaration.name, type: symbolType))
    }
    
    func visit(variable: OCVar) {
        guard let scope = currentScope else {
            fatalError("Error: cannot access")
        }
        guard scope.lookup(variable.name) != nil else {
            fatalError("Error: \(variable.name) variable not found")
        }
    }
    
}

//
//  OCSymbolTable.swift
//  HTN
//
//  Created by DaiMing on 2018/7/10.
//

import Foundation

public class OCSymbolTable {
    var symbols: [String: OCSymbol] = [:]
    
    let name: String
    let level: Int
    let enclosingScope: OCSymbolTable?
    
    init(name: String, level: Int, enclosingScope: OCSymbolTable?) {
        self.name = name
        self.level = level
        self.enclosingScope = enclosingScope
        
        defineBuiltInTypes()
    }
    
    private func defineBuiltInTypes() {
        define(OCBuiltInTypeSymbol.integer)
        define(OCBuiltInTypeSymbol.float)
        define(OCBuiltInTypeSymbol.boolean)
        define(OCBuiltInTypeSymbol.string)
    }
    
    func define(_ symbol: OCSymbol) {
        symbols[symbol.name] = symbol
    }
    
    func lookup(_ name: String, currentScopeOnly: Bool = false) -> OCSymbol? {
        if let symbol = symbols[name] {
            return symbol
        }
        if currentScopeOnly {
            return nil
        }
        return enclosingScope?.lookup(name)
    }
}

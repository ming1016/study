//
//  JTokenizer.swift
//  HTN
//
//  Created by DaiMing on 2018/4/27.
//

import Foundation

public struct JToken {
    var type = ""
    var value = ""
}

public class JTokenizer {
    private var _input: String
    private var _index: String.Index
    
    public init(_ input: String) {
        _input = input.filterAnnotationBlock()
        _index = _input.startIndex
    }
    
    public func tokenizer() -> [JToken] {
        var tokens = [JToken]()
        while let aChar = currentChar {
            let s = aChar.description
            let combinedSymbols = ["+","="]
            let symbols = ["(",")"," "]
            if symbols.contains(s) || combinedSymbols.contains(s) {
                if s == " " {
                    //空格
                    advanceIndex()
                    continue
                }
                //组合关键字符号
                if combinedSymbols.contains(s) {
                    var cSb = ""
                    while let cChar = currentChar {
                        let sb = cChar.description
                        if !combinedSymbols.contains(sb) {
                            break
                        }
                        cSb.append(sb)
                        advanceIndex()
                        continue
                    }
                    tokens.append(JToken(type: "paren", value: cSb))
                    continue
                }
                //特殊符号
                tokens.append(JToken(type: "paren", value: s))
                advanceIndex()
                continue
            } else {
                var word = ""
                while let sChar = currentChar {
                    let str = sChar.description
                    if symbols.contains(str) {
                        break
                    }
                    word.append(str)
                    advanceIndex()
                    continue
                }
                //开始把连续字符进行 token 存储
                if word.count > 0 {
                    var tkType = "char"
                    if word.isFloat() {
                        tkType = "float"
                    }
                    if word.isInt() {
                        tkType = "int"
                    }
                    
                    tokens.append(JToken(type: tkType, value: word))
                }
                continue
            } // end if else
        } // end while
        
        return tokens
    }
    
    //parser tool
    var currentChar: Character? {
        return _index < _input.endIndex ? _input[_index] : nil
    }
    func advanceIndex() {
        _input.formIndex(after: &_index)
    }
}

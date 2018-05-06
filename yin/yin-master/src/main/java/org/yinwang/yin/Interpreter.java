package org.yinwang.yin;


import org.yinwang.yin.ast.Node;
import org.yinwang.yin.parser.Parser;
import org.yinwang.yin.value.Value;

public class Interpreter {

    String file;


    public Interpreter(String file) {
        this.file = file;
    }


    public Value interp(String file) {
        Node program = Parser.parse(file);
        return program.interp(Scope.buildInitScope());
    }


    public static void main(String[] args) {
        Interpreter i = new Interpreter(args[0]);
        _.msg(i.interp(args[0]).toString());
    }

}

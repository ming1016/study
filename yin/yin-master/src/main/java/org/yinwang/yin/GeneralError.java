package org.yinwang.yin;


import org.yinwang.yin.ast.Node;

public class GeneralError extends Exception {
    public String msg;
    public Node location;


    public GeneralError(Node location, String msg) {
        this.msg = msg;
        this.location = location;
    }


    public GeneralError(String msg) {
        this.msg = msg;
    }


    public String toString() {
        if (location != null) {
            return location.getFileLineCol() + ": " + msg;
        } else {
            return msg;
        }
    }

}

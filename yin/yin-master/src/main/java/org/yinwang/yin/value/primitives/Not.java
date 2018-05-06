package org.yinwang.yin.value.primitives;


import org.yinwang.yin._;
import org.yinwang.yin.ast.Node;
import org.yinwang.yin.value.*;

import java.util.List;

public class Not extends PrimFun {

    public Not() {
        super("not", 1);
    }


    @Override
    public Value apply(List<Value> args, Node location) {

        Value v1 = args.get(0);
        if (v1 instanceof BoolValue) {
            return new BoolValue(!((BoolValue) v1).value);
        }
        _.abort(location, "incorrect argument type for not: " + v1);
        return null;
    }


    public Value typecheck(List<Value> args, Node location) {
        Value v1 = args.get(0);
        if (v1 instanceof BoolType) {
            return Type.BOOL;
        }
        _.abort(location, "incorrect argument type for not: " + v1);
        return null;
    }
}

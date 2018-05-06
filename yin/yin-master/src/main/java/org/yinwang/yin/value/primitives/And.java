package org.yinwang.yin.value.primitives;


import org.yinwang.yin._;
import org.yinwang.yin.ast.Node;
import org.yinwang.yin.value.*;

import java.util.List;

public class And extends PrimFun {

    public And() {
        super("and", 2);
    }


    @Override
    public Value apply(List<Value> args, Node location) {

        Value v1 = args.get(0);
        Value v2 = args.get(1);
        if (v1 instanceof BoolValue && v2 instanceof BoolValue) {
            return new BoolValue(((BoolValue) v1).value && ((BoolValue) v2).value);
        }

        _.abort(location, "incorrect argument types for and: " + v1 + ", " + v2);
        return null;
    }


    public Value typecheck(List<Value> args, Node location) {
        Value v1 = args.get(0);
        Value v2 = args.get(1);

        if (v1 instanceof BoolType && v2 instanceof BoolType) {
            return Type.BOOL;
        }
        _.abort(location, "incorrect argument types for and: " + v1 + ", " + v2);
        return null;
    }
}

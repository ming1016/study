package org.yinwang.yin.value.primitives;


import org.yinwang.yin.ast.Node;
import org.yinwang.yin.value.PrimFun;
import org.yinwang.yin.value.UnionType;
import org.yinwang.yin.value.Value;

import java.util.List;

public class U extends PrimFun {

    public U() {
        super("U", -1);
    }


    @Override
    public Value apply(List<Value> args, Node location) {
        return null;
    }


    public Value typecheck(List<Value> args, Node location) {
        return UnionType.union(args);
    }

}

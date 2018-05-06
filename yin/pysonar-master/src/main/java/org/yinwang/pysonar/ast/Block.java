package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;

import java.util.List;
import java.util.Set;


public class Block extends Node {

    @NotNull
    public List<Node> seq;


    public Block(@NotNull List<Node> seq, String file, int start, int end) {
        super(file, start, end);
        this.seq = seq;
        addChildren(seq);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State state) {
        // first pass: mark global names
        for (Node n : seq) {
            if (n instanceof Global) {
                for (Name name : ((Global) n).names) {
                    state.addGlobalName(name.id);
                    Set<Binding> nb = state.lookup(name.id);
                    if (nb != null) {
                        Analyzer.self.putRef(name, nb);
                    }
                }
            }
        }

        boolean returned = false;
        Type retType = Type.UNKNOWN;

        for (Node n : seq) {
            Type t = transformExpr(n, state);
            if (!returned) {
                retType = UnionType.union(retType, t);
                if (!UnionType.contains(t, Type.CONT)) {
                    returned = true;
                    retType = UnionType.remove(retType, Type.CONT);
                }
            }
        }

        return retType;
    }


    @NotNull
    @Override
    public String toString() {
        return "(block:" + seq + ")";
    }

}

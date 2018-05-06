package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;
import org.python.indexer.types.UnionType;

import java.util.ArrayList;
import java.util.List;

public class Block extends Node {

    static final long serialVersionUID = -9096405259154069107L;

    public List<Node> seq;

    public Block(List<Node> seq) {
        this(seq, 0, 1);
    }

    public Block(List<Node> seq, int start, int end) {
        super(start, end);
        if (seq == null) {
            seq = new ArrayList<Node>();
        }
        this.seq = seq;
        addChildren(seq);
    }

    /**
     * First mark all the global names then resolve each statement in the sequence. 
     * Notice that we don't distinguish class and function definitions here. 
     * Their statements will return None type and bind the names themselves in the scope.
     * If the sequence contains escaping control-flow, None type will appear in the return type.
     * This can be used to generate warnings such as "This function may not return a value."
     */
    @Override
    public Type resolve(Scope scope, int tag) throws Exception {
        // find global names and mark them
        for (Node n : seq) {
            if (n.isGlobal()) {
                for (Name name : n.asGlobal().getNames()) {
                    scope.addGlobalName(name.getId());
                    Binding nb = scope.lookup(name.getId());
                    if (nb != null) {
                        Indexer.idx.putLocation(name, nb);
                    }
                }
            }
        }

        boolean returned = false;
        Type retType = Indexer.idx.builtins.unknown;

        for (Node n : seq) {
            Type t = resolveExpr(n, scope, tag);
            if (!returned) {
                retType = UnionType.union(retType, t);
                if (!UnionType.contains(t, Indexer.idx.builtins.Cont)) {
                    returned = true;
                    retType = UnionType.remove(retType, Indexer.idx.builtins.Cont);
                }
            } else if (scope.getScopeType() != Scope.ScopeType.GLOBAL &&
                       scope.getScopeType() != Scope.ScopeType.MODULE) {
                Indexer.idx.putProblem(n, "unreachable code");
            }
        }

        return retType;
    }
    
    public boolean isEmpty() {
        return seq.isEmpty();
    }

    @Override
    public String toString() {
        return "<Block:" + seq + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(seq, v);
        }
    }
}

package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

public class For extends Node {

    static final long serialVersionUID = 3228529969554646406L;

    public Node target;
    public Node iter;
    public Block body;
    public Block orelse;

    public For(Node target, Node iter, Block body, Block orelse) {
        this(target, iter, body, orelse, 0, 1);
    }

    public For(Node target, Node iter, Block body, Block orelse,
               int start, int end) {
        super(start, end);
        this.target = target;
        this.iter = iter;
        this.body = body;
        this.orelse = orelse;
        addChildren(target, iter, body, orelse);
    }

    @Override
    public boolean bindsName() {
        return true;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        NameBinder.bindIter(s, target, iter, Binding.Kind.SCOPE, tag);

        if (body == null) {
            setType(Indexer.idx.builtins.unknown);
        } else {
            setType(resolveExpr(body, s, tag));
        }
        if (orelse != null) {
            addType(resolveExpr(orelse, s, tag));
        }
        return getType();
    }

    @Override
    public String toString() {
        return "<For:" + target + ":" + iter + ":" + body + ":" + orelse + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(target, v);
            visitNode(iter, v);
            visitNode(body, v);
            visitNode(orelse, v);
        }
    }
}

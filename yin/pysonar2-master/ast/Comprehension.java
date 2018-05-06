package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

import java.util.List;

public class Comprehension extends Node {

    static final long serialVersionUID = -598250664243757218L;

    public Node target;
    public Node iter;
    public List<Node> ifs;

    public Comprehension(Node target, Node iter, List<Node> ifs) {
        this(target, iter, ifs, 0, 1);
    }

    public Comprehension(Node target, Node iter, List<Node> ifs, int start, int end) {
        super(start, end);
        this.target = target;
        this.iter = iter;
        this.ifs = ifs;
        addChildren(target, iter);
        addChildren(ifs);
    }

    @Override
    public boolean bindsName() {
        return true;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        NameBinder.bindIter(s, target, iter, Binding.Kind.SCOPE, tag);
        resolveList(ifs, s, tag);
        return resolveExpr(target, s, tag);
    }

    @Override
    public String toString() {
        return "<Comprehension:" + start() + ":" + target + ":" + iter + ":" + ifs + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(target, v);
            visitNode(iter, v);
            visitNodeList(ifs, v);
        }
    }
}

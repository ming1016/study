package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.ListType;
import org.python.indexer.types.Type;

import java.util.List;

public class DictComp extends Node {

    static final long serialVersionUID = -150205687457446323L;

    public Node elt;
    public List<Comprehension> generators;

    public DictComp(Node elt, List<Comprehension> generators) {
        this(elt, generators, 0, 1);
    }

    public DictComp(Node elt, List<Comprehension> generators, int start, int end) {
        super(start, end);
        this.elt = elt;
        this.generators = generators;
        addChildren(elt);
        addChildren(generators);
    }

    /**
     * Python's list comprehension will bind the variables used in generators.
     * This will erase the original values of the variables even after the
     * comprehension.
     */
    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        resolveList(generators, s, tag);
        return new ListType(resolveExpr(elt, s, tag));
    }

    @Override
    public String toString() {
        return "<NDictComp:" + start() + ":" + elt + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(elt, v);
            visitNodeList(generators, v);
        }
    }
}

package org.python.indexer.ast;

import org.python.indexer.Scope;
import org.python.indexer.types.ListType;
import org.python.indexer.types.Type;

import java.util.List;

public class GeneratorExp extends Node {

    static final long serialVersionUID = -8614142736962193509L;

    public Node elt;
    public List<Comprehension> generators;

    public GeneratorExp(Node elt, List<Comprehension> generators) {
        this(elt, generators, 0, 1);
    }

    public GeneratorExp(Node elt, List<Comprehension> generators, int start, int end) {
        super(start, end);
        this.elt = elt;
        this.generators = generators;
        addChildren(elt);
        addChildren(generators);
    }

    /**
     * Python's list comprehension will erase any variable used in generators.
     * This is wrong, but we "respect" this bug here.
     */
    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        resolveList(generators, s, tag);
        return setType(new ListType(resolveExpr(elt, s, tag)));
    }

    @Override
    public String toString() {
        return "<GeneratorExp:" + start() + ":" + elt + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(elt, v);
            visitNodeList(generators, v);
        }
    }
}

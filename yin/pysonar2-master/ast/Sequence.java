package org.python.indexer.ast;

import java.util.ArrayList;
import java.util.List;

public abstract class Sequence extends Node {

    static final long serialVersionUID = 7996591535766850065L;

    public List<Node> elts;

    public Sequence(List<Node> elts) {
        this(elts, 0, 1);
    }

    public Sequence(List<Node> elts, int start, int end) {
        super(start, end);
        this.elts = (elts != null) ? elts : new ArrayList<Node>();
        addChildren(elts);
    }

    public List<Node> getElements() {
        return elts;
    }
}

package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

/**
 * Non-AST node used to represent virtual source locations for builtins
 * as external urls.
 */
public class Url extends Node {

    static final long serialVersionUID = -3488021036061979551L;

    private String url;

    private static int count = 0;

    public Url(String url) {
        this.url = url == null ? "" : url;
        setStart(count);
        setEnd(count++);
    }

    public Url(String url, int start, int end) {
        super(start, end);
        this.url = url == null ? "" : url;
    }

    public String getURL() {
        return url;
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        return setType(Indexer.idx.builtins.BaseStr);
    }

    @Override
    public String toString() {
        return "<Url:\"" + url + "\">";
    }

    @Override
    public void visit(NodeVisitor v) {
        v.visit(this);
    }
}

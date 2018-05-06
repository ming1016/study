package org.python.indexer.ast;

import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.Type;

import java.util.List;

/**
 * Represents the "and"/"or" operators.
 */
public class BoolOp extends Node {

    static final long serialVersionUID = -5261954056600388069L;

    public enum OpType { AND, OR, UNDEFINED }

    OpType op;
    public List<Node> values;

    public BoolOp(OpType op, List<Node> values) {
        this(op, values, 0, 1);
    }

    public BoolOp(OpType op, List<Node> values, int start, int end) {
        super(start, end);
        this.op = op;
        this.values = values;
        addChildren(values);
    }

    @Override
    public Type resolve(Scope s, int tag) throws Exception {
        if (op == OpType.AND) {
            Type last = null;
            for (Node e : values) {
                last = resolveExpr(e, s, tag);
            }
            return (last == null ? Indexer.idx.builtins.unknown : last);
        }

        // OR
        return resolveListAsUnion(values, s, tag);
    }

    @Override
    public String toString() {
        return "<BoolOp:" + op + ":" + values + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(values, v);
        }
    }
}

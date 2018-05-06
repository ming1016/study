package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.FunType;
import org.python.indexer.types.Type;

import java.util.List;

public class Lambda extends FunctionDef {

    static final long serialVersionUID = 7737836525970653522L;

    public Lambda(List<Node> args, Node body, List<Node> defaults,
                  Name varargs, Name kwargs) {
        this(args, body, defaults, varargs, kwargs, 0, 1);
    }

    public Lambda(List<Node> args, Node body, List<Node> defaults,
                  Name varargs, Name kwargs, int start, int end) {
        super(null, args, null, defaults, varargs, kwargs, start, end);
        this.body = body instanceof Block ? (Block)body : body;
        addChildren(this.body);
    }

    @Override
    public boolean isLambda() {
        return true;
    }
    
    @Override
    public Name getName() {
        if (name != null) {
            return name;
        } else {
            String fn = Indexer.idx.genLambdaName();
            name = new Name(fn, start(), start() + "lambda".length());
            addChildren(name);
            return name;
        }
    }

    @Override
    public Type resolve(Scope outer, int tag) throws Exception {
        this.defaultTypes = resolveAndConstructList(defaults, outer, tag);
        FunType cl = new FunType(this, outer.getForwarding());
        cl.getTable().setParent(outer);
        cl.getTable().setPath(outer.extendPath(getName().getId()));
        NameBinder.bind(outer, getName(), cl, Binding.Kind.FUNCTION, tag);
        cl.setDefaultTypes(resolveAndConstructList(defaults, outer, tag));
        Indexer.idx.addUncalled(cl);
        return cl;
    }

    @Override
    public String toString() {
        return "<Lambda:" + start() + ":" + args + ":" + body + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNodeList(args, v);
            visitNodeList(defaults, v);
            visitNode(varargs, v);
            visitNode(kwargs, v);
            visitNode(body, v);
        }
    }
}

package org.python.indexer.ast;

import org.python.indexer.Binding;
import org.python.indexer.Indexer;
import org.python.indexer.Scope;
import org.python.indexer.types.FunType;
import org.python.indexer.types.Type;

import java.util.ArrayList;
import java.util.List;

public class FunctionDef extends Node {

    static final long serialVersionUID = 5495886181960463846L;

    public Name name;
    public List<Node> args;
    public List<Node> defaults;
    public List<Type> defaultTypes;
    public Name varargs;  // *args

    public Name kwargs;   // **kwargs
    public Node body;
    private List<Node> decoratorList;

    public FunctionDef(Name name, List<Node> args, Block body, List<Node> defaults,
                       Name varargs, Name kwargs) {
        this(name, args, body, defaults, kwargs, varargs, 0, 1);
    }

    public FunctionDef(Name name, List<Node> args, Block body, List<Node> defaults,
                       Name varargs, Name kwargs, int start, int end) {
        super(start, end);
        this.name = name;
        this.args = args;
        this.body = body != null ? body : new Block(null);
        this.defaults = defaults;
        this.varargs = varargs;
        this.kwargs = kwargs;
        addChildren(name);
        addChildren(args);
        addChildren(defaults);
        addChildren(varargs, kwargs, this.body);
    }

    public void setDecoratorList(List<Node> decoratorList) {
        this.decoratorList = decoratorList;
        addChildren(decoratorList);
    }

    public List<Node> getDecoratorList() {
        if (decoratorList == null) {
            decoratorList = new ArrayList<Node>();
        }
        return decoratorList;
    }

    @Override
    public boolean isFunctionDef() {
        return true;
    }

    @Override
    public boolean bindsName() {
        return true;
    }

    /**
     * Returns the name of the function for indexing/qname purposes.
     * Lambdas will return a generated name.
     */
    protected String getBindingName(Scope s) {
        return name.getId();
    }

    public List<Node> getArgs() {
        return args;
    }

    public List<Node> getDefaults() {
        return defaults;
    }

    public List<Type> getDefaultTypes() {
        return defaultTypes;
    }
    
    public Node getBody() {
        return body;
    }

    public Name getName() {
        return name;
    }
    
    /**
     * @return the varargs
     */
    public Name getVarargs() {
        return varargs;
    }

    /**
     * @param varargs the varargs to set
     */
    public void setVarargs(Name varargs) {
        this.varargs = varargs;
    }

    /**
     * @return the kwargs
     */
    public Name getKwargs() {
        return kwargs;
    }

    /**
     * @param kwargs the kwargs to set
     */
    public void setKwargs(Name kwargs) {
        this.kwargs = kwargs;
    }


    /**
     * A function's environment is not necessarily the enclosing scope. A
     * method's environment is the scope of the most recent scope that is not a
     * class.
     * 
     * Be sure to distinguish the environment and the symbol table. The
     * function's table is only used for the function's attributes like
     * "im_class". Its parent should be the table of the enclosing scope, and
     * its path should be derived from that scope too for locating the names
     * "lexically".
     */
    @Override
    public Type resolve(Scope outer, int tag) throws Exception {
        resolveList(decoratorList, outer, tag);   //XXX: not handling functional transformations yet
        FunType cl = new FunType(this, outer.getForwarding());
        cl.getTable().setParent(outer);
        cl.getTable().setPath(outer.extendPath(getName().getId()));
        cl.setDefaultTypes(resolveAndConstructList(defaults, outer, tag));
        Indexer.idx.addUncalled(cl);
        Binding.Kind funkind;

        if (outer.getScopeType() == Scope.ScopeType.CLASS) {
            if ("__init__".equals(name.getId())) {
                funkind = Binding.Kind.CONSTRUCTOR;
            } else {
                funkind = Binding.Kind.METHOD;
            }
        } else {
            funkind = Binding.Kind.FUNCTION;
        }

        if (outer != null) {
            Type outType = outer.getType();
            if (outType != null && outType.isClassType()) {
                cl.setCls(outType.asClassType());
            }
        }

        NameBinder.bind(outer, name, cl, funkind, tag);
        return Indexer.idx.builtins.Cont;
    }

    @Override
    public String toString() {
        return "<Function:" + start() + ":" + name + ">";
    }

    @Override
    public void visit(NodeVisitor v) {
        if (v.visit(this)) {
            visitNode(name, v);
            visitNodeList(args, v);
            visitNodeList(defaults, v);
            visitNode(kwargs, v);
            visitNode(varargs, v);
            visitNode(body, v);
        }
    }
    
    @Override
    public boolean equals(Object obj) {
        if (obj instanceof FunctionDef) {
            FunctionDef fo = (FunctionDef)obj;
            return (fo.getFile().equals(getFile()) && fo.start() == start());   
        } else {
            return false;
        }
    }

}

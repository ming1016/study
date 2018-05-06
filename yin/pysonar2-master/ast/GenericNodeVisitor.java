package org.python.indexer.ast;

/**
 * A visitor that passes every visited node to a single function.
 * Subclasses need only implement {@link #dispatch} to receive
 * every node as a generic {@link Node}.
 */
public abstract class GenericNodeVisitor extends DefaultNodeVisitor {

    /**
     * Every visited node is passed to this method.  The semantics
     * for halting traversal are the same as for {@link DefaultNodeVisitor}.
     * @return {@code true} to traverse this node's children
     */
    public boolean dispatch(Node n) {
        return traverseIntoNodes;
    }

    public boolean visit(Alias n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Assert n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Assign n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Attribute n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(AugAssign n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(BinOp n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Block n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(BoolOp n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Break n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Call n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(ClassDef n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Compare n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Comprehension n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Continue n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Delete n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Dict n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Ellipsis n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(ExceptHandler n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Exec n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(For n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(FunctionDef n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(GeneratorExp n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Global n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(If n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(IfExp n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Import n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(ImportFrom n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Index n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Keyword n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Lambda n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(NList n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(ListComp n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Module n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Name n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Num n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Pass n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Print n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Qname n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Raise n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Repr n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Return n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(ExprStmt n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Slice n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Str n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Subscript n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(TryExcept n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(TryFinally n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Tuple n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(UnaryOp n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Url n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(While n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(With n) {
        return traverseIntoNodes && dispatch(n);
    }

    public boolean visit(Yield n) {
        return traverseIntoNodes && dispatch(n);
    }
}

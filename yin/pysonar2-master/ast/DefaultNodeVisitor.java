package org.python.indexer.ast;

/**
 * A visitor that by default visits every node in the tree.
 * Subclasses can override specific node visiting methods
 * and decide whether to visit the children.
 */
public class DefaultNodeVisitor implements NodeVisitor {

    protected boolean traverseIntoNodes = true;

    /**
     * Once this is called, all {@code visit} methods will return {@code false}.
     * If the current node's children are being visited, all remaining top-level
     * children of the node will be visited (without visiting their children),
     * and then tree traversal halts. <p>
     *
     * If the traversal should be halted immediately without visiting any further
     * nodes, the visitor can throw a {@link StopIterationException}.
     */
    public void stopTraversal() {
        traverseIntoNodes = false;
    }

    public boolean visit(Alias n) {
        return traverseIntoNodes;
    }

    public boolean visit(Assert n) {
        return traverseIntoNodes;
    }

    public boolean visit(Assign n) {
        return traverseIntoNodes;
    }

    public boolean visit(Attribute n) {
        return traverseIntoNodes;
    }

    public boolean visit(AugAssign n) {
        return traverseIntoNodes;
    }

    public boolean visit(BinOp n) {
        return traverseIntoNodes;
    }

    public boolean visit(Block n) {
        return traverseIntoNodes;
    }

    public boolean visit(BoolOp n) {
        return traverseIntoNodes;
    }

    public boolean visit(Break n) {
        return traverseIntoNodes;
    }

    public boolean visit(Call n) {
        return traverseIntoNodes;
    }

    public boolean visit(ClassDef n) {
        return traverseIntoNodes;
    }

    public boolean visit(Compare n) {
        return traverseIntoNodes;
    }

    public boolean visit(Comprehension n) {
        return traverseIntoNodes;
    }

    public boolean visit(Continue n) {
        return traverseIntoNodes;
    }

    public boolean visit(Delete n) {
        return traverseIntoNodes;
    }

    public boolean visit(Dict n) {
        return traverseIntoNodes;
    }

    public boolean visit(Ellipsis n) {
        return traverseIntoNodes;
    }

    public boolean visit(ExceptHandler n) {
        return traverseIntoNodes;
    }

    public boolean visit(Exec n) {
        return traverseIntoNodes;
    }

    public boolean visit(For n) {
        return traverseIntoNodes;
    }

    public boolean visit(FunctionDef n) {
        return traverseIntoNodes;
    }

    public boolean visit(GeneratorExp n) {
        return traverseIntoNodes;
    }

    public boolean visit(Global n) {
        return traverseIntoNodes;
    }

    public boolean visit(If n) {
        return traverseIntoNodes;
    }

    public boolean visit(IfExp n) {
        return traverseIntoNodes;
    }

    public boolean visit(Import n) {
        return traverseIntoNodes;
    }

    public boolean visit(ImportFrom n) {
        return traverseIntoNodes;
    }

    public boolean visit(Index n) {
        return traverseIntoNodes;
    }

    public boolean visit(Keyword n) {
        return traverseIntoNodes;
    }

    public boolean visit(Lambda n) {
        return traverseIntoNodes;
    }

    public boolean visit(NList n) {
        return traverseIntoNodes;
    }

    public boolean visit(Set n) {
        return traverseIntoNodes;
    }

    public boolean visit(ListComp n) {
        return traverseIntoNodes;
    }

    public boolean visit(SetComp n) {
        return traverseIntoNodes;
    }

    public boolean visit(DictComp n) {
        return traverseIntoNodes;
    }

    public boolean visit(Module n) {
        return traverseIntoNodes;
    }

    public boolean visit(Name n) {
        return traverseIntoNodes;
    }

    public boolean visit(Num n) {
        return traverseIntoNodes;
    }

    public boolean visit(Pass n) {
        return traverseIntoNodes;
    }

    public boolean visit(Print n) {
        return traverseIntoNodes;
    }

    public boolean visit(Qname n) {
        return traverseIntoNodes;
    }

    public boolean visit(Raise n) {
        return traverseIntoNodes;
    }

    public boolean visit(Repr n) {
        return traverseIntoNodes;
    }

    public boolean visit(Return n) {
        return traverseIntoNodes;
    }

    public boolean visit(ExprStmt n) {
        return traverseIntoNodes;
    }

    public boolean visit(Slice n) {
        return traverseIntoNodes;
    }

    public boolean visit(Str n) {
        return traverseIntoNodes;
    }

    public boolean visit(Subscript n) {
        return traverseIntoNodes;
    }

    public boolean visit(TryExcept n) {
        return traverseIntoNodes;
    }

    public boolean visit(TryFinally n) {
        return traverseIntoNodes;
    }

    public boolean visit(Tuple n) {
        return traverseIntoNodes;
    }

    public boolean visit(UnaryOp n) {
        return traverseIntoNodes;
    }

    public boolean visit(Url n) {
        return traverseIntoNodes;
    }

    public boolean visit(While n) {
        return traverseIntoNodes;
    }

    public boolean visit(With n) {
        return traverseIntoNodes;
    }

    public boolean visit(Yield n) {
        return traverseIntoNodes;
    }
}

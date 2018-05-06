package org.python.indexer.ast;

/**
 * Preorder-traversal node visitor interface.
 */
public interface NodeVisitor {
    /**
     * Convenience exception for subclasses.  The caller that initiates
     * the visit should catch this exception if the subclass is expected
     * to throw it.
     */
    public static final class StopIterationException extends RuntimeException {
        public StopIterationException() {}
    }

    public boolean visit(Alias m);
    public boolean visit(Assert m);
    public boolean visit(Assign m);
    public boolean visit(Attribute m);
    public boolean visit(AugAssign m);
    public boolean visit(BinOp m);
    public boolean visit(Block m);
    public boolean visit(BoolOp m);
    public boolean visit(Break m);
    public boolean visit(Call m);
    public boolean visit(ClassDef m);
    public boolean visit(Compare m);
    public boolean visit(Comprehension m);
    public boolean visit(Continue m);
    public boolean visit(Delete m);
    public boolean visit(Dict m);
    public boolean visit(Ellipsis m);
    public boolean visit(ExceptHandler m);
    public boolean visit(Exec m);
    public boolean visit(For m);
    public boolean visit(FunctionDef m);
    public boolean visit(GeneratorExp m);
    public boolean visit(Global m);
    public boolean visit(If m);
    public boolean visit(IfExp m);
    public boolean visit(Import m);
    public boolean visit(ImportFrom m);
    public boolean visit(Index m);
    public boolean visit(Keyword m);
    public boolean visit(Lambda m);
    public boolean visit(NList m);
    public boolean visit(ListComp m);
    public boolean visit(SetComp m);
    public boolean visit(DictComp m);
    public boolean visit(Module m);
    public boolean visit(Name m);
    public boolean visit(Num m);
    public boolean visit(Pass m);
    public boolean visit(Print m);
    public boolean visit(Qname m);
    public boolean visit(Raise m);
    public boolean visit(Repr m);
    public boolean visit(Return m);
    public boolean visit(ExprStmt m);
    public boolean visit(Slice m);
    public boolean visit(Str m);
    public boolean visit(Subscript m);
    public boolean visit(TryExcept m);
    public boolean visit(TryFinally m);
    public boolean visit(Tuple m);
    public boolean visit(UnaryOp m);
    public boolean visit(Url m);
    public boolean visit(While m);
    public boolean visit(With m);
    public boolean visit(Yield m);
	public boolean visit(Set s);
}

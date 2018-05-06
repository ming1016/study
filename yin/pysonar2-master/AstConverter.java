package org.python.indexer;

import org.python.antlr.PythonTree;
import org.python.antlr.Visitor;
import org.python.antlr.ast.*;
import org.python.antlr.base.excepthandler;
import org.python.antlr.base.expr;
import org.python.antlr.base.stmt;
import org.python.indexer.ast.*;
import org.python.indexer.ast.Assert;
import org.python.indexer.ast.Assign;
import org.python.indexer.ast.Attribute;
import org.python.indexer.ast.AugAssign;
import org.python.indexer.ast.BinOp;
import org.python.indexer.ast.BoolOp;
import org.python.indexer.ast.Break;
import org.python.indexer.ast.Call;
import org.python.indexer.ast.ClassDef;
import org.python.indexer.ast.Compare;
import org.python.indexer.ast.Continue;
import org.python.indexer.ast.Delete;
import org.python.indexer.ast.Dict;
import org.python.indexer.ast.DictComp;
import org.python.indexer.ast.Ellipsis;
import org.python.indexer.ast.ExceptHandler;
import org.python.indexer.ast.Exec;
import org.python.indexer.ast.For;
import org.python.indexer.ast.FunctionDef;
import org.python.indexer.ast.GeneratorExp;
import org.python.indexer.ast.Global;
import org.python.indexer.ast.If;
import org.python.indexer.ast.IfExp;
import org.python.indexer.ast.Import;
import org.python.indexer.ast.ImportFrom;
import org.python.indexer.ast.Index;
import org.python.indexer.ast.Lambda;
import org.python.indexer.ast.ListComp;
import org.python.indexer.ast.Module;
import org.python.indexer.ast.Name;
import org.python.indexer.ast.Num;
import org.python.indexer.ast.Pass;
import org.python.indexer.ast.Print;
import org.python.indexer.ast.Raise;
import org.python.indexer.ast.Repr;
import org.python.indexer.ast.Return;
import org.python.indexer.ast.Set;
import org.python.indexer.ast.SetComp;
import org.python.indexer.ast.Slice;
import org.python.indexer.ast.Str;
import org.python.indexer.ast.Subscript;
import org.python.indexer.ast.TryExcept;
import org.python.indexer.ast.TryFinally;
import org.python.indexer.ast.Tuple;
import org.python.indexer.ast.UnaryOp;
import org.python.indexer.ast.While;
import org.python.indexer.ast.With;
import org.python.indexer.ast.Yield;

import java.util.ArrayList;
import java.util.List;

/**
 * Converts the antlr AST into the indexer's AST format.
 */

public class AstConverter extends Visitor {

    public String convOp(Object t) {
        if (t instanceof operatorType) {
            switch((operatorType)t) {
                case Add:
                    return "+";
                case Sub:
                    return "-";
                case Mult:
                    return "*";
                case Div:
                    return "/";
                case Mod:
                    return "%";
                case Pow:
                    return "**";
                case LShift:
                    return "<<";
                case RShift:
                    return ">>";
                case BitOr:
                    return "|";
                case BitXor:
                    return "^";
                case BitAnd:
                    return "&";
                case FloorDiv:
                    return "//";
                default:
                    return null;
            }
        }
        if (t instanceof boolopType) {
            switch ((boolopType)t) {
                case And:
                    return "and";
                case Or:
                    return "or";
                default:
                    return null;
            }
        }
        if (t instanceof unaryopType) {
            switch ((unaryopType)t) {
                case Invert:
                    return "~";
                case Not:
                    return "not";
                case USub:
                    return "-";
                case UAdd:
                    return "+";
                default:
                    return null;
            }
        }
        if (t instanceof cmpopType) {
            switch ((cmpopType)t) {
                case Eq:
                    return "==";
                case NotEq:
                    return "!=";
                case Gt:
                    return ">";
                case GtE:
                    return ">=";
                case Lt:
                    return "<";
                case LtE:
                    return "<=";
                case In:
                    return "in";
                case NotIn:
                    return "not in";
                case Is:
                    return "is";
                case IsNot:
                    return "is not";
                default:
                    return null;
            }
        }
        return null;
    }

     // Helpers for converting lists of things

    private List<ExceptHandler> convertListExceptHandler(List<excepthandler> in) throws Exception {
        List<ExceptHandler> out = new ArrayList<ExceptHandler>(in == null ? 0 : in.size());
        if (in != null) {
            for (excepthandler e : in) {
                ExceptHandler nxh = (ExceptHandler)e.accept(this);
                if (nxh != null) {
                    out.add(nxh);
                }
            }
        }
        return out;
    }

    private List<Node> convertListExpr(List<expr> in) throws Exception {
        List<Node> out = new ArrayList<Node>(in == null ? 0 : in.size());
        if (in != null) {
            for (expr e : in) {
                Node nx = (Node)e.accept(this);
                if (nx != null) {
                    out.add(nx);
                }
            }
        }
        return out;
    }

    private List<Name> convertListName(List<org.python.antlr.ast.Name> in) throws Exception {
        List<Name> out = new ArrayList<Name>(in == null ? 0 : in.size());
        if (in != null) {
            for (expr e : in) {
                Name nn = (Name)e.accept(this);
                if (nn != null) {
                    out.add(nn);
                }
            }
        }
        return out;
    }

    private Qname convertQname(List<org.python.antlr.ast.Name> in) throws Exception {
        if (in == null) {
            return null;
        }
        // This would be less ugly if we generated Qname nodes in the antlr ast.
        Qname out = null;
        int end = -1;
        for (int i = in.size() - 1; i >= 0; i--) {
            org.python.antlr.ast.Name n = in.get(i);
            if (end == -1) {
                end = n.getCharStopIndex();
            }
            Name nn = (Name)n.accept(this);
            out = new Qname(out, nn, n.getCharStartIndex(), end);
        }
        return out;
    }

    private List<Keyword> convertListKeyword(List<keyword> in) throws Exception {
        List<Keyword> out = new ArrayList<Keyword>(in == null ? 0 : in.size());
        if (in != null) {
            for (keyword e : in) {
                Keyword nkw = new Keyword(e.getInternalArg(), convExpr(e.getInternalValue()));
                if (nkw != null) {
                    out.add(nkw);
                }
            }
        }
        return out;
    }

    private Block convertListStmt(List<stmt> in) throws Exception {
        List<Node> out = new ArrayList<Node>(in == null ? 0 : in.size());
        if (in != null) {
            for (stmt e : in) {
                Node nx = (Node)e.accept(this);
                if (nx != null) {
                    out.add(nx);
                }
            }
        }
        return new Block(out, 0, 0);
    }

    private Node convExpr(PythonTree e) throws Exception {
        if (e == null) {
            return null;
        }
        Object o = e.accept(this);
        if (o instanceof Node) {
            return (Node)o;
        }
        return null;
    }

    private int start(PythonTree tree) {
        return tree.getCharStartIndex();
    }

    private int stop(PythonTree tree) {
        return tree.getCharStopIndex();
    }

    @Override
    public Object visitAssert(org.python.antlr.ast.Assert n) throws Exception {
        return new Assert(convExpr(n.getInternalTest()),
                           convExpr(n.getInternalMsg()),
                           start(n), stop(n));
    }

    @Override
    public Object visitAssign(org.python.antlr.ast.Assign n) throws Exception {
        return new Assign(convertListExpr(n.getInternalTargets()),
                           convExpr(n.getInternalValue()),
                           start(n), stop(n));
    }

    @Override
    public Object visitAttribute(org.python.antlr.ast.Attribute n) throws Exception {
        return new Attribute(convExpr(n.getInternalValue()),
                              (Name)convExpr(n.getInternalAttrName()),
                              start(n), stop(n));
    }

    @Override
    public Object visitAugAssign(org.python.antlr.ast.AugAssign n) throws Exception {
        return new AugAssign(convExpr(n.getInternalTarget()),
                              convExpr(n.getInternalValue()),
                              convOp(n.getInternalOp()),
                              start(n), stop(n));
    }

    @Override
    public Object visitBinOp(org.python.antlr.ast.BinOp n) throws Exception {
        return new BinOp(convExpr(n.getInternalLeft()),
                          convExpr(n.getInternalRight()),
                          convOp(n.getInternalOp()),
                          start(n), stop(n));
    }

    @Override
    public Object visitBoolOp(org.python.antlr.ast.BoolOp n) throws Exception {
        BoolOp.OpType op;
        switch (n.getInternalOp()) {
            case And:
                op = BoolOp.OpType.AND;
                break;
            case Or:
                op = BoolOp.OpType.OR;
                break;
            default:
                op = BoolOp.OpType.UNDEFINED;
                break;
        }
        return new BoolOp(op, convertListExpr(n.getInternalValues()), start(n), stop(n));
    }

    @Override
    public Object visitBreak(org.python.antlr.ast.Break n) throws Exception {
        return new Break(start(n), stop(n));
    }

    @Override
    public Object visitCall(org.python.antlr.ast.Call n) throws Exception {
        return new Call(convExpr(n.getInternalFunc()),
                         convertListExpr(n.getInternalArgs()),
                         convertListKeyword(n.getInternalKeywords()),
                         convExpr(n.getInternalKwargs()),
                         convExpr(n.getInternalStarargs()),
                         start(n), stop(n));
    }

    @Override
    public Object visitClassDef(org.python.antlr.ast.ClassDef n) throws Exception {
        return new ClassDef((Name)convExpr(n.getInternalNameNode()),
                             convertListExpr(n.getInternalBases()),
                             convertListStmt(n.getInternalBody()),
                             start(n), stop(n));
    }

    @Override
    public Object visitCompare(org.python.antlr.ast.Compare n) throws Exception {
        return new Compare(convExpr(n.getInternalLeft()),
                            null,  // XXX:  why null?
                            convertListExpr(n.getInternalComparators()),
                            start(n), stop(n));
    }

    @Override
    public Object visitContinue(org.python.antlr.ast.Continue n) throws Exception {
        return new Continue(start(n), stop(n));
    }

    @Override
    public Object visitDelete(org.python.antlr.ast.Delete n) throws Exception {
        return new Delete(convertListExpr(n.getInternalTargets()), start(n), stop(n));
    }

    @Override
    public Object visitDict(org.python.antlr.ast.Dict n) throws Exception {
        return new Dict(convertListExpr(n.getInternalKeys()),
                         convertListExpr(n.getInternalValues()),
                         start(n), stop(n));
    }

    @Override
    public Object visitEllipsis(org.python.antlr.ast.Ellipsis n) throws Exception {
        return new Ellipsis(start(n), stop(n));
    }

    @Override
    public Object visitExceptHandler(org.python.antlr.ast.ExceptHandler n) throws Exception {
        return new ExceptHandler(convExpr(n.getInternalName()),
                                  convExpr(n.getInternalType()),
                                  convertListStmt(n.getInternalBody()),
                                  start(n), stop(n));
    }

    @Override
    public Object visitExec(org.python.antlr.ast.Exec n) throws Exception {
        return new Exec(convExpr(n.getInternalBody()),
                         convExpr(n.getInternalGlobals()),
                         convExpr(n.getInternalLocals()),
                         start(n), stop(n));
    }

    @Override
    public Object visitExpr(Expr n) throws Exception {
        return new ExprStmt(convExpr(n.getInternalValue()), start(n), stop(n));
    }

    @Override
    public Object visitFor(org.python.antlr.ast.For n) throws Exception {
        return new For(convExpr(n.getInternalTarget()),
                        convExpr(n.getInternalIter()),
                        convertListStmt(n.getInternalBody()),
                        convertListStmt(n.getInternalOrelse()),
                        start(n), stop(n));
    }

    @Override
    public Object visitFunctionDef(org.python.antlr.ast.FunctionDef n) throws Exception {
        arguments args = n.getInternalArgs();
        FunctionDef fn = new FunctionDef((Name)convExpr(n.getInternalNameNode()),
                                           convertListExpr(args.getInternalArgs()),
                                           convertListStmt(n.getInternalBody()),
                                           convertListExpr(args.getInternalDefaults()),
                                           (Name)convExpr(args.getInternalVarargName()),
                                           (Name)convExpr(args.getInternalKwargName()),
                                           start(n), stop(n));
        fn.setDecoratorList(convertListExpr(n.getInternalDecorator_list()));
        return fn;
    }

    @Override
    public Object visitGeneratorExp(org.python.antlr.ast.GeneratorExp n) throws Exception {
        List<Comprehension> generators =
                new ArrayList<Comprehension>(n.getInternalGenerators().size());
        for (comprehension c : n.getInternalGenerators()) {
            generators.add(new Comprehension(convExpr(c.getInternalTarget()),
                                              convExpr(c.getInternalIter()),
                                              convertListExpr(c.getInternalIfs()),
                                              start(c), stop(c)));
        }
        return new GeneratorExp(convExpr(n.getInternalElt()), generators, start(n), stop(n));
    }

    @Override
    public Object visitGlobal(org.python.antlr.ast.Global n) throws Exception {
        return new Global(convertListName(n.getInternalNameNodes()),
                           start(n), stop(n));
    }

    @Override
    public Object visitIf(org.python.antlr.ast.If n) throws Exception {
        return new If(convExpr(n.getInternalTest()),
                       convertListStmt(n.getInternalBody()),
                       convertListStmt(n.getInternalOrelse()),
                       start(n), stop(n));
    }

    @Override
    public Object visitIfExp(org.python.antlr.ast.IfExp n) throws Exception {
        return new IfExp(convExpr(n.getInternalTest()),
                          convExpr(n.getInternalBody()),
                          convExpr(n.getInternalOrelse()),
                          start(n), stop(n));
    }

    @Override
    public Object visitImport(org.python.antlr.ast.Import n) throws Exception {
        List<Alias> aliases = new ArrayList<Alias>(n.getInternalNames().size());
        for (alias e : n.getInternalNames()) {
            aliases.add(new Alias(e.getInternalName(),
                                   convertQname(e.getInternalNameNodes()),
                                   (Name)convExpr(e.getInternalAsnameNode()),
                                   start(e), stop(e)));
        }
        return new Import(aliases, start(n), stop(n));
    }

    @Override
    public Object visitImportFrom(org.python.antlr.ast.ImportFrom n) throws Exception {
        List<Alias> aliases = new ArrayList<Alias>(n.getInternalNames().size());
        for (alias e : n.getInternalNames()) {
            aliases.add(new Alias(e.getInternalName(),
                                   convertQname(e.getInternalNameNodes()),
                                   (Name)convExpr(e.getInternalAsnameNode()),
                                   start(e), stop(e)));
        }
        return new ImportFrom(n.getInternalModule(),
                               convertQname(n.getInternalModuleNames()),
                               aliases, start(n), stop(n));
    }

    @Override
    public Object visitIndex(org.python.antlr.ast.Index n) throws Exception {
        return new Index(convExpr(n.getInternalValue()), start(n), stop(n));
    }

    @Override
    public Object visitLambda(org.python.antlr.ast.Lambda n) throws Exception {
        arguments args = n.getInternalArgs();
        return new Lambda(convertListExpr(args.getInternalArgs()),
                           convExpr(n.getInternalBody()),
                           convertListExpr(args.getInternalDefaults()),
                           (Name)convExpr(args.getInternalVarargName()),
                           (Name)convExpr(args.getInternalKwargName()),
                           start(n), stop(n));
    }

    @Override
    public Object visitList(org.python.antlr.ast.List n) throws Exception {
        return new NList(convertListExpr(n.getInternalElts()), start(n), stop(n));
    }

    @Override
    public Object visitSet(org.python.antlr.ast.Set n) throws Exception {
        return new Set(convertListExpr(n.getInternalElts()), start(n), stop(n));
    }

    // This is more complex than it should be, but let's wait until Jython add
    // visitors to comprehensions
    @Override
    public Object visitListComp(org.python.antlr.ast.ListComp n) throws Exception {
        List<Comprehension> generators =
                new ArrayList<Comprehension>(n.getInternalGenerators().size());
        for (comprehension c : n.getInternalGenerators()) {
            generators.add(new Comprehension(convExpr(c.getInternalTarget()),
                                              convExpr(c.getInternalIter()),
                                              convertListExpr(c.getInternalIfs()),
                                              start(c), stop(c)));
        }
        return new ListComp(convExpr(n.getInternalElt()), generators, start(n), stop(n));
    }

    @Override
    public Object visitSetComp(org.python.antlr.ast.SetComp n) throws Exception {
        List<Comprehension> generators =
                new ArrayList<Comprehension>(n.getInternalGenerators().size());
        for (comprehension c : n.getInternalGenerators()) {
            generators.add(new Comprehension(convExpr(c.getInternalTarget()),
                                              convExpr(c.getInternalIter()),
                                              convertListExpr(c.getInternalIfs()),
                                              start(c), stop(c)));
        }
        return new SetComp(convExpr(n.getInternalElt()), generators, start(n), stop(n));
    }

    @Override
    public Object visitDictComp(org.python.antlr.ast.DictComp n) throws Exception {
        List<Comprehension> generators =
                new ArrayList<Comprehension>(n.getInternalGenerators().size());
        for (comprehension c : n.getInternalGenerators()) {
            generators.add(new Comprehension(convExpr(c.getInternalTarget()),
                                              convExpr(c.getInternalIter()),
                                              convertListExpr(c.getInternalIfs()),
                                              start(c), stop(c)));
        }
        return new DictComp(convExpr(n.getInternalKey()), generators, start(n), stop(n));
    }

    @Override
    public Object visitModule(org.python.antlr.ast.Module n) throws Exception {
        return new Module(convertListStmt(n.getInternalBody()), start(n), stop(n));
    }

    @Override
    public Object visitName(org.python.antlr.ast.Name n) throws Exception {
        return new Name(n.getInternalId(), start(n), stop(n));
    }

    @Override
    public Object visitNum(org.python.antlr.ast.Num n) throws Exception {
        return new Num(n.getInternalN(), start(n), stop(n));
    }

    @Override
    public Object visitPass(org.python.antlr.ast.Pass n) throws Exception {
        return new Pass(start(n), stop(n));
    }

    @Override
    public Object visitPrint(org.python.antlr.ast.Print n) throws Exception {
        return new Print(convExpr(n.getInternalDest()),
                          convertListExpr(n.getInternalValues()),
                          start(n), stop(n));
    }

    @Override
    public Object visitRaise(org.python.antlr.ast.Raise n) throws Exception {
        return new Raise(convExpr(n.getInternalType()),
                          convExpr(n.getInternalInst()),
                          convExpr(n.getInternalTback()),
                          start(n), stop(n));
    }

    @Override
    public Object visitRepr(org.python.antlr.ast.Repr n) throws Exception {
        return new Repr(convExpr(n.getInternalValue()), start(n), stop(n));
    }

    @Override
    public Object visitReturn(org.python.antlr.ast.Return n) throws Exception {
        return new Return(convExpr(n.getInternalValue()), start(n), stop(n));
    }

    @Override
    public Object visitSlice(org.python.antlr.ast.Slice n) throws Exception {
        return new Slice(convExpr(n.getInternalLower()),
                          convExpr(n.getInternalStep()),
                          convExpr(n.getInternalUpper()),
                          start(n), stop(n));
    }

    @Override
    public Object visitStr(org.python.antlr.ast.Str n) throws Exception {
        return new Str(n.getInternalS(), start(n), stop(n));
    }

    @Override
    public Object visitSubscript(org.python.antlr.ast.Subscript n) throws Exception {
        return new Subscript(convExpr(n.getInternalValue()),
                              convExpr(n.getInternalSlice()),
                              start(n), stop(n));
    }

    @Override
    public Object visitTryExcept(org.python.antlr.ast.TryExcept n) throws Exception {
        return new TryExcept(convertListExceptHandler(n.getInternalHandlers()),
                              convertListStmt(n.getInternalBody()),
                              convertListStmt(n.getInternalOrelse()),
                              start(n), stop(n));
    }

    @Override
    public Object visitTryFinally(org.python.antlr.ast.TryFinally n) throws Exception {
        return new TryFinally(convertListStmt(n.getInternalBody()),
                               convertListStmt(n.getInternalFinalbody()),
                               start(n), stop(n));
    }

    @Override
    public Object visitTuple(org.python.antlr.ast.Tuple n) throws Exception {
        return new Tuple(convertListExpr(n.getInternalElts()), start(n), stop(n));
    }

    @Override
    public Object visitUnaryOp(org.python.antlr.ast.UnaryOp n) throws Exception {
        return new UnaryOp(null,  // XXX:  why null for operator?
                            convExpr(n.getInternalOperand()),
                            start(n), stop(n));
    }

    @Override
    public Object visitWhile(org.python.antlr.ast.While n) throws Exception {
        return new While(convExpr(n.getInternalTest()),
                          convertListStmt(n.getInternalBody()),
                          convertListStmt(n.getInternalOrelse()),
                          start(n), stop(n));
    }

    @Override
    public Object visitWith(org.python.antlr.ast.With n) throws Exception {
        return new With(convExpr(n.getInternalOptional_vars()),
                         convExpr(n.getInternalContext_expr()),
                         convertListStmt(n.getInternalBody()),
                         start(n), stop(n));
    }

    @Override
    public Object visitYield(org.python.antlr.ast.Yield n) throws Exception {
        return new Yield(convExpr(n.getInternalValue()), start(n), stop(n));
    }
}

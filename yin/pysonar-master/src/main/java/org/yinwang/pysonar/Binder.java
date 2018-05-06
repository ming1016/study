package org.yinwang.pysonar;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.ast.*;
import org.yinwang.pysonar.types.*;

import java.util.List;
import java.util.Set;


/**
 * Handles binding names to scopes, including destructuring assignment.
 */
public class Binder {

    public static void bind(@NotNull State s, Node target, @NotNull Type rvalue, Binding.Kind kind) {
        if (target instanceof Name) {
            bind(s, (Name) target, rvalue, kind);
        } else if (target instanceof Tuple) {
            bind(s, ((Tuple) target).elts, rvalue, kind);
        } else if (target instanceof PyList) {
            bind(s, ((PyList) target).elts, rvalue, kind);
        } else if (target instanceof Attribute) {
            ((Attribute) target).setAttr(s, rvalue);
        } else if (target instanceof Subscript) {
            Subscript sub = (Subscript) target;
            Type valueType = Node.transformExpr(sub.value, s);
            Node.transformExpr(sub.slice, s);
            if (valueType instanceof ListType) {
                ListType t = (ListType) valueType;
                t.setElementType(UnionType.union(t.eltType, rvalue));
            }
        } else if (target != null) {
            Analyzer.self.putProblem(target, "invalid location for assignment");
        }
    }


    /**
     * Without specifying a kind, bind determines the kind according to the type
     * of the scope.
     */
    public static void bind(@NotNull State s, Node target, @NotNull Type rvalue) {
        Binding.Kind kind;
        if (s.stateType == State.StateType.FUNCTION) {
            kind = Binding.Kind.VARIABLE;
        } else if (s.stateType == State.StateType.CLASS ||
                s.stateType == State.StateType.INSTANCE)
        {
            kind = Binding.Kind.ATTRIBUTE;
        } else {
            kind = Binding.Kind.SCOPE;
        }
        bind(s, target, rvalue, kind);
    }


    public static void bind(@NotNull State s, @NotNull List<Node> xs, @NotNull Type rvalue, Binding.Kind kind) {
        if (rvalue instanceof TupleType) {
            List<Type> vs = ((TupleType) rvalue).eltTypes;
            if (xs.size() != vs.size()) {
                reportUnpackMismatch(xs, vs.size());
            } else {
                for (int i = 0; i < xs.size(); i++) {
                    bind(s, xs.get(i), vs.get(i), kind);
                }
            }
        } else {
            if (rvalue instanceof ListType) {
                bind(s, xs, ((ListType) rvalue).toTupleType(xs.size()), kind);
            } else if (rvalue instanceof DictType) {
                bind(s, xs, ((DictType) rvalue).toTupleType(xs.size()), kind);
            } else if (rvalue.isUnknownType()) {
                for (Node x : xs) {
                    bind(s, x, Type.UNKNOWN, kind);
                }
            } else if (xs.size() > 0) {
                Analyzer.self.putProblem(xs.get(0).file,
                        xs.get(0).start,
                        xs.get(xs.size() - 1).end,
                        "unpacking non-iterable: " + rvalue);
            }
        }
    }


    public static void bind(@NotNull State s, @NotNull Name name, @NotNull Type rvalue, Binding.Kind kind) {
        if (s.isGlobalName(name.id)) {
            Set<Binding> bs = s.lookup(name.id);
            if (bs != null) {
                for (Binding b : bs) {
                    b.addType(rvalue);
                    Analyzer.self.putRef(name, b);
                }
            }
        } else {
            s.insert(name.id, name, rvalue, kind);
        }
    }


    // iterator
    public static void bindIter(@NotNull State s, Node target, @NotNull Node iter, Binding.Kind kind) {
        Type iterType = Node.transformExpr(iter, s);

        if (iterType instanceof ListType) {
            bind(s, target, ((ListType) iterType).eltType, kind);
        } else if (iterType instanceof TupleType) {
            bind(s, target, ((TupleType) iterType).toListType().eltType, kind);
        } else {
            Set<Binding> ents = iterType.table.lookupAttr("__iter__");
            if (ents != null) {
                for (Binding ent : ents) {
                    if (ent == null || !(ent.type instanceof FunType)) {
                        if (!iterType.isUnknownType()) {
                            Analyzer.self.putProblem(iter, "not an iterable type: " + iterType);
                        }
                        bind(s, target, Type.UNKNOWN, kind);
                    } else {
                        bind(s, target, ((FunType) ent.type).getReturnType(), kind);
                    }
                }
            } else {
                bind(s, target, Type.UNKNOWN, kind);
            }
        }
    }


    private static void reportUnpackMismatch(@NotNull List<Node> xs, int vsize) {
        int xsize = xs.size();
        int beg = xs.get(0).start;
        int end = xs.get(xs.size() - 1).end;
        int diff = xsize - vsize;
        String msg;
        if (diff > 0) {
            msg = "ValueError: need more than " + vsize + " values to unpack";
        } else {
            msg = "ValueError: too many values to unpack";
        }
        Analyzer.self.putProblem(xs.get(0).file, beg, end, msg);
    }
}

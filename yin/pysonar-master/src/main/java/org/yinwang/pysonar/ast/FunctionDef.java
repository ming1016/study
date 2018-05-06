package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.Binder;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ClassType;
import org.yinwang.pysonar.types.FunType;
import org.yinwang.pysonar.types.Type;

import java.util.List;


public class FunctionDef extends Node {

    public Name name;
    public List<Node> args;
    public List<Node> defaults;
    public Name vararg;  // *args
    public Name kwarg;   // **kwarg
    public List<Node> afterRest = null;   // after rest arg of Ruby
    public Node body;
    public boolean called = false;
    public boolean isLamba = false;


    public FunctionDef(Name name, List<Node> args, Node body, List<Node> defaults,
                       Name vararg, Name kwarg, String file, int start, int end)
    {
        super(file, start, end);
        if (name != null) {
            this.name = name;
        } else {
            isLamba = true;
            String fn = genLambdaName();
            this.name = new Name(fn, file, start, start + "lambda".length());
            addChildren(this.name);
        }

        this.args = args;
        this.body = body;
        this.defaults = defaults;
        this.vararg = vararg;
        this.kwarg = kwarg;
        addChildren(name);
        addChildren(args);
        addChildren(defaults);
        addChildren(vararg, kwarg, this.body);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        State env = s.getForwarding();
        FunType fun = new FunType(this, env);
        fun.table.setParent(s);
        fun.table.setPath(s.extendPath(name.id));
        fun.setDefaultTypes(resolveList(defaults, s));
        Analyzer.self.addUncalled(fun);
        Binding.Kind funkind;

        if (isLamba) {
            return fun;
        } else {
            if (s.stateType == State.StateType.CLASS) {
                if ("__init__".equals(name.id)) {
                    funkind = Binding.Kind.CONSTRUCTOR;
                } else {
                    funkind = Binding.Kind.METHOD;
                }
            } else {
                funkind = Binding.Kind.FUNCTION;
            }

            Type outType = s.type;
            if (outType instanceof ClassType) {
                fun.setCls((ClassType) outType);
            }

            Binder.bind(s, name, fun, funkind);
            return Type.CONT;
        }
    }


    public String getArgumentExpr() {
        StringBuilder argExpr = new StringBuilder();
        argExpr.append("(");
        boolean first = true;

        for (Node n : args) {
            if (!first) {
                argExpr.append(", ");
            }
            first = false;
            argExpr.append(n.toDisplay());
        }

        if (vararg != null) {
            if (!first) {
                argExpr.append(", ");
            }
            first = false;
            argExpr.append("*" + vararg.toDisplay());
        }

        if (kwarg != null) {
            if (!first) {
                argExpr.append(", ");
            }
            argExpr.append("**" + kwarg.toDisplay());
        }

        argExpr.append(")");
        return argExpr.toString();
    }


    private static int lambdaCounter = 0;


    @NotNull
    public static String genLambdaName() {
        lambdaCounter = lambdaCounter + 1;
        return "lambda%" + lambdaCounter;
    }


    @NotNull
    @Override
    public String toString() {
        return "(func:" + start + ":" + name + ")";
    }

}

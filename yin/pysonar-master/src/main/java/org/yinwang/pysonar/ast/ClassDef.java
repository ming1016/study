package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.*;
import org.yinwang.pysonar.types.*;

import java.util.ArrayList;
import java.util.List;


public class ClassDef extends Node {

    @NotNull
    public Name name;
    public List<Node> bases;
    public Node body;


    public ClassDef(@NotNull Name name, List<Node> bases, Node body, String file, int start, int end) {
        super(file, start, end);
        this.name = name;
        this.bases = bases;
        this.body = body;
        addChildren(name, this.body);
        addChildren(bases);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        ClassType classType = new ClassType(name.id, s);
        List<Type> baseTypes = new ArrayList<>();
        for (Node base : bases) {
            Type baseType = transformExpr(base, s);
            if (baseType instanceof ClassType) {
                classType.addSuper(baseType);
            } else if (baseType instanceof UnionType) {
                for (Type parent : ((UnionType) baseType).types) {
                    classType.addSuper(parent);
                }
            } else {
                Analyzer.self.putProblem(base, base + " is not a class");
            }
            baseTypes.add(baseType);
        }

        // XXX: Not sure if we should add "bases", "name" and "dict" here. They
        // must be added _somewhere_ but I'm just not sure if it should be HERE.
        addSpecialAttribute(classType.table, "__bases__", new TupleType(baseTypes));
        addSpecialAttribute(classType.table, "__name__", Type.STR);
        addSpecialAttribute(classType.table, "__dict__",
                new DictType(Type.STR, Type.UNKNOWN));
        addSpecialAttribute(classType.table, "__module__", Type.STR);
        addSpecialAttribute(classType.table, "__doc__", Type.STR);

        // Bind ClassType to name here before resolving the body because the
        // methods need this type as self.
        Binder.bind(s, name, classType, Binding.Kind.CLASS);
        if (body != null) {
            transformExpr(body, classType.table);
        }
        return Type.CONT;
    }


    private void addSpecialAttribute(@NotNull State s, String name, Type proptype) {
        Binding b = new Binding(name, Builtins.newTutUrl("classes.html"), proptype, Binding.Kind.ATTRIBUTE);
        s.update(name, b);
        b.markSynthetic();
        b.markStatic();

    }


    @NotNull
    @Override
    public String toString() {
        return "(class:" + name.id + ":" + start + ")";
    }

}

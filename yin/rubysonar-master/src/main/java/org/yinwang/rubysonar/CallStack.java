package org.yinwang.rubysonar;

import org.jetbrains.annotations.NotNull;
import org.yinwang.rubysonar.ast.Node;
import org.yinwang.rubysonar.types.Type;

import java.util.HashSet;
import java.util.Set;


public class CallStack {

    @NotNull
    private Set<Node> stack = new HashSet<>();


    public void push(Node call, Type type) {
        stack.add(call);
    }


    public void pop(Node call, Type type) {
        stack.remove(call);
    }


    public boolean contains(Node call, Type type) {
        return stack.contains(call);
    }
}

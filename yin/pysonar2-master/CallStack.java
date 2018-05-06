package org.python.indexer;

import org.python.indexer.ast.Node;
import org.python.indexer.types.Type;

import java.util.HashSet;
import java.util.Set;


public class CallStack {

    //    private Map<Node, Set<Type>> stack = new HashMap<Node, Set<Type>>();
    private Set<Node> stack = new HashSet<Node>();

    public void push(Node call, Type type) {
//        Set<Type> inner = stack.get(call);
//        if (inner != null) {
//            inner.add(type);
//        } else {
//            inner = new HashSet<Type>();
//            inner.add(type);
//            stack.put(call, inner);
//        }
        stack.add(call);
    }


    public void pop(Node call, Type type) {
//        Set<Type> inner = stack.get(call);
//        if (inner != null) {
//            inner.remove(type);
//            if (inner.isEmpty()) {
//                stack.remove(call);
//            }
//        }
        stack.remove(call);
    }


    public boolean contains(Node call, Type type) {
//        Set<Type> inner = stack.get(call);
//        if (inner != null) {
//            return inner.contains(type);
//        } else {
//            return false;
//        }
        return stack.contains(call);
    }
}

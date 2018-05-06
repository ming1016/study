package org.yinwang.pysonar;

import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.List;


public class TypeStack {

    class Pair {
        public Object first;
        public Object second;


        public Pair(Object first, Object second) {
            this.first = first;
            this.second = second;
        }
    }


    @NotNull
    private List<Pair> stack = new ArrayList<>();


    public void push(Object first, Object second) {
        stack.add(new Pair(first, second));
    }


    public void pop(Object first, Object second) {
        stack.remove(stack.size() - 1);
    }


    public boolean contains(Object first, Object second) {
        for (Pair p : stack) {
            if (p.first == first && p.second == second ||
                    p.first == second && p.second == first)
            {
                return true;
            }
        }
        return false;
    }

}

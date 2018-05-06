package org.yinwang.pysonar;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.types.ClassType;
import org.yinwang.pysonar.types.Type;
import org.yinwang.pysonar.types.UnionType;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;


/**
 * Generates a file outline from the index: a structure representing the
 * variable and attribute definitions in a file.
 */
public class Outliner {

    public static abstract class Entry {
        @Nullable
        public String qname;  // entry qualified name
        public int offset;  // file offset of referenced declaration
        @Nullable
        public Binding.Kind kind;  // binding kind of outline entry


        public Entry() {
        }


        public Entry(String qname, int offset, Binding.Kind kind) {
            this.qname = qname;
            this.offset = offset;
            this.kind = kind;
        }


        public abstract boolean isLeaf();


        @NotNull
        public Leaf asLeaf() {
            return (Leaf) this;
        }


        public abstract boolean isBranch();


        @NotNull
        public Branch asBranch() {
            return (Branch) this;
        }


        public abstract boolean hasChildren();


        public abstract List<Entry> getChildren();


        public abstract void setChildren(List<Entry> children);


        @Nullable
        public String getQname() {
            return qname;
        }


        public void setQname(@Nullable String qname) {
            if (qname == null) {
                throw new IllegalArgumentException("qname param cannot be null");
            }
            this.qname = qname;
        }


        /**
         * Returns the file offset of the beginning of the identifier referenced
         * by this outline entry.
         */
        public int getOffset() {
            return offset;
        }


        public void setOffset(int offset) {
            this.offset = offset;
        }


        public void setKind(@Nullable Binding.Kind kind) {
            if (kind == null) {
                throw new IllegalArgumentException("kind param cannot be null");
            }
            this.kind = kind;
        }


        /**
         * Returns the simple (unqualified) name of the identifier.
         */
        public String getName() {
            String[] parts = qname.split("[.&@%]");
            return parts[parts.length - 1];
        }


        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            toString(sb, 0);
            return sb.toString().trim();
        }


        public void toString(@NotNull StringBuilder sb, int depth) {
            for (int i = 0; i < depth; i++) {
                sb.append("  ");
            }
            sb.append(kind);
            sb.append(" ");
            sb.append(getName());
            sb.append("\n");
            if (hasChildren()) {
                for (Entry e : getChildren()) {
                    e.toString(sb, depth + 1);
                }
            }
        }
    }


    /**
     * An outline entry with children.
     */
    public static class Branch extends Entry {
        private List<Entry> children = new ArrayList<>();


        public Branch() {
        }


        public Branch(String qname, int start, Binding.Kind kind) {
            super(qname, start, kind);
        }


        public boolean isLeaf() {
            return false;
        }


        public boolean isBranch() {
            return true;
        }


        public boolean hasChildren() {
            return children != null && !children.isEmpty();
        }


        public List<Entry> getChildren() {
            return children;
        }


        public void setChildren(List<Entry> children) {
            this.children = children;
        }
    }


    /**
     * An entry with no children.
     */
    public static class Leaf extends Entry {
        public boolean isLeaf() {
            return true;
        }


        public boolean isBranch() {
            return false;
        }


        public Leaf() {
        }


        public Leaf(String qname, int start, Binding.Kind kind) {
            super(qname, start, kind);
        }


        public boolean hasChildren() {
            return false;
        }


        @NotNull
        public List<Entry> getChildren() {
            return new ArrayList<>();
        }


        public void setChildren(List<Entry> children) {
            throw new UnsupportedOperationException("Leaf nodes cannot have children.");
        }
    }


    /**
     * Create an outline for a file in the index.
     *
     * @param scope the file scope
     * @param path  the file for which to build the outline
     * @return a list of entries constituting the file outline.
     * Returns an empty list if the analyzer hasn't analyzed that path.
     */
    @NotNull
    public List<Entry> generate(@NotNull Analyzer idx, @NotNull String abspath) {
        Type mt = idx.loadFile(abspath);
        if (mt == null) {
            return new ArrayList<>();
        }
        return generate(mt.table, abspath);
    }


    /**
     * Create an outline for a symbol table.
     *
     * @param state the file state
     * @param path  the file for which we're building the outline
     * @return a list of entries constituting the outline
     */
    @NotNull
    public List<Entry> generate(@NotNull State state, @NotNull String path) {
        List<Entry> result = new ArrayList<>();

        Set<Binding> entries = new TreeSet<>();
        for (Binding b : state.values()) {
            if (!b.isSynthetic()
                    && !b.isBuiltin()
                    && path.equals(b.getFile()))
            {
                entries.add(b);
            }
        }

        for (Binding nb : entries) {
            List<Entry> kids = null;

            if (nb.kind == Binding.Kind.CLASS) {
                Type realType = nb.type;
                if (realType instanceof UnionType) {
                    for (Type t : ((UnionType) realType).types) {
                        if (t instanceof ClassType) {
                            realType = t;
                            break;
                        }
                    }
                }
                kids = generate(realType.table, path);
            }

            Entry kid = kids != null ? new Branch() : new Leaf();
            kid.setOffset(nb.start);
            kid.setQname(nb.qname);
            kid.setKind(nb.kind);

            if (kids != null) {
                kid.setChildren(kids);
            }
            result.add(kid);
        }
        return result;
    }
}

package org.python.indexer;

import org.python.indexer.types.ModuleType;
import org.python.indexer.types.Type;

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
        protected String qname;  // entry qualified name
        protected int offset;  // file offset of referenced declaration
        protected Binding.Kind kind;  // binding kind of outline entry

        public Entry() {
        }

        public Entry(String qname, int offset, Binding.Kind kind) {
            this.qname = qname;
            this.offset = offset;
            this.kind = kind;
        }

        public abstract boolean isLeaf();
        public Leaf asLeaf() {
            return (Leaf)this;
        }

        public abstract boolean isBranch();
        public Branch asBranch() {
            return (Branch)this;
        }

        public abstract boolean hasChildren();
        public abstract List<Entry> getChildren();
        public abstract void setChildren(List<Entry> children);

        public String getQname() {
            return qname;
        }
        public void setQname(String qname) {
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

        public Binding.Kind getKind() {
            return kind;
        }
        public void setKind(Binding.Kind kind) {
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
            return parts[parts.length-1];
        }

        @Override public String toString() {
            StringBuilder sb = new StringBuilder();
            toString(sb, 0);
            return sb.toString().trim();
        }

        public void toString(StringBuilder sb, int depth) {
            for (int i = 0; i < depth; i++) {
                sb.append("  ");
            }
            sb.append(getKind());
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
        private List<Entry> children = new ArrayList<Entry>();

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
        public List<Entry> getChildren() {
            return new ArrayList<Entry>();
        }
        public void setChildren(List<Entry> children) {
            throw new UnsupportedOperationException("Leaf nodes cannot have children.");
        }
    }

    /**
     * Create an outline for a file in the index.
     * @param scope the file scope
     * @param path the file for which to build the outline
     * @return a list of entries constituting the file outline.
     * Returns an empty list if the indexer hasn't indexed that path.
     */
    public List<Entry> generate(Indexer idx, String abspath) throws Exception {
        ModuleType mt = idx.getModuleForFile(abspath);
        if (mt == null) {
            return new ArrayList<Entry>();
        }
        return generate(mt.getTable(), abspath);
    }

    /**
     * Create an outline for a symbol table.
     * @param scope the file scope
     * @param path the file for which we're building the outline
     * @return a list of entries constituting the outline
     */
    public List<Entry> generate(Scope scope, String path) {
        List<Entry> result = new ArrayList<Entry>();

        Set<Binding> entries = new TreeSet<Binding>();
        for (Binding nb : scope.values()) {
            if (!nb.isSynthetic()
                && !nb.isBuiltin()
                && !nb.getDefs().isEmpty()
                && path.equals(nb.getSignatureNode().getFile())) {
                entries.add(nb);
            }
        }

        for (Binding nb : entries) {
            Def signode = nb.getSignatureNode();
            List<Entry> kids = null;

            if (nb.getKind() == Binding.Kind.CLASS) {
                Type realType = nb.getType();
                if (realType.isUnionType()) {
                    for (Type t : realType.asUnionType().getTypes()) {
                        if (t.isClassType()) {
                            realType = t;
                            break;
                        }
                    }
                }
                kids = generate(realType.getTable(), path);
            }

            Entry kid = kids != null ? new Branch() : new Leaf();
            kid.setOffset(signode.getStart());
            kid.setQname(nb.getQname());
            kid.setKind(nb.getKind());

            if (kids != null) {
                kid.setChildren(kids);
            }
            result.add(kid);
        }
        return result;
    }
}

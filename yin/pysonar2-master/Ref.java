package org.python.indexer;

import org.python.indexer.ast.Attribute;
import org.python.indexer.ast.Name;
import org.python.indexer.ast.Node;
import org.python.indexer.ast.Str;

/**
 * Encapsulates information about a binding reference.
 */
public class Ref {

    private static final int ATTRIBUTE = 0x1;
    private static final int CALL = 0x2;  // function/method call
    private static final int NEW = 0x4;  // instantiation
    private static final int STRING = 0x8; // source node is a String

    private int start;
    private String file;
    private String name;
    private int flags;

    public Ref(Node node) {
        if (node == null) {
            throw new IllegalArgumentException("null node");
        }
        file = node.getFile();
        start = node.start();

        if (node instanceof Name) {
            Name nn = ((Name)node);
            name = nn.getId();
            if (nn.isCall()) {
                // We don't always have enough information at this point to know
                // if it's a constructor call or a regular function/method call,
                // so we just determine if it looks like a call or not, and the
                // indexer will convert constructor-calls to NEW in a later pass.
                markAsCall();
            }
        } else if (node instanceof Str) {
            markAsString();
            name = ((Str)node).getStr();
        } else {
            throw new IllegalArgumentException("I don't know what " + node + " is.");
        }

        Node parent = node.getParent();
        if ((parent instanceof Attribute)
            && node == ((Attribute)parent).attr) {
            markAsAttribute();
        }
    }

    /**
     * Constructor that provides a way for clients to add additional references
     * not associated with an AST node (e.g. inside a comment or doc string).
     * @param path absolute path to the file containing the reference
     * @param offset the 0-indexed file offset of the reference
     * @param text the text of the reference
     */
    public Ref(String path, int offset, String text) {
        if (path == null) {
            throw new IllegalArgumentException("'path' cannot be null");
        }
        if (text == null) {
            throw new IllegalArgumentException("'text' cannot be null");
        }
        file = path;
        start = offset;
        name = text;
    }

    /**
     * Returns the file containing the reference.
     */
    public String getFile() {
        return file;
    }

    /**
     * Returns the text of the reference.
     */
    public String getName() {
        return name;
    }

    /**
     * Returns the starting file offset of the reference.
     */
    public int start() {
        return start;
    }

    /**
     * Returns the ending file offset of the reference.
     */
    public int end() {
        return start + length();
    }

    /**
     * Returns the length of the reference text.
     */
    public int length() {
        return isString() ? name.length() + 2 : name.length();
    }

    /**
     * Returns {@code true} if this reference was unquoted name.
     */
    public boolean isName() {
        return !isString();
    }

    /**
     * Returns {@code true} if this reference was an attribute
     * of some other node.
     */
    public boolean isAttribute() {
        return (flags & ATTRIBUTE) != 0;
    }

    public void markAsAttribute() {
        flags |= ATTRIBUTE;
    }

    /**
     * Returns {@code true} if this reference was a quoted name.
     * If so, the {@link #start} and {@link #length} include the positions
     * of the opening and closing quotes, but {@link #isName} returns the
     * text within the quotes.
     */
    public boolean isString() {
        return (flags & STRING) != 0;
    }

    public void markAsString() {
        flags |= STRING;
    }

    /**
     * Returns {@code true} if this reference is a function or method call.
     */
    public boolean isCall() {
        return (flags & CALL) != 0;
    }

    /**
     * Returns {@code true} if this reference is a class instantiation.
     */
    public void markAsCall() {
        flags |= CALL;
        flags &= ~NEW;
    }

    public boolean isNew() {
        return (flags & NEW) != 0;
    }

    public void markAsNew() {
        flags |= NEW;
        flags &= ~CALL;
    }

    public boolean isRef() {
        return !(isCall() || isNew());
    }

    @Override
    public String toString() {
        return "<Ref:" + file + ":" + name + ":" + start + ">";
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Ref)) {
            return false;
        } else {
            Ref ref = (Ref)obj;
            return  (start == ref.start &&
                        (file == null && ref.file == null) || file.equals(ref.file));
        }
    }

    @Override
    public int hashCode() {
        return ("" + file + start).hashCode();
    }
}

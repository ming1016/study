package org.python.indexer;

import org.python.indexer.ast.Name;
import org.python.indexer.ast.Node;
import org.python.indexer.ast.Url;

/**
 * Encapsulates information about a binding definition site.
 */
public class Def {

    // Being frugal with fields here is good for memory usage.
    private int start;
    private int end;
    private Binding binding;
    private String fileOrUrl;
    private String name;
    private Node node;

    public Def(Node node) {
        this(node, null);
    }

    public Def(Node node, Binding b) {
        if (node == null) {
            throw new IllegalArgumentException("null 'node' param");
        }
        this.node = node;
        binding = b;
        if (node instanceof Url) {
            String url = ((Url)node).getURL();
            if (url.startsWith("file://")) {
                fileOrUrl = url.substring("file://".length());
            } else {
                fileOrUrl = url;
            }
            return;
        }

        // start/end offsets are invalid/bogus for NUrls
        start = node.start();
        end = node.end();
        fileOrUrl = node.getFile();
        if (fileOrUrl == null) {
            throw new IllegalArgumentException("Non-URL nodes must have a non-null file");
        }
        if (node instanceof Name) {
            name = node.asName().getId();
        }
    }

    /**
     * Returns the name of the node.  Only applies if the definition coincides
     * with a {@link org.python.indexer.ast.Name} node.
     * @return the name, or null
     */
    public String getName() {
        return name;
    }

    /**
     * Returns the file if this node is from a source file, else {@code null}.
     */
    public String getFile() {
        return isURL() ? null : fileOrUrl;
    }

    /**
     * Returns the URL if this node is from a URL, else {@code null}.
     */
    public String getURL() {
        return isURL() ? fileOrUrl : null;
    }

    /**
     * Returns the file if from a source file, else the URL.
     */
    public String getFileOrUrl() {
        return fileOrUrl;
    }

    /**
     * Returns {@code true} if this node is from a URL.
     */
    public boolean isURL() {
        return fileOrUrl.startsWith("http://");
    }

    public boolean isModule() {
        return binding != null && binding.getKind() == Binding.Kind.MODULE;
    }

    public int getStart() {
        return start;
    }

    public int getEnd() {
        return end;
    }

    public int getLength() {
        return end - start;
    }

    public boolean isName() {
        return name != null;
    }

    void setBinding(Binding b) {
        binding = b;
    }

    public Binding getBinding() {
        return binding;
    }
    
    public Node getNode() {
        return node;
    }

    public void setNode(Node node) {
        this.node = node;
    }

    @Override
    public String toString() {
        return "<Def:" + (name == null ? "" : name) +
                ":" + start + ":" + fileOrUrl + ">";
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Def)) {
            return false;
        } else {
            Def def = (Def)obj;
            return (start == def.start 
                 && end   == def.end
                 && (fileOrUrl == null && def.fileOrUrl == null
                  || fileOrUrl == def.fileOrUrl));
        }
    }

    @Override
    public int hashCode() {
        return ("" + fileOrUrl + start).hashCode();
    }

}

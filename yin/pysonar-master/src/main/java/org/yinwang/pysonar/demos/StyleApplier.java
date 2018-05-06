package org.yinwang.pysonar.demos;

import org.jetbrains.annotations.NotNull;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar._;

import java.util.List;
import java.util.SortedSet;
import java.util.TreeSet;


/**
 * Turns a list of {@link Style}s into HTML spans.
 */
class StyleApplier {

    @NotNull
    private SortedSet<Tag> tags = new TreeSet<Tag>();

    private StringBuilder buffer;  // html output buffer

    private String source;  // input source code

    // Current offset into the source being copied into the html buffer.
    private int sourceOffset = 0;


    abstract class Tag implements Comparable<Tag> {
        int offset;
        Style style;


        @Override
        public int compareTo(@NotNull Tag other) {
            if (this == other) {
                return 0;
            }
            if (this.offset < other.offset) {
                return -1;
            }
            if (other.offset < this.offset) {
                return 1;
            }
            return this.hashCode() - other.hashCode();
        }


        void insert() {
            // Copy source code up through this tag.
            if (offset > sourceOffset) {
                copySource(sourceOffset, offset);
            }
        }
    }


    class StartTag extends Tag {
        public StartTag(@NotNull Style style) {
            offset = style.start;
            this.style = style;
        }


        @Override
        void insert() {
            super.insert();
            if (Analyzer.self.hasOption("debug")) {
                switch (style.type) {
                    case ANCHOR:
                        buffer.append("<a name='" + style.url + "'");
                        buffer.append(", id ='" + style.id + "'");
                        if (style.highlight != null && !style.highlight.isEmpty()) {
                            String ids = _.joinWithSep(style.highlight, "\",\"", "\"", "\"");
                            buffer.append(", onmouseover='highlight(").append(ids).append(")'");
                        }
                        break;
                    case LINK:
                        buffer.append("<a href='" + style.url + "'");
                        buffer.append(", id ='" + style.id + "'");
                        if (style.highlight != null && !style.highlight.isEmpty()) {
                            String ids = _.joinWithSep(style.highlight, "\",\"", "\"", "\"");
                            buffer.append(", onmouseover='highlight(").append(ids).append(")'");
                        }
                        break;
                    default:
                        buffer.append("<span class='");
                        buffer.append(toCSS(style)).append("'");
                        break;
                }
            } else {
                switch (style.type) {
                    case ANCHOR:
                        buffer.append("<a name='" + style.url + "'");
                        buffer.append(", xid ='" + style.id + "'");
                        break;
                    case LINK:
                        buffer.append("<a href='" + style.url + "'");
                        buffer.append(", xid ='" + style.id + "'");
                        break;
                    default:
                        buffer.append("<span class='");
                        buffer.append(toCSS(style)).append("'");
                        break;
                }
            }
            if (style.message != null) {
                buffer.append(", title='");
                buffer.append(style.message);
                buffer.append("'");
            }
            buffer.append(">");
        }
    }


    class EndTag extends Tag {
        public EndTag(@NotNull Style style) {
            offset = style.end;
            this.style = style;
        }


        @Override
        void insert() {
            super.insert();
            switch (style.type) {
                case ANCHOR:
                case LINK:
                    buffer.append("</a>");
                    break;
                default:
                    buffer.append("</span>");
                    break;
            }
        }
    }


    public StyleApplier(String path, String src, @NotNull List<Style> runs) {
        source = src;
        for (Style run : runs) {
            tags.add(new StartTag(run));
            tags.add(new EndTag(run));
        }
    }


    /**
     * @return the html
     */
    @NotNull
    public String apply() {
        buffer = new StringBuilder();

        for (Tag tag : tags) {
            tag.insert();
        }
        // Copy in remaining source beyond last tag.
        if (sourceOffset < source.length()) {
            copySource(sourceOffset, source.length());
        }
        return buffer.toString();
    }


    /**
     * Copies code from the input source to the output html.
     *
     * @param begin the starting source offset
     * @param end   the end offset, or -1 to go to end of file
     */
    private void copySource(int begin, int end) {
        // Be robust if the analyzer gives us bad offsets.
        try {
            String src = escape((end == -1)
                    ? source.substring(begin)
                    : source.substring(begin, end));
            buffer.append(src);
        } catch (RuntimeException x) {
            // This can happen with files with weird encodings
            // Igore them because of the rareness
        }
        sourceOffset = end;
    }


    private String escape(@NotNull String s) {
        return s.replace("&", "&amp;")
                .replace("'", "&#39;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }


    private String toCSS(@NotNull Style style) {
        return style.type.toString().toLowerCase().replace("_", "-");
    }
}

package org.yinwang.pysonar.demos;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.Outliner;
import org.yinwang.pysonar._;

import java.util.List;


class HtmlOutline {

    private Analyzer analyzer;
    @Nullable
    private StringBuilder buffer;


    public HtmlOutline(Analyzer idx) {
        this.analyzer = idx;
    }


    @NotNull
    public String generate(String path) {
        buffer = new StringBuilder(1024);
        List<Outliner.Entry> entries = generateOutline(analyzer, path);
        addOutline(entries);
        String html = buffer.toString();
        buffer = null;
        return html;
    }


    @NotNull
    public List<Outliner.Entry> generateOutline(Analyzer analyzer, @NotNull String file) {
        return new Outliner().generate(analyzer, file);
    }


    private void addOutline(@NotNull List<Outliner.Entry> entries) {
        add("<ul>\n");
        for (Outliner.Entry e : entries) {
            addEntry(e);
        }
        add("</ul>\n");
    }


    private void addEntry(@NotNull Outliner.Entry e) {
        add("<li>");

        String style = null;
        switch (e.kind) {
            case FUNCTION:
            case METHOD:
            case CONSTRUCTOR:
                style = "function";
                break;
            case CLASS:
                style = "type-name";
                break;
            case PARAMETER:
                style = "parameter";
                break;
            case VARIABLE:
            case SCOPE:
                style = "identifier";
                break;
        }

        add("<a href='#");
        add(e.getQname());
        add("', onmouseover='highlight(\"" + _.escapeQname(e.getQname()) + "\")'>");

        if (style != null) {
            add("<span class='");
            add(style);
            add("'>");
        }
        add(e.getName());
        if (style != null) {
            add("</span>");
        }

        add("</a>");

        if (e.isBranch()) {
            addOutline(e.getChildren());
        }
        add("</li>");
    }


    private void add(String text) {
        buffer.append(text);
    }
}

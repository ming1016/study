package org.yinwang.yin.parser;


import org.jetbrains.annotations.Nullable;
import org.yinwang.yin.Constants;
import org.yinwang.yin._;
import org.yinwang.yin.ast.*;

import java.util.*;


/**
 * first phase parser
 * parse into S-expression like format
 */
public class PreParser {

    public String file;
    public String text;

    // current offset indicators
    public int offset;
    public int line;
    public int col;

    // all delimeters
    public final Set<String> delims = new HashSet<>();
    // map open delimeters to their matched closing ones
    public final Map<String, String> delimMap = new HashMap<>();


    public PreParser(String file) {
        this.file = _.unifyPath(file);
        this.text = _.readFile(file);
        this.offset = 0;
        this.line = 0;
        this.col = 0;

        if (text == null) {
            _.abort("failed to read file: " + file);
        }

        addDelimiterPair(Constants.TUPLE_BEGIN, Constants.TUPLE_END);
        addDelimiterPair(Constants.RECORD_BEGIN, Constants.RECORD_END);
        addDelimiterPair(Constants.ARRAY_BEGIN, Constants.ARRAY_END);

        addDelimiter(Constants.ATTRIBUTE_ACCESS);
    }


    public void forward() {
        if (text.charAt(offset) == '\n') {
            line++;
            col = 0;
            offset++;
        } else {
            col++;
            offset++;
        }
    }


    public void addDelimiterPair(String open, String close) {
        delims.add(open);
        delims.add(close);
        delimMap.put(open, close);
    }


    public void addDelimiter(String delim) {
        delims.add(delim);
    }


    public boolean isDelimiter(char c) {
        return delims.contains(Character.toString(c));
    }


    public boolean isOpen(Node c) {
        if (c instanceof Delimeter) {
            return delimMap.keySet().contains(((Delimeter) c).shape);
        } else {
            return false;
        }
    }


    public boolean isClose(Node c) {
        if (c instanceof Delimeter) {
            return delimMap.values().contains(((Delimeter) c).shape);
        } else {
            return false;
        }
    }


    public boolean matchString(String open, String close) {
        String matched = delimMap.get(open);
        if (matched != null && matched.equals(close)) {
            return true;
        } else {
            return false;
        }
    }


    public boolean matchDelim(Node open, Node close) {
        return (open instanceof Delimeter &&
                close instanceof Delimeter &&
                matchString(((Delimeter) open).shape, ((Delimeter) close).shape));
    }


    /**
     * lexer
     *
     * @return a token or null if file ends
     */
    @Nullable
    private Node nextToken() {

        boolean seenComment = true;
        while (seenComment) {
            seenComment = false;
            // skip spaces
            while (offset < text.length() &&
                    Character.isWhitespace(text.charAt(offset)))
            {
                forward();
            }

            // comments
            if (offset + Constants.LINE_COMMENT.length() <= text.length() &&
                    text.substring(offset, offset + Constants.LINE_COMMENT.length()).equals(Constants.LINE_COMMENT))
            {
                while (offset < text.length() && text.charAt(offset) != '\n') {
                    forward();
                }
                if (offset < text.length()) {
                    forward();
                }
                seenComment = true;
            }
        }

        // end of file
        if (offset >= text.length()) {
            return null;
        }

        char cur = text.charAt(offset);

        // delimiters
        if (isDelimiter(cur)) {
            Node ret = new Delimeter(Character.toString(cur), file, offset, offset + 1, line, col);
            forward();
            return ret;
        }

        // string
        if (text.charAt(offset) == '"' && (offset == 0 || text.charAt(offset - 1) != '\\')) {
            int start = offset;
            int startLine = line;
            int startCol = col;
            forward();   // skip "

            while (offset < text.length() &&
                    !(text.charAt(offset) == '"' && text.charAt(offset - 1) != '\\'))
            {
                if (text.charAt(offset) == '\n') {
                    _.abort(file + ":" + startLine + ":" + startCol + ": runaway string");
                    return null;
                }
                forward();
            }

            if (offset >= text.length()) {
                _.abort(file + ":" + startLine + ":" + startCol + ": runaway string");
                return null;
            }

            forward(); // skip "
            int end = offset;

            String content = text.substring(start + 1, end - 1);
            return new Str(content, file, start, end, startLine, startCol);
        }


        // find consequtive token
        int start = offset;
        int startLine = line;
        int startCol = col;

        if (Character.isDigit(text.charAt(start)) ||
                ((text.charAt(start) == '+' || text.charAt(start) == '-')
                        && Character.isDigit(text.charAt(start + 1))))
        {
            while (offset < text.length() &&
                    !Character.isWhitespace(cur) &&
                    !(isDelimiter(cur) && cur != '.'))
            {
                forward();
                if (offset < text.length()) {
                    cur = text.charAt(offset);
                }
            }

            String content = text.substring(start, offset);

            IntNum intNum = IntNum.parse(content, file, start, offset, startLine, startCol);
            if (intNum != null) {
                return intNum;
            } else {
                FloatNum floatNum = FloatNum.parse(content, file, start, offset, startLine, startCol);
                if (floatNum != null) {
                    return floatNum;
                } else {
                    _.abort(file + ":" + startLine + ":" + startCol + " : incorrect number format: " + content);
                    return null;
                }
            }
        } else {
            while (offset < text.length() &&
                    !Character.isWhitespace(cur) &&
                    !isDelimiter(cur))
            {
                forward();
                if (offset < text.length()) {
                    cur = text.charAt(offset);
                }
            }

            String content = text.substring(start, offset);
            if (content.matches(":\\w.*")) {
                return new Keyword(content.substring(1), file, start, offset, startLine, startCol);
            } else {
                return new Name(content, file, start, offset, startLine, startCol);
            }
        }
    }


    /**
     * parser
     *
     * @return a Node or null if file ends
     */
    public Node nextNode(int depth) {
        Node begin = nextToken();

        // end of file
        if (begin == null) {
            return null;
        }

        if (depth == 0 && isClose(begin)) {
            _.abort(begin, "unmatched closing delimeter: " + begin);
            return null;
        } else if (isOpen(begin)) {   // try to get matched (...)
            List<Node> elements = new ArrayList<>();
            Node iter = nextNode(depth + 1);

            while (!matchDelim(begin, iter)) {
                if (iter == null) {
                    _.abort(begin, "unclosed delimeter: " + begin);
                    return null;
                } else if (isClose(iter)) {
                    _.abort(iter, "unmatched closing delimeter: " + iter);
                    return null;
                } else {
                    elements.add(iter);
                    iter = nextNode(depth + 1);
                }
            }
            return new Tuple(elements, begin, iter, begin.file, begin.start, iter.end, begin.line, begin.col);
        } else {
            return begin;
        }
    }


    // wrapper for the actual parser
    public Node nextSexp() {
        return nextNode(0);
    }


    // parse file into a Node
    public Node parse() {
        List<Node> elements = new ArrayList<>();
        // synthetic block keyword
        elements.add(genName(Constants.SEQ_KEYWORD));

        Node s = nextSexp();
        while (s != null) {
            elements.add(s);
            s = nextSexp();
        }
        return new Tuple(elements, genName(Constants.TUPLE_BEGIN), genName(Constants.TUPLE_END),
                file, 0, text.length(), 0, 0);
    }


    public Name genName(String id) {
        return new Name(id, file, 0, 0, 0, 0);
    }


    public static void main(String[] args) {
        PreParser p = new PreParser(args[0]);
        _.msg("tree: " + p.parse());
    }
}

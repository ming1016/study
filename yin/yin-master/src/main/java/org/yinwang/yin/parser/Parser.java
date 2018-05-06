package org.yinwang.yin.parser;

import org.yinwang.yin.Constants;
import org.yinwang.yin.Scope;
import org.yinwang.yin._;
import org.yinwang.yin.ast.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class Parser {

    public static Node parse(String file) {
        PreParser preparser = new PreParser(file);
        Node prenode = preparser.parse();
        Node grouped = groupAttr(prenode);
        return parseNode(grouped);
    }


    public static Node parseNode(Node prenode) {

        // initial program is in a block
        if (prenode instanceof Block) {
            List<Node> parsed = parseList(((Block) prenode).statements);
            return new Block(parsed, prenode.file, prenode.start, prenode.end, prenode.line, prenode.col);
        }

        if (prenode instanceof Attr) {
            Attr a = (Attr) prenode;
            return new Attr(parseNode(a.value), a.attr, a.file, a.start, a.end, a.line, a.col);
        }

        // most structures are encoded in a tuple
        // (if t c a) (+ 1 2) (f x y) ...
        // decode them by their first map
        if (prenode instanceof Tuple) {
            Tuple tuple = ((Tuple) prenode);
            List<Node> elements = tuple.elements;

            if (elements.isEmpty()) {
                _.abort(tuple, "syntax error");
            }

            if (delimType(tuple.open, Constants.RECORD_BEGIN)) {
                return new RecordLiteral(parseList(elements), tuple.file, tuple.start, tuple.end, tuple.line,
                        tuple.col);
            }

            if (delimType(tuple.open, Constants.ARRAY_BEGIN)) {
                return new VectorLiteral(parseList(elements), tuple.file, tuple.start, tuple.end, tuple.line,
                        tuple.col);
            }

            Node keyNode = elements.get(0);

            if (keyNode instanceof Name) {
                String keyword = ((Name) keyNode).id;

                // -------------------- sequence --------------------
                if (keyword.equals(Constants.SEQ_KEYWORD)) {
                    List<Node> statements = parseList(elements.subList(1, elements.size()));
                    return new Block(statements, prenode.file, prenode.start, prenode.end, prenode.line, prenode.col);
                }

                // -------------------- if --------------------
                if (keyword.equals(Constants.IF_KEYWORD)) {
                    if (elements.size() == 4) {
                        Node test = parseNode(elements.get(1));
                        Node conseq = parseNode(elements.get(2));
                        Node alter = parseNode(elements.get(3));
                        return new If(test, conseq, alter, prenode.file, prenode.start, prenode.end, prenode.line,
                                prenode.col);
                    }
                }

                // -------------------- definition --------------------
                if (keyword.equals(Constants.DEF_KEYWORD)) {
                    if (elements.size() == 3) {
                        Node pattern = parseNode(elements.get(1));
                        Node value = parseNode(elements.get(2));
                        return new Def(pattern, value, prenode.file, prenode.start, prenode.end, prenode.line,
                                prenode.col);
                    } else {
                        _.abort(tuple, "incorrect format of definition");
                    }
                }

                // -------------------- assignment --------------------
                if (keyword.equals(Constants.ASSIGN_KEYWORD)) {
                    if (elements.size() == 3) {
                        Node pattern = parseNode(elements.get(1));
                        Node value = parseNode(elements.get(2));
                        return new Assign(pattern, value, prenode.file, prenode.start, prenode.end, prenode.line,
                                prenode.col);
                    } else {
                        _.abort(tuple, "incorrect format of definition");
                    }
                }

                // -------------------- declare --------------------
                if (keyword.equals(Constants.DECLARE_KEYWORD)) {
                    if (elements.size() < 2) {
                        _.abort(tuple, "syntax error in record type definition");
                    }
                    Scope properties = parseProperties(elements.subList(1, elements.size()));
                    return new Declare(properties, prenode.file,
                            prenode.start, prenode.end, prenode.line, prenode.col);
                }

                // -------------------- anonymous function --------------------
                if (keyword.equals(Constants.FUN_KEYWORD)) {
                    if (elements.size() < 3) {
                        _.abort(tuple, "syntax error in function definition");
                    }

                    // construct parameter list
                    Node preParams = elements.get(1);
                    if (!(preParams instanceof Tuple)) {
                        _.abort(preParams, "incorrect format of parameters: " + preParams);
                    }

                    // parse the parameters, test whether it's all names or all tuples
                    boolean hasName = false;
                    boolean hasTuple = false;
                    List<Name> paramNames = new ArrayList<>();
                    List<Node> paramTuples = new ArrayList<>();

                    for (Node p : ((Tuple) preParams).elements) {
                        if (p instanceof Name) {
                            hasName = true;
                            paramNames.add((Name) p);
                        } else if (p instanceof Tuple) {
                            hasTuple = true;
                            List<Node> argElements = ((Tuple) p).elements;
                            if (argElements.size() == 0) {
                                _.abort(p, "illegal argument format: " + p);
                            }
                            if (!(argElements.get(0) instanceof Name)) {
                                _.abort(p, "illegal argument name : " + argElements.get(0));
                            }

                            Name name = (Name) argElements.get(0);
                            if (!name.id.equals(Constants.RETURN_ARROW)) {
                                paramNames.add(name);
                            }
                            paramTuples.add(p);
                        }
                    }

                    if (hasName && hasTuple) {
                        _.abort(preParams, "parameters must be either all names or all tuples: " + preParams);
                        return null;
                    }

                    Scope properties;
                    if (hasTuple) {
                        properties = parseProperties(paramTuples);
                    } else {
                        properties = null;
                    }

                    // construct body
                    List<Node> statements = parseList(elements.subList(2, elements.size()));
                    int start = statements.get(0).start;
                    int end = statements.get(statements.size() - 1).end;
                    Node body = new Block(statements, prenode.file, start, end, prenode.line, prenode.col);

                    return new Fun(paramNames, properties, body,
                            prenode.file, prenode.start, prenode.end, prenode.line, prenode.col);
                }

                // -------------------- record type definition --------------------
                if (keyword.equals(Constants.RECORD_KEYWORD)) {
                    if (elements.size() < 2) {
                        _.abort(tuple, "syntax error in record type definition");
                    }

                    Node name = elements.get(1);
                    Node maybeParents = elements.get(2);

                    List<Name> parents;
                    List<Node> fields;

                    if (!(name instanceof Name)) {
                        _.abort(name, "syntax error in record name: " + name);
                        return null;
                    }

                    // check if there are parents (record A (B C) ...)
                    if (maybeParents instanceof Tuple &&
                            delimType(((Tuple) maybeParents).open, Constants.TUPLE_BEGIN))
                    {
                        List<Node> parentNodes = ((Tuple) maybeParents).elements;
                        parents = new ArrayList<>();
                        for (Node p : parentNodes) {
                            if (!(p instanceof Name)) {
                                _.abort(p, "parents can only be names");
                            }
                            parents.add((Name) p);
                        }
                        fields = elements.subList(3, elements.size());
                    } else {
                        parents = null;
                        fields = elements.subList(2, elements.size());
                    }

                    Scope properties = parseProperties(fields);
                    return new RecordDef((Name) name, parents, properties, prenode.file,
                            prenode.start, prenode.end, prenode.line, prenode.col);
                }
            }

            // -------------------- application --------------------
            // must go after others because it has no keywords
            Node func = parseNode(elements.get(0));
            List<Node> parsedArgs = parseList(elements.subList(1, elements.size()));
            Argument args = new Argument(parsedArgs);
            return new Call(func, args, prenode.file, prenode.start, prenode.end, prenode.line, prenode.col);
        }

        // defaut return the node untouched
        return prenode;
    }


    public static List<Node> parseList(List<Node> prenodes) {
        List<Node> parsed = new ArrayList<>();
        for (Node s : prenodes) {
            parsed.add(parseNode(s));
        }
        return parsed;
    }


    // treat the list of nodes as key-value pairs like (:x 1 :y 2)
    public static Map<String, Node> parseMap(List<Node> prenodes) {
        Map<String, Node> ret = new LinkedHashMap<>();
        if (prenodes.size() % 2 != 0) {
            _.abort("must be of the form (:key1 value1 :key2 value2), but got: " + prenodes);
            return null;
        }

        for (int i = 0; i < prenodes.size(); i += 2) {
            Node key = prenodes.get(i);
            Node value = prenodes.get(i + 1);
            if (!(key instanceof Keyword)) {
                _.abort(key, "key must be a keyword, but got: " + key);
            }
            ret.put(((Keyword) key).id, value);
        }
        return ret;
    }


    public static Scope parseProperties(List<Node> fields) {
        Scope properties = new Scope();
        for (Node field : fields) {
            if (field instanceof Tuple &&
                    delimType(((Tuple) field).open, Constants.ARRAY_BEGIN))
            {
                List<Node> elements = parseList(((Tuple) field).elements);
                if (elements.size() < 2) {
                    _.abort(field, "empty record slot not allowed");
                }

                Node nameNode = elements.get(0);
                if (!(nameNode instanceof Name)) {
                    _.abort(nameNode, "expect field name, but got: " + nameNode);
                }
                String id = ((Name) nameNode).id;
                if (properties.containsKey(id)) {
                    _.abort(nameNode, "duplicated field name: " + nameNode);
                }

                Node typeNode = elements.get(1);
                properties.put(id, "type", typeNode);

                Map<String, Node> props = parseMap(elements.subList(2, elements.size()));
                Map<String, Object> propsObj = new LinkedHashMap<>();
                for (Map.Entry<String, Node> e : props.entrySet()) {
                    propsObj.put(e.getKey(), e.getValue());
                }
                properties.putProperties(((Name) nameNode).id, propsObj);
            }
        }
        return properties;
    }


    public static Node groupAttr(Node prenode) {
        if (prenode instanceof Tuple) {
            Tuple t = (Tuple) prenode;
            List<Node> elements = t.elements;
            List<Node> newElems = new ArrayList<>();

            if (elements.size() >= 1) {
                Node grouped = elements.get(0);
                if (delimType(grouped, Constants.ATTRIBUTE_ACCESS)) {
                    _.abort(grouped, "illegal keyword: " + grouped);
                }
                grouped = groupAttr(grouped);

                for (int i = 1; i < elements.size(); i++) {
                    Node node1 = elements.get(i);
                    if (delimType(node1, Constants.ATTRIBUTE_ACCESS)) {
                        if (i + 1 >= elements.size()) {
                            _.abort(node1, "illegal position for .");
                        }
                        Node node2 = elements.get(i + 1);
                        if (delimType(node1, Constants.ATTRIBUTE_ACCESS)) {
                            if (!(node2 instanceof Name)) {
                                _.abort(node2, "attribute is not a name");
                            }
                            grouped = new Attr(grouped, (Name) node2, grouped.file,
                                    grouped.start, node2.end, grouped.line, grouped.col);
                            i++;   // skip
                        }
                    } else {
                        newElems.add(grouped);
                        grouped = groupAttr(node1);
                    }
                }
                newElems.add(grouped);
            }
            return new Tuple(newElems, t.open, t.close, t.file, t.start, t.end, t.line, t.col);
        } else {
            return prenode;
        }
    }


    public static boolean delimType(Node c, String d) {
        return c instanceof Delimeter && ((Delimeter) c).shape.equals(d);
    }


    public static void main(String[] args) {
        Node tree = Parser.parse(args[0]);
        _.msg(tree.toString());
    }

}

package org.yinwang.rubysonar;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.rubysonar.ast.*;
import org.yinwang.rubysonar.ast.Class;
import org.yinwang.rubysonar.ast.Void;

import java.io.File;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;


public class Parser {

    private static final String RUBY_EXE = "irb";
    private static final int TIMEOUT = 30000;

    @Nullable
    Process rubyProcess;
    private static Gson gson = new GsonBuilder().setPrettyPrinting().create();
    private static final String dumpPythonResource = "org/yinwang/rubysonar/ruby/dump_ruby.rb";
    private String exchangeFile;
    private String endMark;
    private String jsonizer;
    private String parserLog;
    private String file;


    public Parser() {
        exchangeFile = _.locateTmp("json");
        endMark = _.locateTmp("end");
        jsonizer = _.locateTmp("dump_ruby");
        parserLog = _.locateTmp("parser_log");

        startRubyProcesses();
        if (rubyProcess != null) {
            _.msg("started: " + RUBY_EXE);
        }
    }


    // start or restart ruby process
    private void startRubyProcesses() {
        if (rubyProcess != null) {
            rubyProcess.destroy();
        }

        rubyProcess = startInterpreter(RUBY_EXE);

        if (rubyProcess == null) {
            _.die("You don't seem to have ruby on PATH");
        }
    }


    public void close() {
        if (!Analyzer.self.hasOption("debug")) {
            new File(jsonizer).delete();
            new File(exchangeFile).delete();
            new File(endMark).delete();
            new File(parserLog).delete();
        }
    }


    @Nullable
    public Node convert(Object o) {
        if (!(o instanceof Map) || ((Map) o).isEmpty()) {
            return null;
        }

        Map<String, Object> map = (Map<String, Object>) o;

        String type = (String) map.get("type");
        Double startDouble = (Double) map.get("start");
        Double endDouble = (Double) map.get("end");

        int start = startDouble == null ? 0 : startDouble.intValue();
        int end = endDouble == null ? 1 : endDouble.intValue();


        if (type.equals("program")) {
            return convert(map.get("body"));
        }

        if (type.equals("module")) {
            Node name = convert(map.get("name"));
            Block body = (Block) convert(map.get("body"));

            if (name instanceof Name) {
                String id = ((Name) name).id;
                if (id.startsWith("ClassMethods") || id.startsWith("InstanceMethods")) {
                    return body;
                }
            }
            Str docstring = (Str) convert(map.get("doc"));
            return new Module(name, body, docstring, file, start, end);
        }

        if (type.equals("block")) {
            List<Node> stmts = convertList(map.get("stmts"));
            return new Block(stmts, file, start, end);
        }

        if (type.equals("def") || type.equals("lambda")) {
            Node binder = convert(map.get("name"));
            Node body = convert(map.get("body"));
            Map<String, Object> argsMap = (Map<String, Object>) map.get("params");
            List<Node> positional = convertList(argsMap.get("positional"));
            List<Node> defaults = convertList(argsMap.get("defaults"));
            Name var = (Name) convert(argsMap.get("rest"));
            Name vararg = var == null ? null : var;
            Name kw = (Name) convert(argsMap.get("rest_kw"));
            Name kwarg = kw == null ? null : kw;
            List<Node> afterRest = convertList(argsMap.get("after_rest"));
            Name blockarg = (Name) convert(argsMap.get("blockarg"));
            Str docstring = (Str) convert(map.get("doc"));
            return new Function(binder, positional, body, defaults, vararg, kwarg, afterRest, blockarg,
                    docstring, file, start, end);
        }

        if (type.equals("call")) {
            Node func = convert(map.get("func"));
            Map<String, Object> args = (Map<String, Object>) map.get("args");
            Node blockarg = null;
            Node stararg = null;

            if (args != null) {
                List<Node> posKey = convertList(args.get("positional"));
                List<Node> pos = new ArrayList<>();
                List<Keyword> kws = new ArrayList<>();
                if (posKey != null) {
                    for (Node node : posKey) {
                        if (node instanceof Assign && ((Assign) node).target instanceof Name) {
                            kws.add(new Keyword(((Name) ((Assign) node).target).id,
                                    ((Assign) node).value,
                                    file,
                                    node.start,
                                    node.end));
                        } else {
                            pos.add(node);
                        }
                    }
                }
                stararg = convert(args.get("star"));
                blockarg = convert(args.get("blockarg"));
                return new Call(func, pos, kws, null, stararg, blockarg, file, start, end);
            } else {
                // call with no arguments
                return new Call(func, null, null, null, stararg, blockarg, file, start, end);
            }
        }

        if (type.equals("attribute")) {
            Node value = convert(map.get("value"));
            Name attr = (Name) convert(map.get("attr"));
            return new Attribute(value, attr, file, start, end);
        }

        if (type.equals("binary")) {
            Node left = convert(map.get("left"));
            Node right = convert(map.get("right"));
            Op op = convertOp(map.get("op"));

            // desugar complex operators
            if (op == Op.NotEqual) {
                Node eq = new BinOp(Op.Equal, left, right, file, start, end);
                return new UnaryOp(Op.Not, eq, file, start, end);
            }

            if (op == Op.NotMatch) {
                Node eq = new BinOp(Op.Match, left, right, file, start, end);
                return new UnaryOp(Op.Not, eq, file, start, end);
            }

            if (op == Op.LtE) {
                Node lt = new BinOp(Op.Lt, left, right, file, start, end);
                Node eq = new BinOp(Op.Eq, left, right, file, start, end);
                return new BinOp(Op.Or, lt, eq, file, start, end);
            }

            if (op == Op.GtE) {
                Node gt = new BinOp(Op.Gt, left, right, file, start, end);
                Node eq = new BinOp(Op.Eq, left, right, file, start, end);
                return new BinOp(Op.Or, gt, eq, file, start, end);
            }

            if (op == Op.NotIn) {
                Node in = new BinOp(Op.In, left, right, file, start, end);
                return new UnaryOp(Op.Not, in, file, start, end);
            }

            if (op == Op.NotEq) {
                Node in = new BinOp(Op.Eq, left, right, file, start, end);
                return new UnaryOp(Op.Not, in, file, start, end);
            }

            return new BinOp(op, left, right, file, start, end);

        }

        if (type.equals("void")) {
            return new Void(file, start, end);
        }


        if (type.equals("break")) {
            return new Control("break", file, start, end);
        }

        if (type.equals("retry")) {
            return new Control("retry", file, start, end);
        }

        if (type.equals("redo")) {
            return new Control("redo", file, start, end);
        }

        if (type.equals("continue")) {
            return new Control("continue", file, start, end);
        }

        if (type.equals("class")) {
            Node locator = convert(map.get("name"));
            Node base = convert(map.get("super"));
            Node body = convert(map.get("body"));
            Str docstring = (Str) convert(map.get("doc"));
            boolean isStatic = (Boolean) map.get("static");
            return new Class(locator, base, body, docstring, isStatic, file, start, end);
        }

        if (type.equals("undef")) {
            List<Node> targets = convertList(map.get("names"));
            return new Undef(targets, file, start, end);
        }

        if (type.equals("hash")) {
            List<Map<String, Object>> entries = (List<Map<String, Object>>) map.get("entries");
            List<Node> keys = new ArrayList<>();
            List<Node> values = new ArrayList<>();

            if (entries != null) {
                for (Map<String, Object> e : entries) {
                    Node k = convert(e.get("key"));
                    Node v = convert(e.get("value"));
                    if (k != null && v != null) {
                        keys.add(k);
                        values.add(v);
                    }
                }
            }
            return new Dict(keys, values, file, start, end);
        }

        if (type.equals("rescue")) {
            List<Node> exceptions = convertList(map.get("exceptions"));
            Node binder = convert(map.get("binder"));
            Node handler = convert(map.get("handler"));
            Node orelse = convert(map.get("else"));
            return new Handler(exceptions, binder, handler, orelse, file, start, end);
        }

        if (type.equals("for")) {
            Node target = convert(map.get("target"));
            Node iter = convert(map.get("iter"));
            Block body = (Block) convert(map.get("body"));
            return new For(target, iter, body, null, file, start, end);
        }

        if (type.equals("if")) {
            Node test = convert(map.get("test"));
            Node body = convert(map.get("body"));
            Node orelse = convert(map.get("else"));
            return new If(test, body, orelse, file, start, end);
        }

        if (type.equals("keyword")) {
            String arg = (String) map.get("arg");
            Node value = convert(map.get("value"));
            return new Keyword(arg, value, file, start, end);
        }

        if (type.equals("array")) {
            List<Node> elts = convertList(map.get("elts"));
            if (elts == null) {
                elts = Collections.emptyList();
            }
            return new Array(elts, file, start, end);
        }

        if (type.equals("args")) {
            List<Node> elts = convertList(map.get("positional"));
            if (elts != null) {
                return new Array(elts, file, start, end);
            } else {
                elts = convertList(map.get("star"));
                if (elts != null) {
                    return new Array(elts, file, start, end);
                } else {
                    return new Array(Collections.<Node>emptyList(), file, start, end);
                }
            }
        }

        if (type.equals("dot2") || type.equals("dot3")) {
            Node from = convert(map.get("from"));
            Node to = convert(map.get("to"));
            List<Node> elts = new ArrayList<>();
            elts.add(from);
            elts.add(to);
            return new Array(elts, file, start, end);
        }

        if (type.equals("star")) { // f(*[1, 2, 3, 4])
            Node value = convert(map.get("value"));
            return new Starred(value, file, start, end);
        }

        // another name for Name in Python3 func parameters?
        if (type.equals("arg")) {
            String id = (String) map.get("arg");
            return new Name(id, file, start, end);
        }

        if (type.equals("return")) {
            Node value = convert(map.get("value"));
            return new Return(value, file, start, end);
        }

        if (type.equals("string")) {
            String s = (String) map.get("id");
            return new Str(s, file, start, end);
        }

        if (type.equals("string_embexpr")) {
            Node value = convert(map.get("value"));
            return new StrEmbed(value, file, start, end);
        }

        if (type.equals("regexp")) {
            Node pattern = convert(map.get("pattern"));
            Node regexp_end = convert(map.get("regexp_end"));
            return new Regexp(pattern, regexp_end, file, start, end);
        }

        // Ruby's subscript is Python's Slice with step size 1
        if (type.equals("subscript")) {
            Node value = convert(map.get("value"));
            Object sliceObj = map.get("slice");

            if (sliceObj instanceof List) {
                List<Node> s = convertList(sliceObj);
                if (s.size() == 1) {
                    Node node = s.get(0);
                    Index idx = new Index(node, file, node.start, node.end);
                    return new Subscript(value, idx, file, start, end);
                } else if (s.size() == 2) {
                    Slice slice = new Slice(s.get(0), null, s.get(1), file, s.get(0).start, s.get(1).end);
                    return new Subscript(value, slice, file, start, end);
                } else {
                    // failed to parse the subscript part
                    // cheat by returning the value
                    return value;
                }
            } else if (sliceObj == null) {
                return new Subscript(value, null, file, start, end);
            } else {
                Node sliceNode = convert(sliceObj);
                return new Subscript(value, sliceNode, file, start, end);
            }
        }

        if (type.equals("begin")) {
            Node body = convert(map.get("body"));
            Node rescue = convert(map.get("rescue"));
            Node orelse = convert(map.get("else"));
            Node finalbody = convert(map.get("ensure"));
            return new Try(rescue, body, orelse, finalbody, file, start, end);
        }

        if (type.equals("unary")) {
            Op op = convertOp(map.get("op"));
            Node operand = convert(map.get("operand"));
            return new UnaryOp(op, operand, file, start, end);
        }

        if (type.equals("while")) {
            Node test = convert(map.get("test"));
            Node body = convert(map.get("body"));
            return new While(test, body, null, file, start, end);
        }

        if (type.equals("yield")) {
            Node value = convert(map.get("value"));
            return new Yield(value, file, start, end);
        }

        if (type.equals("assign")) {
            Node target = convert(map.get("target"));
            Node value = convert(map.get("value"));
            return new Assign(target, value, file, start, end);
        }

        if (type.equals("name")) {
            String id = (String) map.get("id");
            return new Name(id, file, start, end);
        }

        if (type.equals("cvar")) {
            String id = (String) map.get("id");
            return new Name(id, NameType.CLASS, file, start, end);
        }

        if (type.equals("ivar")) {
            String id = (String) map.get("id");
            return new Name(id, NameType.INSTANCE, file, start, end);
        }

        if (type.equals("gvar")) {
            String id = (String) map.get("id");
            return new Name(id, NameType.GLOBAL, file, start, end);
        }

        if (type.equals("symbol")) {
            String id = (String) map.get("id");
            return new Symbol(id, file, start, end);
        }

        if (type.equals("int")) {
            String n = (String) map.get("value");
            return new RbInt(n, file, start, end);
        }

        if (type.equals("float")) {
            String n = (String) map.get("value");
            return new RbFloat(n, file, start, end);
        }

        _.die("[please report parser bug]: unexpected ast node: " + type);
        return null;
    }


    @Nullable
    private <T> List<T> convertList(@Nullable Object o) {
        if (o == null) {
            return null;
        } else {
            List<Map<String, Object>> in = (List<Map<String, Object>>) o;
            List<T> out = new ArrayList<>();

            for (Object x : (List) in) {
                if (!(x instanceof Map)) {
                    _.die("not a map: " + x);
                }
            }

            for (Map<String, Object> m : in) {
                Node n = convert(m);
                if (n != null) {
                    out.add((T) n);
                }
            }

            return out;
        }
    }


    public Op convertOp(Object map) {
        String name = (String) ((Map<String, Object>) map).get("name");

        if (name.equals("+") || name.equals("+@")) {
            return Op.Add;
        }

        if (name.equals("-") || name.equals("-@") || name.equals("<=>")) {
            return Op.Sub;
        }

        if (name.equals("*")) {
            return Op.Mul;
        }

        if (name.equals("/")) {
            return Op.Div;
        }

        if (name.equals("**")) {
            return Op.Pow;
        }

        if (name.equals("=~")) {
            return Op.Match;
        }

        if (name.equals("!~")) {
            return Op.NotMatch;
        }

        if (name.equals("==") || name.equals("===")) {
            return Op.Equal;
        }

        if (name.equals("<")) {
            return Op.Lt;
        }

        if (name.equals(">")) {
            return Op.Gt;
        }


        if (name.equals("&")) {
            return Op.BitAnd;
        }

        if (name.equals("|")) {
            return Op.BitOr;
        }

        if (name.equals("^")) {
            return Op.BitXor;
        }


        if (name.equals("in")) {
            return Op.In;
        }


        if (name.equals("<<")) {
            return Op.LShift;
        }

        if (name.equals("%")) {
            return Op.Mod;
        }

        if (name.equals(">>")) {
            return Op.RShift;
        }

        if (name.equals("~")) {
            return Op.Invert;
        }

        if (name.equals("and") || name.equals("&&")) {
            return Op.And;
        }

        if (name.equals("or") || name.equals("||")) {
            return Op.Or;
        }

        if (name.equals("not") || name.equals("!")) {
            return Op.Not;
        }

        if (name.equals("!=")) {
            return Op.NotEqual;
        }

        if (name.equals("<=")) {
            return Op.LtE;
        }

        if (name.equals(">=")) {
            return Op.GtE;
        }

        if (name.equals("defined")) {
            return Op.Defined;
        }

        _.die("illegal operator: " + name);
        return null;
    }


    public String prettyJson(String json) {
        Map<String, Object> obj = gson.fromJson(json, Map.class);
        return gson.toJson(obj);
    }


    @Nullable
    public Process startInterpreter(String interpExe) {
        String jsonizeStr;
        Process p;

        try {
            InputStream jsonize =
                    Thread.currentThread()
                            .getContextClassLoader()
                            .getResourceAsStream(dumpPythonResource);
            jsonizeStr = _.readWholeStream(jsonize);
        } catch (Exception e) {
            _.die("Failed to open resource file:" + dumpPythonResource);
            return null;
        }

        try {
            FileWriter fw = new FileWriter(jsonizer);
            fw.write(jsonizeStr);
            fw.close();
        } catch (Exception e) {
            _.die("Failed to write into: " + jsonizer);
            return null;
        }

        try {
            ProcessBuilder builder = new ProcessBuilder(interpExe);
            builder.redirectErrorStream(true);
            builder.redirectError(new File(parserLog));
            builder.redirectOutput(new File(parserLog));
            builder.environment().remove("RUBYLIB");
            p = builder.start();
        } catch (Exception e) {
            _.die("Failed to start irb");
            return null;
        }

        if (!sendCommand("load '" + jsonizer + "'", p)) {
            _.die("Failed to load jsonizer, please report bug");
            p.destroy();
            return null;
        }

        return p;
    }


    @Nullable
    public Node parseFile(String filename) {
        file = filename;
        Node node = parseFileInner(filename, rubyProcess);
        if (node != null) {
            return node;
        } else {
//            _.msg("failed to parse: " + filename);

            Analyzer.self.failedToParse.add(filename);
            return null;
        }
    }


    @Nullable
    public Node parseFileInner(String filename, @NotNull Process rubyProcess) {
//        _.msg("parsing: " + filename);

        cleanTemp();

        String s1 = _.escapeWindowsPath(filename);
        String s2 = _.escapeWindowsPath(exchangeFile);
        String s3 = _.escapeWindowsPath(endMark);
        String dumpCommand = "parse_dump('" + s1 + "', '" + s2 + "', '" + s3 + "')";

        if (!sendCommand(dumpCommand, rubyProcess)) {
            cleanTemp();
            return null;
        }

        long waitStart = System.currentTimeMillis();
        File marker = new File(endMark);

        while (!marker.exists()) {
            if (System.currentTimeMillis() - waitStart > TIMEOUT) {
                _.msg("\nTimed out while parsing: " + filename);
                cleanTemp();
                startRubyProcesses();
                return null;
            }

            try {
                Thread.sleep(1);
            } catch (Exception e) {
                cleanTemp();
                return null;
            }
        }

        String json;
        try {
            json = _.readFile(exchangeFile);
        } catch (Exception e) {
            cleanTemp();
            return null;
        }

        cleanTemp();

        Map<String, Object> map = gson.fromJson(json, Map.class);
        return convert(map);
    }


    private boolean sendCommand(String cmd, @NotNull Process rubyProcess) {
        try {
            OutputStreamWriter writer = new OutputStreamWriter(rubyProcess.getOutputStream());
            writer.write(cmd);
            writer.write("\n");
            writer.flush();
            return true;
        } catch (Exception e) {
            _.msg("\nFailed to send command to Ruby interpreter: " + cmd);
            return false;
        }
    }


    private void cleanTemp() {
        new File(exchangeFile).delete();
        new File(endMark).delete();
    }


    public static void main(String[] args) {
        Parser parser = new Parser();
        parser.parseFile(args[0]);
    }

}

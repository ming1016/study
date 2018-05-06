package org.yinwang.pysonar;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import org.apache.commons.io.FileUtils;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.ast.*;

import java.io.File;
import java.io.OutputStreamWriter;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


public class Parser {

    private static final String PYTHON2_EXE = "python";
    private static final String PYTHON3_EXE = "python3";
    private static final int TIMEOUT = 10000;

    Process python2Process;
    Process python3Process;
    private static Gson gson = new GsonBuilder().setPrettyPrinting().create();
    private static final String dumpPythonResource = "org/yinwang/pysonar/python/dump_python.py";
    private String exchangeFile;
    private String endMark;
    private String jsonizer;
    private String parserLog;
    private String file;
    private String content;


    public Parser() {

        exchangeFile = _.locateTmp("json");
        endMark = _.locateTmp("end");
        jsonizer = _.locateTmp("dump_python");
        parserLog = _.locateTmp("parser_log");

        startPythonProcesses();

        if (python2Process != null) {
            _.msg("started: " + PYTHON2_EXE);
        }

        if (python3Process != null) {
            _.msg("started: " + PYTHON3_EXE);
        }
    }


    // start or restart python processes
    private void startPythonProcesses() {
        if (python2Process != null) {
            python2Process.destroy();
        }
        if (python3Process != null) {
            python3Process.destroy();
        }

        // copy dump_python.py to temp dir
        try {
            URL url = Thread.currentThread().getContextClassLoader().getResource(dumpPythonResource);
            FileUtils.copyURLToFile(url, new File(jsonizer));
        } catch (Exception e) {
            _.die("Failed to copy resource file:" + dumpPythonResource);
        }

        python2Process = startInterpreter(PYTHON2_EXE);
        python3Process = startInterpreter(PYTHON3_EXE);
        if (python2Process == null && python3Process == null) {
            _.die("You don't seem to have either of Python or Python3 on PATH");
        }
    }


    public void close() {
        if (!Analyzer.self.hasOption("debug")) {
            new File(exchangeFile).delete();
            new File(endMark).delete();
            new File(jsonizer).delete();
            new File(parserLog).delete();
        }
    }


    @Nullable
    public Node convert(Object o) {
        if (!(o instanceof Map)) {
            return null;
        }

        Map<String, Object> map = (Map<String, Object>) o;

        String type = (String) map.get("type");
        Double startDouble = (Double) map.get("start");
        Double endDouble = (Double) map.get("end");

        int start = startDouble == null ? 0 : startDouble.intValue();
        int end = endDouble == null ? 1 : endDouble.intValue();


        if (type.equals("Module")) {
            Block b = convertBlock(map.get("body"));
            return new Module(b, file, start, end);
        }

        if (type.equals("alias")) {         // lower case alias
            String qname = (String) map.get("name");
            List<Name> names = segmentQname(qname, start + "import ".length(), false);
            Name asname = map.get("asname") == null ? null : new Name((String) map.get("asname"));
            return new Alias(names, asname, file, start, end);
        }

        if (type.equals("Assert")) {
            Node test = convert(map.get("test"));
            Node msg = convert(map.get("msg"));
            return new Assert(test, msg, file, start, end);
        }

        // assign could be x=y=z=1
        // turn it into one or more Assign nodes
        // z = 1; y = z; x = z
        if (type.equals("Assign")) {
            List<Node> targets = convertList(map.get("targets"));
            Node value = convert(map.get("value"));
            if (targets.size() == 1) {
                return new Assign(targets.get(0), value, file, start, end);
            } else {
                List<Node> assignments = new ArrayList<>();
                Node lastTarget = targets.get(targets.size() - 1);
                assignments.add(new Assign(lastTarget, value, file, start, end));

                for (int i = targets.size() - 2; i >= 0; i--) {
                    Node nextAssign = new Assign(targets.get(i), lastTarget, file, start, end);
                    assignments.add(nextAssign);
                }

                return new Block(assignments, file, start, end);
            }
        }

        if (type.equals("Attribute")) {
            Node value = convert(map.get("value"));
            Name attr = (Name) convert(map.get("attr_name"));
            if (attr == null) {
                attr = new Name((String) map.get("attr"));
            }
            return new Attribute(value, attr, file, start, end);
        }

        if (type.equals("AugAssign")) {
            Node target = convert(map.get("target"));
            Node value = convert(map.get("value"));
            Op op = convertOp(map.get("op"));
            Node operation = new BinOp(op, target, value, file, target.start, value.end);
            return new Assign(target, operation, file, start, end);
        }

        if (type.equals("BinOp")) {
            Node left = convert(map.get("left"));
            Node right = convert(map.get("right"));
            Op op = convertOp(map.get("op"));

            // desugar complex operators
            if (op == Op.NotEqual) {
                Node eq = new BinOp(Op.Equal, left, right, file, start, end);
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

        if (type.equals("BoolOp")) {
            List<Node> values = convertList(map.get("values"));
            if (values == null || values.size() < 2) {
                _.die("impossible number of arguments, please fix the Python parser");
            }
            Op op = convertOp(map.get("op"));
            BinOp ret = new BinOp(op, values.get(0), values.get(1), file, start, end);
            for (int i = 2; i < values.size(); i++) {
                ret = new BinOp(op, ret, values.get(i), file, start, end);
            }
            return ret;
        }

        if (type.equals("Bytes")) {
            Object s = map.get("s");
            return new Bytes(s, file, start, end);
        }

        if (type.equals("Call")) {
            Node func = convert(map.get("func"));
            List<Node> args = convertList(map.get("args"));
            List<Keyword> keywords = convertList(map.get("keywords"));
            Node kwargs = convert(map.get("kwarg"));
            Node starargs = convert(map.get("starargs"));
            return new Call(func, args, keywords, kwargs, starargs, file, start, end);
        }

        if (type.equals("ClassDef")) {
            Name name = (Name) convert(map.get("name_node"));      // hack
            List<Node> bases = convertList(map.get("bases"));
            Block body = convertBlock(map.get("body"));
            return new ClassDef(name, bases, body, file, start, end);
        }

        // left-fold Compare into
        if (type.equals("Compare")) {
            Node left = convert(map.get("left"));
            List<Op> ops = convertListOp(map.get("ops"));
            List<Node> comparators = convertList(map.get("comparators"));
            Node result = new BinOp(ops.get(0), left, comparators.get(0), file, start, end);
            for (int i = 1; i < comparators.size(); i++) {
                Node compNext = new BinOp(ops.get(i), comparators.get(i - 1), comparators.get(i), file, start, end);
                result = new BinOp(Op.And, result, compNext, file, start, end);
            }
            return result;
        }

        if (type.equals("comprehension")) {
            Node target = convert(map.get("target"));
            Node iter = convert(map.get("iter"));
            List<Node> ifs = convertList(map.get("ifs"));
            return new Comprehension(target, iter, ifs, file, start, end);
        }

        if (type.equals("Break")) {
            return new Break(file, start, end);
        }

        if (type.equals("Continue")) {
            return new Continue(file, start, end);
        }

        if (type.equals("Delete")) {
            List<Node> targets = convertList(map.get("targets"));
            return new Delete(targets, file, start, end);
        }

        if (type.equals("Dict")) {
            List<Node> keys = convertList(map.get("keys"));
            List<Node> values = convertList(map.get("values"));
            return new Dict(keys, values, file, start, end);
        }

        if (type.equals("DictComp")) {
            Node key = convert(map.get("key"));
            Node value = convert(map.get("value"));
            List<Comprehension> generators = convertList(map.get("generators"));
            return new DictComp(key, value, generators, file, start, end);
        }

        if (type.equals("Ellipsis")) {
            return new Ellipsis(file, start, end);
        }

        if (type.equals("ExceptHandler")) {
            Node exception = convert(map.get("type"));
            List<Node> exceptions;

            if (exception != null) {
                exceptions = new ArrayList<>();
                exceptions.add(exception);
            } else {
                exceptions = null;
            }

            Node binder = convert(map.get("name"));
            Block body = convertBlock(map.get("body"));
            return new Handler(exceptions, binder, body, file, start, end);
        }

        if (type.equals("Exec")) {
            Node body = convert(map.get("body"));
            Node globals = convert(map.get("globals"));
            Node locals = convert(map.get("locals"));
            return new Exec(body, globals, locals, file, start, end);
        }

        if (type.equals("Expr")) {
            Node value = convert(map.get("value"));
            return new Expr(value, file, start, end);
        }

        if (type.equals("For")) {
            Node target = convert(map.get("target"));
            Node iter = convert(map.get("iter"));
            Block body = convertBlock(map.get("body"));
            Block orelse = convertBlock(map.get("orelse"));
            return new For(target, iter, body, orelse, file, start, end);
        }

        if (type.equals("FunctionDef") || type.equals("Lambda")) {
            Name name = type.equals("Lambda") ? null : (Name) convert(map.get("name_node"));
            Map<String, Object> argsMap = (Map<String, Object>) map.get("args");
            List<Node> args = convertList(argsMap.get("args"));
            List<Node> defaults = convertList(argsMap.get("defaults"));
            Node body = type.equals("Lambda") ? convert(map.get("body")) : convertBlock(map.get("body"));

            // handle vararg depending on different python versions
            Name vararg = null;
            Object varargObj = argsMap.get("vararg");
            if (varargObj instanceof String) {
                vararg = new Name((String) argsMap.get("vararg"));
            } else if (varargObj instanceof Map) {
                String argName = (String) ((Map) varargObj).get("arg");
                vararg = new Name(argName);
            }

            // handle kwarg depending on different python versions
            Name kwarg = null;
            Object kwargObj = argsMap.get("kwarg");
            if (kwargObj instanceof String) {
                kwarg = new Name((String) argsMap.get("kwarg"));
            } else if (kwargObj instanceof Map) {
                String argName = (String) ((Map) kwargObj).get("arg");
                kwarg = new Name(argName);
            }

            return new FunctionDef(name, args, body, defaults, vararg, kwarg, file, start, end);
        }

        if (type.equals("GeneratorExp")) {
            Node elt = convert(map.get("elt"));
            List<Comprehension> generators = convertList(map.get("generators"));
            return new GeneratorExp(elt, generators, file, start, end);
        }

        if (type.equals("Global")) {
            List<String> names = (List<String>) map.get("names");
            List<Name> nameNodes = new ArrayList<>();
            for (String name : names) {
                nameNodes.add(new Name(name));
            }
            return new Global(nameNodes, file, start, end);
        }

        if (type.equals("Nonlocal")) {
            List<String> names = (List<String>) map.get("names");
            List<Name> nameNodes = new ArrayList<>();
            for (String name : names) {
                nameNodes.add(new Name(name));
            }
            return new Global(nameNodes, file, start, end);
        }

        if (type.equals("If")) {
            Node test = convert(map.get("test"));
            Block body = convertBlock(map.get("body"));
            Block orelse = convertBlock(map.get("orelse"));
            return new If(test, body, orelse, file, start, end);
        }

        if (type.equals("IfExp")) {
            Node test = convert(map.get("test"));
            Node body = convert(map.get("body"));
            Node orelse = convert(map.get("orelse"));
            return new IfExp(test, body, orelse, file, start, end);
        }


        if (type.equals("Import")) {
            List<Alias> aliases = convertList(map.get("names"));
            locateNames(aliases, start);
            return new Import(aliases, file, start, end);
        }

        if (type.equals("ImportFrom")) {
            String module = (String) map.get("module");
            int level = ((Double) map.get("level")).intValue();
            List<Name> moduleSeg = module == null ? null : segmentQname(module, start + "from ".length() + level, true);
            List<Alias> names = convertList(map.get("names"));
            locateNames(names, start);
            return new ImportFrom(moduleSeg, names, level, file, start, end);
        }

        if (type.equals("Index")) {
            Node value = convert(map.get("value"));
            return new Index(value, file, start, end);
        }

        if (type.equals("keyword")) {
            String arg = (String) map.get("arg");
            Node value = convert(map.get("value"));
            return new Keyword(arg, value, file, start, end);
        }

        if (type.equals("List")) {
            List<Node> elts = convertList(map.get("elts"));
            return new PyList(elts, file, start, end);
        }

        if (type.equals("Starred")) { // f(*[1, 2, 3, 4])
            Node value = convert(map.get("value"));
            return new Starred(value, file, start, end);
        }

        if (type.equals("ListComp")) {
            Node elt = convert(map.get("elt"));
            List<Comprehension> generators = convertList(map.get("generators"));
            return new ListComp(elt, generators, file, start, end);
        }

        if (type.equals("Name")) {
            String id = (String) map.get("id");
            return new Name(id, file, start, end);
        }

        if (type.equals("NameConstant")) {
            String strVal;
            Object value = map.get("value");
            if (value instanceof Boolean) {
                strVal = ((Boolean) value) ? "true" : "false";
            } else if (value instanceof String) {
                strVal = (String) value;
            } else {
                _.msg("[WARNING] NameConstant contains unrecognized value: " + value + ", please report issue");
                strVal = "";
            }
            return new Name(strVal, file, start, end);
        }

        // another name for Name in Python3 func parameters?
        if (type.equals("arg")) {
            String id = (String) map.get("arg");
            return new Name(id, file, start, end);
        }

        if (type.equals("Num")) {

            String num_type = (String) map.get("num_type");
            if (num_type.equals("int")) {
                return new PyInt((String) map.get("n"), file, start, end);
            } else if (num_type.equals("float")) {
                return new PyFloat((String) map.get("n"), file, start, end);
            } else {
                Object real = map.get("real");
                Object imag = map.get("imag");

                if (real instanceof String) {
                    if (real.equals("Infinity")) {
                        real = Double.POSITIVE_INFINITY;
                    } else if (real.equals("-Infinity")) {
                        real = Double.NEGATIVE_INFINITY;
                    }
                }
                if (imag instanceof String) {
                    if (imag.equals("Infinity")) {
                        imag = Double.POSITIVE_INFINITY;
                    } else if (real.equals("-Infinity")) {
                        imag = Double.NEGATIVE_INFINITY;
                    }
                }
                return new PyComplex((double) real, (double) imag, file, start, end);
            }
        }

        if (type.equals("SetComp")) {
            Node elt = convert(map.get("elt"));
            List<Comprehension> generators = convertList(map.get("generators"));
            return new SetComp(elt, generators, file, start, end);
        }

        if (type.equals("Pass")) {
            return new Pass(file, start, end);
        }

        if (type.equals("Print")) {
            List<Node> values = convertList(map.get("values"));
            Node destination = convert(map.get("destination"));
            return new Print(destination, values, file, start, end);
        }

        if (type.equals("Raise")) {
            Node exceptionType = convert(map.get("type"));
            Node inst = convert(map.get("inst"));
            Node tback = convert(map.get("tback"));
            return new Raise(exceptionType, inst, tback, file, start, end);
        }

        if (type.equals("Repr")) {
            Node value = convert(map.get("value"));
            return new Repr(value, file, start, end);
        }

        if (type.equals("Return")) {
            Node value = convert(map.get("value"));
            return new Return(value, file, start, end);
        }

        if (type.equals("Set")) {
            List<Node> elts = convertList(map.get("elts"));
            return new PySet(elts, file, start, end);
        }

        if (type.equals("SetComp")) {
            Node elt = convert(map.get("elt"));
            List<Comprehension> generators = convertList(map.get("generators"));
            return new SetComp(elt, generators, file, start, end);
        }

        if (type.equals("Slice")) {
            Node lower = convert(map.get("lower"));
            Node step = convert(map.get("step"));
            Node upper = convert(map.get("upper"));
            return new Slice(lower, step, upper, file, start, end);
        }

        if (type.equals("ExtSlice")) {
            List<Node> dims = convertList(map.get("dims"));
            return new ExtSlice(dims, file, start, end);
        }

        if (type.equals("Str")) {
            String s = (String) map.get("s");
            return new Str(s, file, start, end);
        }

        if (type.equals("Subscript")) {
            Node value = convert(map.get("value"));
            Node slice = convert(map.get("slice"));
            return new Subscript(value, slice, file, start, end);
        }

        if (type.equals("Try")) {
            Block body = convertBlock(map.get("body"));
            Block orelse = convertBlock(map.get("orelse"));
            List<Handler> handlers = convertList(map.get("handlers"));
            Block finalbody = convertBlock(map.get("finalbody"));
            return new Try(handlers, body, orelse, finalbody, file, start, end);
        }

        if (type.equals("TryExcept")) {
            Block body = convertBlock(map.get("body"));
            Block orelse = convertBlock(map.get("orelse"));
            List<Handler> handlers = convertList(map.get("handlers"));
            return new Try(handlers, body, orelse, null, file, start, end);
        }

        if (type.equals("TryFinally")) {
            Block body = convertBlock(map.get("body"));
            Block finalbody = convertBlock(map.get("finalbody"));
            return new Try(null, body, null, finalbody, file, start, end);
        }

        if (type.equals("Tuple")) {
            List<Node> elts = convertList(map.get("elts"));
            return new Tuple(elts, file, start, end);
        }

        if (type.equals("UnaryOp")) {
            Op op = convertOp(map.get("op"));
            Node operand = convert(map.get("operand"));
            return new UnaryOp(op, operand, file, start, end);
        }

        if (type.equals("While")) {
            Node test = convert(map.get("test"));
            Block body = convertBlock(map.get("body"));
            Block orelse = convertBlock(map.get("orelse"));
            return new While(test, body, orelse, file, start, end);
        }

        if (type.equals("With")) {
            List<Withitem> items = new ArrayList<>();

            Node context_expr = convert(map.get("context_expr"));
            Node optional_vars = convert(map.get("optional_vars"));
            Block body = convertBlock(map.get("body"));

            // Python 3 puts context_expr and optional_vars inside "items"
            if (context_expr != null) {
                Withitem item = new Withitem(context_expr, optional_vars, file, -1, -1);
                items.add(item);
            } else {
                List<Map<String, Object>> itemsMap = (List<Map<String, Object>>) map.get("items");

                for (Map<String, Object> m : itemsMap) {
                    context_expr = convert(m.get("context_expr"));
                    optional_vars = convert(m.get("optional_vars"));
                    Withitem item = new Withitem(context_expr, optional_vars, file, -1, -1);
                    items.add(item);
                }
            }

            return new With(items, body, file, start, end);
        }

        if (type.equals("Yield")) {
            Node value = convert(map.get("value"));
            return new Yield(value, file, start, end);
        }

        if (type.equals("YieldFrom")) {
            Node value = convert(map.get("value"));
            return new Yield(value, file, start, end);
        }

        _.die("[Please report bug]: unexpected ast node: " + map.get("type"));

        return null;
    }


    @Nullable
    private <T> List<T> convertList(@Nullable Object o) {
        if (o == null) {
            return null;
        } else {
            List<Map<String, Object>> in = (List<Map<String, Object>>) o;
            List<T> out = new ArrayList<>();

            for (Map<String, Object> m : in) {
                Node n = convert(m);
                if (n != null) {
                    out.add((T) n);
                }
            }

            return out;
        }
    }


    // cpython ast doesn't have location information for names in the Alias node, thus we need to locate it here.
    private void locateNames(List<Alias> names, int start) {
        for (Alias a : names) {
            Name first = a.name.get(0);
            start = content.indexOf(first.id, start);
            first.start = start;
            first.end = start + first.id.length();
            start = first.end;
            if (a.asname != null) {
                start = content.indexOf(a.asname.id, start);
                a.asname.start = start;
                a.asname.end = start + a.asname.id.length();
                a.asname.file = file;  // file is missing for asname node
                start = a.asname.end;
            }
        }
    }


    @Nullable
    private List<Node> convertListNode(@Nullable Object o) {
        if (o == null) {
            return null;
        } else {
            List<Map<String, Object>> in = (List<Map<String, Object>>) o;
            List<Node> out = new ArrayList<>();

            for (Map<String, Object> m : in) {
                Node n = convert(m);
                if (n != null) {
                    out.add(n);
                }
            }

            return out;
        }
    }


    @Nullable
    private Block convertBlock(@Nullable Object o) {
        if (o == null) {
            return null;
        } else {
            List<Node> body = convertListNode(o);
            if (body == null || body.isEmpty()) {
                return null;
            } else {
                return new Block(body, file, 0, 0);
            }
        }
    }


    @Nullable
    private List<Op> convertListOp(@Nullable Object o) {
        if (o == null) {
            return null;
        } else {
            List<Map<String, Object>> in = (List<Map<String, Object>>) o;
            List<Op> out = new ArrayList<>();

            for (Map<String, Object> m : in) {
                Op n = convertOp(m);
                if (n != null) {
                    out.add(n);
                }
            }

            return out;
        }
    }


    public Op convertOp(Object map) {
        String type = (String) ((Map<String, Object>) map).get("type");

        if (type.equals("Add") || type.equals("UAdd")) {
            return Op.Add;
        }

        if (type.equals("Sub") || type.equals("USub")) {
            return Op.Sub;
        }

        if (type.equals("Mult")) {
            return Op.Mul;
        }

        if (type.equals("Div")) {
            return Op.Div;
        }

        if (type.equals("Pow")) {
            return Op.Pow;
        }

        if (type.equals("Eq")) {
            return Op.Equal;
        }

        if (type.equals("Is")) {
            return Op.Eq;
        }

        if (type.equals("Lt")) {
            return Op.Lt;
        }

        if (type.equals("Gt")) {
            return Op.Gt;
        }


        if (type.equals("BitAnd")) {
            return Op.BitAnd;
        }

        if (type.equals("BitOr")) {
            return Op.BitOr;
        }

        if (type.equals("BitXor")) {
            return Op.BitXor;
        }


        if (type.equals("In")) {
            return Op.In;
        }


        if (type.equals("LShift")) {
            return Op.LShift;
        }

        if (type.equals("FloorDiv")) {
            return Op.FloorDiv;
        }

        if (type.equals("Mod")) {
            return Op.Mod;
        }

        if (type.equals("RShift")) {
            return Op.RShift;
        }

        if (type.equals("Invert")) {
            return Op.Invert;
        }

        if (type.equals("And")) {
            return Op.And;
        }

        if (type.equals("Or")) {
            return Op.Or;
        }

        if (type.equals("Not")) {
            return Op.Not;
        }

        if (type.equals("NotEq")) {
            return Op.NotEqual;
        }

        if (type.equals("IsNot")) {
            return Op.NotEq;
        }

        if (type.equals("LtE")) {
            return Op.LtE;
        }

        if (type.equals("GtE")) {
            return Op.GtE;
        }

        if (type.equals("NotIn")) {
            return Op.NotIn;
        }

        _.die("illegal operator: " + type);
        return null;
    }


    @NotNull
    List<Name> segmentQname(@NotNull String qname, int start, boolean hasLoc) {
        List<Name> result = new ArrayList<>();

        for (int i = 0; i < qname.length(); i++) {
            String name = "";
            while (Character.isSpaceChar(qname.charAt(i))) {
                i++;
            }
            int nameStart = i;

            while (i < qname.length() &&
                    (Character.isJavaIdentifierPart(qname.charAt(i)) ||
                            qname.charAt(i) == '*') &&
                    qname.charAt(i) != '.')
            {
                name += qname.charAt(i);
                i++;
            }

            int nameStop = i;
            int nstart = hasLoc ? start + nameStart : -1;
            int nstop = hasLoc ? start + nameStop : -1;
            result.add(new Name(name, file, nstart, nstop));
        }

        return result;
    }


    public String prettyJson(String json) {
        Map<String, Object> obj = gson.fromJson(json, Map.class);
        return gson.toJson(obj);
    }


    @Nullable
    public Process startInterpreter(String pythonExe) {
        Process p;
        try {
            ProcessBuilder builder = new ProcessBuilder(pythonExe, "-i", jsonizer);
            builder.redirectErrorStream(true);
            builder.redirectError(new File(parserLog));
            builder.redirectOutput(new File(parserLog));
            builder.environment().remove("PYTHONPATH");
            p = builder.start();
        } catch (Exception e) {
            _.msg("Failed to start: " + pythonExe);
            return null;
        }
        return p;
    }


    @Nullable
    public Node parseFile(String filename) {
        file = filename;
        content = _.readFile(filename);

        Node node2 = parseFileInner(filename, python2Process);
        if (node2 != null) {
            return node2;
        } else if (python3Process != null) {
            Node node3 = parseFileInner(filename, python3Process);
            if (node3 == null) {
                _.msg("failed to parse: " + filename);
                Analyzer.self.failedToParse.add(filename);
                return null;
            } else {
                return node3;
            }
        } else {
            _.msg("failed to parse: " + filename);
            Analyzer.self.failedToParse.add(filename);
            return null;
        }
    }


    @Nullable
    public Node parseFileInner(String filename, @NotNull Process pythonProcess) {
//        _.msg("parsing: " + filename);

        File exchange = new File(exchangeFile);
        File marker = new File(endMark);
        cleanTemp();

        String s1 = _.escapeWindowsPath(filename);
        String s2 = _.escapeWindowsPath(exchangeFile);
        String s3 = _.escapeWindowsPath(endMark);
        String dumpCommand = "parse_dump('" + s1 + "', '" + s2 + "', '" + s3 + "')";

        if (!sendCommand(dumpCommand, pythonProcess)) {
            cleanTemp();
            return null;
        }

        long waitStart = System.currentTimeMillis();
        while (!marker.exists()) {
            if (System.currentTimeMillis() - waitStart > TIMEOUT) {
                _.msg("\nTimed out while parsing: " + filename);
                cleanTemp();
                startPythonProcesses();
                return null;
            }

            try {
                Thread.sleep(1);
            } catch (Exception e) {
                cleanTemp();
                return null;
            }
        }

        String json = _.readFile(exchangeFile);
        if (json != null) {
            cleanTemp();
            Map<String, Object> map = gson.fromJson(json, Map.class);
            return convert(map);
        } else {
            cleanTemp();
            return null;
        }
    }


    private void cleanTemp() {
        new File(exchangeFile).delete();
        new File(endMark).delete();
    }


    private boolean sendCommand(String cmd, @NotNull Process pythonProcess) {
        try {
            OutputStreamWriter writer = new OutputStreamWriter(pythonProcess.getOutputStream());
            writer.write(cmd);
            writer.write("\n");
            writer.flush();
            return true;
        } catch (Exception e) {
            _.msg("\nFailed to send command to interpreter: " + cmd);
            return false;
        }
    }

}

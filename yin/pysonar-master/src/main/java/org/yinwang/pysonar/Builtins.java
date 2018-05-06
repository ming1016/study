package org.yinwang.pysonar;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.ast.Url;
import org.yinwang.pysonar.types.*;

import java.util.HashMap;
import java.util.Map;

import static org.yinwang.pysonar.Binding.Kind.*;

/**
 * This file is messy. Should clean up.
 */
public class Builtins {

    public static final String LIBRARY_URL = "http://docs.python.org/library/";
    public static final String TUTORIAL_URL = "http://docs.python.org/tutorial/";
    public static final String REFERENCE_URL = "http://docs.python.org/reference/";
    public static final String DATAMODEL_URL = "http://docs.python.org/reference/datamodel#";


    @NotNull
    public static Url newLibUrl(String module, String name) {
        return newLibUrl(module + ".html#" + name);
    }


    @NotNull
    public static Url newLibUrl(@NotNull String path) {
        if (!path.contains("#") && !path.endsWith(".html")) {
            path += ".html";
        }
        return new Url(LIBRARY_URL + path);
    }


    @NotNull
    public static Url newRefUrl(String path) {
        return new Url(REFERENCE_URL + path);
    }


    @NotNull
    public static Url newDataModelUrl(String path) {
        return new Url(DATAMODEL_URL + path);
    }


    @NotNull
    public static Url newTutUrl(String path) {
        return new Url(TUTORIAL_URL + path);
    }


    // XXX:  need to model "types" module and reconcile with these types
    public ModuleType Builtin;
    public ClassType objectType;
    public ClassType BaseType;
    public ClassType BaseList;
    public InstanceType BaseListInst;
    public ClassType BaseArray;
    public ClassType BaseDict;
    public ClassType BaseTuple;
    public ClassType BaseModule;
    public ClassType BaseFile;
    public InstanceType BaseFileInst;
    public ClassType BaseException;
    public ClassType BaseStruct;
    public ClassType BaseFunction;  // models functions, lambas and methods
    public ClassType BaseClass;  // models classes and instances

    public ClassType Datetime_datetime;
    public ClassType Datetime_date;
    public ClassType Datetime_time;
    public ClassType Datetime_timedelta;
    public ClassType Datetime_tzinfo;
    public InstanceType Time_struct_time;


    @NotNull
    String[] builtin_exception_types = {
            "ArithmeticError", "AssertionError", "AttributeError",
            "BaseException", "Exception", "DeprecationWarning", "EOFError",
            "EnvironmentError", "FloatingPointError", "FutureWarning",
            "GeneratorExit", "IOError", "ImportError", "ImportWarning",
            "IndentationError", "IndexError", "KeyError", "KeyboardInterrupt",
            "LookupError", "MemoryError", "NameError", "NotImplemented",
            "NotImplementedError", "OSError", "OverflowError",
            "PendingDeprecationWarning", "ReferenceError", "RuntimeError",
            "RuntimeWarning", "StandardError", "StopIteration", "SyntaxError",
            "SyntaxWarning", "SystemError", "SystemExit", "TabError",
            "TypeError", "UnboundLocalError", "UnicodeDecodeError",
            "UnicodeEncodeError", "UnicodeError", "UnicodeTranslateError",
            "UnicodeWarning", "UserWarning", "ValueError", "Warning",
            "ZeroDivisionError"
    };


    @NotNull
    ClassType newClass(@NotNull String name, State table) {
        return newClass(name, table, null);
    }


    @NotNull
    ClassType newClass(@NotNull String name, State table,
                       ClassType superClass, @NotNull ClassType... moreSupers)
    {
        ClassType t = new ClassType(name, table, superClass);
        for (ClassType c : moreSupers) {
            t.addSuper(c);
        }
        return t;
    }


    @Nullable
    ModuleType newModule(String name) {
        return new ModuleType(name, null, Analyzer.self.globaltable);
    }


    @NotNull
    ClassType newException(@NotNull String name, State t) {
        return newClass(name, t, BaseException);
    }


    @NotNull
    FunType newFunc() {
        return new FunType();
    }


    @Nullable
    FunType newFunc(@Nullable Type type) {
        if (type == null) {
            type = Type.UNKNOWN;
        }
        return new FunType(Type.UNKNOWN, type);
    }


    @NotNull
    ListType newList() {
        return newList(Type.UNKNOWN);
    }


    @NotNull
    ListType newList(Type type) {
        return new ListType(type);
    }


    @NotNull
    DictType newDict(Type ktype, Type vtype) {
        return new DictType(ktype, vtype);
    }


    @NotNull
    TupleType newTuple(Type... types) {
        return new TupleType(types);
    }


    @NotNull
    UnionType newUnion(Type... types) {
        return new UnionType(types);
    }


    String[] list(String... names) {
        return names;
    }


    private abstract class NativeModule {

        protected String name;
        @Nullable
        protected ModuleType module;
        @Nullable
        protected State table;  // the module's symbol table


        NativeModule(String name) {
            this.name = name;
            modules.put(name, this);
        }


        /**
         * Lazily load the module.
         */
        @Nullable
        ModuleType getModule() {
            if (module == null) {
                createModuleType();
                initBindings();
            }
            return module;
        }


        protected abstract void initBindings();


        protected void createModuleType() {
            if (module == null) {
                module = newModule(name);
                table = module.table;
                Analyzer.self.moduleTable.insert(name, liburl(), module, MODULE);
            }
        }


        @Nullable
        protected void update(String name, Url url, Type type, Binding.Kind kind) {
            table.insert(name, url, type, kind);
        }


        @Nullable
        protected void addClass(String name, Url url, Type type) {
            table.insert(name, url, type, CLASS);
        }


        @Nullable
        protected void addMethod(String name, Url url, Type type) {
            table.insert(name, url, type, METHOD);
        }


        @Nullable
        protected void addFunction(String name, Url url, Type type) {
            table.insert(name, url, newFunc(type), FUNCTION);
        }


        // don't use this unless you're sure it's OK to share the type object
        protected void addFunctions_beCareful(Type type, @NotNull String... names) {
            for (String name : names) {
                addFunction(name, liburl(), type);
            }
        }


        protected void addNoneFuncs(String... names) {
            addFunctions_beCareful(Type.NONE, names);
        }


        protected void addNumFuncs(String... names) {
            addFunctions_beCareful(Type.INT, names);
        }


        protected void addStrFuncs(String... names) {
            addFunctions_beCareful(Type.STR, names);
        }


        protected void addUnknownFuncs(@NotNull String... names) {
            for (String name : names) {
                addFunction(name, liburl(), Type.UNKNOWN);
            }
        }


        @Nullable
        protected void addAttr(String name, Url url, Type type) {
            table.insert(name, url, type, ATTRIBUTE);
        }


        // don't use this unless you're sure it's OK to share the type object
        protected void addAttributes_beCareful(Type type, @NotNull String... names) {
            for (String name : names) {
                addAttr(name, liburl(), type);
            }
        }


        protected void addNumAttrs(String... names) {
            addAttributes_beCareful(Type.INT, names);
        }


        protected void addStrAttrs(String... names) {
            addAttributes_beCareful(Type.STR, names);
        }


        protected void addUnknownAttrs(@NotNull String... names) {
            for (String name : names) {
                addAttr(name, liburl(), Type.UNKNOWN);
            }
        }


        @NotNull
        protected Url liburl() {
            return newLibUrl(name);
        }


        @NotNull
        protected Url liburl(String anchor) {
            return newLibUrl(name, anchor);
        }


        @NotNull
        @Override
        public String toString() {
            return module == null
                    ? "<Non-loaded builtin module '" + name + "'>"
                    : "<NativeModule:" + module + ">";
        }
    }


    /**
     * The set of top-level native modules.
     */
    @NotNull
    private Map<String, NativeModule> modules = new HashMap<>();


    public Builtins() {
        buildTypes();
    }


    private void buildTypes() {
        new BuiltinsModule();
        State bt = Builtin.table;

        objectType = newClass("object", bt);
        BaseType = newClass("type", bt, objectType);
        BaseTuple = newClass("tuple", bt, objectType);
        BaseList = newClass("list", bt, objectType);
        BaseListInst = new InstanceType(BaseList);
        BaseArray = newClass("array", bt);
        BaseDict = newClass("dict", bt, objectType);
        ClassType numClass = newClass("int", bt, objectType);
        BaseModule = newClass("module", bt);
        BaseFile = newClass("file", bt, objectType);
        BaseFileInst = new InstanceType(BaseFile);
        BaseFunction = newClass("function", bt, objectType);
        BaseClass = newClass("classobj", bt, objectType);
    }


    void init() {
        buildObjectType();
        buildTupleType();
        buildArrayType();
        buildListType();
        buildDictType();
        buildNumTypes();
        buildStrType();
        buildModuleType();
        buildFileType();
        buildFunctionType();
        buildClassType();

        modules.get("__builtin__").initBindings();  // eagerly load these bindings

        new ArrayModule();
        new AudioopModule();
        new BinasciiModule();
        new Bz2Module();
        new CPickleModule();
        new CStringIOModule();
        new CMathModule();
        new CollectionsModule();
        new CryptModule();
        new CTypesModule();
        new DatetimeModule();
        new DbmModule();
        new ErrnoModule();
        new ExceptionsModule();
        new FcntlModule();
        new FpectlModule();
        new GcModule();
        new GdbmModule();
        new GrpModule();
        new ImpModule();
        new ItertoolsModule();
        new MarshalModule();
        new MathModule();
        new Md5Module();
        new MmapModule();
        new NisModule();
        new OperatorModule();
        new OsModule();
        new ParserModule();
        new PosixModule();
        new PwdModule();
        new PyexpatModule();
        new ReadlineModule();
        new ResourceModule();
        new SelectModule();
        new SignalModule();
        new ShaModule();
        new SpwdModule();
        new StropModule();
        new StructModule();
        new SysModule();
        new SyslogModule();
        new TermiosModule();
        new ThreadModule();
        new TimeModule();
        new UnicodedataModule();
        new ZipimportModule();
        new ZlibModule();
    }


    /**
     * Loads (if necessary) and returns the specified built-in module.
     */
    @Nullable
    public ModuleType get(@NotNull String name) {
        if (!name.contains(".")) {  // unqualified
            return getModule(name);
        }

        String[] mods = name.split("\\.");
        Type type = getModule(mods[0]);
        if (type == null) {
            return null;
        }
        for (int i = 1; i < mods.length; i++) {
            type = type.table.lookupType(mods[i]);
            if (!(type instanceof ModuleType)) {
                return null;
            }
        }
        return (ModuleType) type;
    }


    @Nullable
    private ModuleType getModule(String name) {
        NativeModule wrap = modules.get(name);
        return wrap == null ? null : wrap.getModule();
    }


    void buildObjectType() {
        String[] obj_methods = {
                "__delattr__", "__format__", "__getattribute__", "__hash__",
                "__init__", "__new__", "__reduce__", "__reduce_ex__",
                "__repr__", "__setattr__", "__sizeof__", "__str__", "__subclasshook__"
        };
        for (String m : obj_methods) {
            objectType.table.insert(m, newLibUrl("stdtypes"), newFunc(), METHOD);
        }
        objectType.table.insert("__doc__", newLibUrl("stdtypes"), Type.STR, CLASS);
        objectType.table.insert("__class__", newLibUrl("stdtypes"), Type.UNKNOWN, CLASS);
    }


    void buildTupleType() {
        State bt = BaseTuple.table;
        String[] tuple_methods = {
                "__add__", "__contains__", "__eq__", "__ge__", "__getnewargs__",
                "__gt__", "__iter__", "__le__", "__len__", "__lt__", "__mul__",
                "__ne__", "__new__", "__rmul__", "count", "index"
        };
        for (String m : tuple_methods) {
            bt.insert(m, newLibUrl("stdtypes"), newFunc(), METHOD);
        }
        bt.insert("__getslice__", newDataModelUrl("object.__getslice__"), newFunc(), METHOD);
        bt.insert("__getitem__", newDataModelUrl("object.__getitem__"), newFunc(), METHOD);
        bt.insert("__iter__", newDataModelUrl("object.__iter__"), newFunc(), METHOD);
    }


    void buildArrayType() {
        String[] array_methods_none = {
                "append", "buffer_info", "byteswap", "extend", "fromfile",
                "fromlist", "fromstring", "fromunicode", "index", "insert", "pop",
                "read", "remove", "reverse", "tofile", "tolist", "typecode", "write"
        };
        for (String m : array_methods_none) {
            BaseArray.table.insert(m, newLibUrl("array"), newFunc(Type.NONE), METHOD);
        }
        String[] array_methods_num = {"count", "itemsize",};
        for (String m : array_methods_num) {
            BaseArray.table.insert(m, newLibUrl("array"), newFunc(Type.INT), METHOD);
        }
        String[] array_methods_str = {"tostring", "tounicode",};
        for (String m : array_methods_str) {
            BaseArray.table.insert(m, newLibUrl("array"), newFunc(Type.STR), METHOD);
        }
    }


    void buildListType() {
        BaseList.table.insert("__getslice__", newDataModelUrl("object.__getslice__"),
                newFunc(BaseListInst), METHOD);
        BaseList.table.insert("__getitem__", newDataModelUrl("object.__getitem__"),
                newFunc(BaseList), METHOD);
        BaseList.table.insert("__iter__", newDataModelUrl("object.__iter__"),
                newFunc(BaseList), METHOD);

        String[] list_methods_none = {
                "append", "extend", "index", "insert", "pop", "remove", "reverse", "sort"
        };
        for (String m : list_methods_none) {
            BaseList.table.insert(m, newLibUrl("stdtypes"), newFunc(Type.NONE), METHOD);
        }
        String[] list_methods_num = {"count"};
        for (String m : list_methods_num) {
            BaseList.table.insert(m, newLibUrl("stdtypes"), newFunc(Type.INT), METHOD);
        }
    }


    @NotNull
    Url numUrl() {
        return newLibUrl("stdtypes", "typesnumeric");
    }


    void buildNumTypes() {
        State bft = Type.FLOAT.table;
        String[] float_methods_num = {
                "__abs__", "__add__", "__coerce__", "__div__", "__divmod__",
                "__eq__", "__float__", "__floordiv__", "__format__",
                "__ge__", "__getformat__", "__gt__", "__int__",
                "__le__", "__long__", "__lt__", "__mod__", "__mul__", "__ne__",
                "__neg__", "__new__", "__nonzero__", "__pos__", "__pow__",
                "__radd__", "__rdiv__", "__rdivmod__", "__rfloordiv__", "__rmod__",
                "__rmul__", "__rpow__", "__rsub__", "__rtruediv__", "__setformat__",
                "__sub__", "__truediv__", "__trunc__", "as_integer_ratio",
                "fromhex", "is_integer"
        };
        for (String m : float_methods_num) {
            bft.insert(m, numUrl(), newFunc(Type.FLOAT), METHOD);
        }
        State bnt = Type.INT.table;
        String[] num_methods_num = {
                "__abs__", "__add__", "__and__",
                "__class__", "__cmp__", "__coerce__", "__delattr__", "__div__",
                "__divmod__", "__doc__", "__float__", "__floordiv__",
                "__getattribute__", "__getnewargs__", "__hash__", "__hex__",
                "__index__", "__init__", "__int__", "__invert__", "__long__",
                "__lshift__", "__mod__", "__mul__", "__neg__", "__new__",
                "__nonzero__", "__oct__", "__or__", "__pos__", "__pow__",
                "__radd__", "__rand__", "__rdiv__", "__rdivmod__",
                "__reduce__", "__reduce_ex__", "__repr__", "__rfloordiv__",
                "__rlshift__", "__rmod__", "__rmul__", "__ror__", "__rpow__",
                "__rrshift__", "__rshift__", "__rsub__", "__rtruediv__",
                "__rxor__", "__setattr__", "__str__", "__sub__", "__truediv__",
                "__xor__"
        };
        for (String m : num_methods_num) {
            bnt.insert(m, numUrl(), newFunc(Type.INT), METHOD);
        }
        bnt.insert("__getnewargs__", numUrl(), newFunc(newTuple(Type.INT)), METHOD);
        bnt.insert("hex", numUrl(), newFunc(Type.STR), METHOD);
        bnt.insert("conjugate", numUrl(), newFunc(Type.COMPLEX), METHOD);

        State bct = Type.COMPLEX.table;
        String[] complex_methods = {
                "__abs__", "__add__", "__div__", "__divmod__",
                "__float__", "__floordiv__", "__format__", "__getformat__", "__int__",
                "__long__", "__mod__", "__mul__", "__neg__", "__new__",
                "__pos__", "__pow__", "__radd__", "__rdiv__", "__rdivmod__",
                "__rfloordiv__", "__rmod__", "__rmul__", "__rpow__", "__rsub__",
                "__rtruediv__", "__sub__", "__truediv__", "conjugate"
        };
        for (String c : complex_methods) {
            bct.insert(c, numUrl(), newFunc(Type.COMPLEX), METHOD);
        }
        String[] complex_methods_num = {
                "__eq__", "__ge__", "__gt__", "__le__", "__lt__", "__ne__",
                "__nonzero__", "__coerce__"
        };
        for (String cn : complex_methods_num) {
            bct.insert(cn, numUrl(), newFunc(Type.INT), METHOD);
        }
        bct.insert("__getnewargs__", numUrl(), newFunc(newTuple(Type.COMPLEX)), METHOD);
        bct.insert("imag", numUrl(), Type.INT, ATTRIBUTE);
        bct.insert("real", numUrl(), Type.INT, ATTRIBUTE);
    }


    void buildStrType() {
        Type.STR.table.insert("__getslice__", newDataModelUrl("object.__getslice__"),
                newFunc(Type.STR), METHOD);
        Type.STR.table.insert("__getitem__", newDataModelUrl("object.__getitem__"),
                newFunc(Type.STR), METHOD);
        Type.STR.table.insert("__iter__", newDataModelUrl("object.__iter__"),
                newFunc(Type.STR), METHOD);

        String[] str_methods_str = {
                "capitalize", "center", "decode", "encode", "expandtabs", "format",
                "index", "join", "ljust", "lower", "lstrip", "partition", "replace",
                "rfind", "rindex", "rjust", "rpartition", "rsplit", "rstrip",
                "strip", "swapcase", "title", "translate", "upper", "zfill"
        };
        for (String m : str_methods_str) {
            Type.STR.table.insert(m, newLibUrl("stdtypes.html#str." + m),
                    newFunc(Type.STR), METHOD);
        }

        String[] str_methods_num = {
                "count", "isalnum", "isalpha", "isdigit", "islower", "isspace",
                "istitle", "isupper", "find", "startswith", "endswith"
        };
        for (String m : str_methods_num) {
            Type.STR.table.insert(m, newLibUrl("stdtypes.html#str." + m),
                    newFunc(Type.INT), METHOD);
        }

        String[] str_methods_list = {"split", "splitlines"};
        for (String m : str_methods_list) {
            Type.STR.table.insert(m, newLibUrl("stdtypes.html#str." + m),
                    newFunc(newList(Type.STR)), METHOD);
        }
        Type.STR.table.insert("partition", newLibUrl("stdtypes"),
                newFunc(newTuple(Type.STR)), METHOD);
    }


    void buildModuleType() {
        String[] attrs = {"__doc__", "__file__", "__name__", "__package__"};
        for (String m : attrs) {
            BaseModule.table.insert(m, newTutUrl("modules.html"), Type.STR, ATTRIBUTE);
        }
        BaseModule.table.insert("__dict__", newLibUrl("stdtypes", "modules"),
                newDict(Type.STR, Type.UNKNOWN), ATTRIBUTE);
    }


    void buildDictType() {
        String url = "datastructures.html#dictionaries";
        State bt = BaseDict.table;

        bt.insert("__getitem__", newTutUrl(url), newFunc(), METHOD);
        bt.insert("__iter__", newTutUrl(url), newFunc(), METHOD);
        bt.insert("get", newTutUrl(url), newFunc(), METHOD);

        bt.insert("items", newTutUrl(url),
                newFunc(newList(newTuple(Type.UNKNOWN, Type.UNKNOWN))), METHOD);

        bt.insert("keys", newTutUrl(url), newFunc(BaseList), METHOD);
        bt.insert("values", newTutUrl(url), newFunc(BaseList), METHOD);

        String[] dict_method_unknown = {
                "clear", "copy", "fromkeys", "get", "iteritems", "iterkeys",
                "itervalues", "pop", "popitem", "setdefault", "update"
        };
        for (String m : dict_method_unknown) {
            bt.insert(m, newTutUrl(url), newFunc(), METHOD);
        }

        String[] dict_method_num = {"has_key"};
        for (String m : dict_method_num) {
            bt.insert(m, newTutUrl(url), newFunc(Type.INT), METHOD);
        }
    }


    void buildFileType() {
        String url = "stdtypes.html#bltin-file-objects";
        State table = BaseFile.table;

        String[] methods_unknown = {
                "__enter__", "__exit__", "__iter__", "flush", "readinto", "truncate"
        };
        for (String m : methods_unknown) {
            table.insert(m, newLibUrl(url), newFunc(), METHOD);
        }

        String[] methods_str = {"next", "read", "readline"};
        for (String m : methods_str) {
            table.insert(m, newLibUrl(url), newFunc(Type.STR), METHOD);
        }

        String[] num = {"fileno", "isatty", "tell"};
        for (String m : num) {
            table.insert(m, newLibUrl(url), newFunc(Type.INT), METHOD);
        }

        String[] methods_none = {"close", "seek", "write", "writelines"};
        for (String m : methods_none) {
            table.insert(m, newLibUrl(url), newFunc(Type.NONE), METHOD);
        }

        table.insert("readlines", newLibUrl(url), newFunc(newList(Type.STR)), METHOD);
        table.insert("xreadlines", newLibUrl(url), newFunc(Type.STR), METHOD);
        table.insert("closed", newLibUrl(url), Type.INT, ATTRIBUTE);
        table.insert("encoding", newLibUrl(url), Type.STR, ATTRIBUTE);
        table.insert("errors", newLibUrl(url), Type.UNKNOWN, ATTRIBUTE);
        table.insert("mode", newLibUrl(url), Type.INT, ATTRIBUTE);
        table.insert("name", newLibUrl(url), Type.STR, ATTRIBUTE);
        table.insert("softspace", newLibUrl(url), Type.INT, ATTRIBUTE);
        table.insert("newlines", newLibUrl(url), newUnion(Type.STR, newTuple(Type.STR)), ATTRIBUTE);
    }


    void buildFunctionType() {
        State t = BaseFunction.table;

        for (String s : list("func_doc", "__doc__", "func_name", "__name__", "__module__")) {
            t.insert(s, new Url(DATAMODEL_URL), Type.STR, ATTRIBUTE);
        }

        t.insert("func_closure", new Url(DATAMODEL_URL), newTuple(), ATTRIBUTE);
        t.insert("func_code", new Url(DATAMODEL_URL), Type.UNKNOWN, ATTRIBUTE);
        t.insert("func_defaults", new Url(DATAMODEL_URL), newTuple(), ATTRIBUTE);
        t.insert("func_globals", new Url(DATAMODEL_URL), new DictType(Type.STR, Type.UNKNOWN),
                ATTRIBUTE);
        t.insert("func_dict", new Url(DATAMODEL_URL), new DictType(Type.STR, Type.UNKNOWN), ATTRIBUTE);

        // Assume any function can become a method, for simplicity.
        for (String s : list("__func__", "im_func")) {
            t.insert(s, new Url(DATAMODEL_URL), new FunType(), METHOD);
        }
    }


    // XXX:  finish wiring this up.  ClassType needs to inherit from it somehow,
    // so we can remove the per-instance attributes from NClassDef.
    void buildClassType() {
        State t = BaseClass.table;

        for (String s : list("__name__", "__doc__", "__module__")) {
            t.insert(s, new Url(DATAMODEL_URL), Type.STR, ATTRIBUTE);
        }

        t.insert("__dict__", new Url(DATAMODEL_URL), new DictType(Type.STR, Type.UNKNOWN), ATTRIBUTE);
    }


    class BuiltinsModule extends NativeModule {
        public BuiltinsModule() {
            super("__builtin__");
            Builtin = module = newModule(name);
            table = module.table;
        }


        @Override
        public void initBindings() {
            Analyzer.self.moduleTable.insert(name, liburl(), module, MODULE);
            table.addSuper(BaseModule.table);

            addClass("None", newLibUrl("constants"), Type.NONE);
            addFunction("bool", newLibUrl("functions", "bool"), Type.BOOL);
            addFunction("complex", newLibUrl("functions", "complex"), Type.COMPLEX);
            addClass("dict", newLibUrl("stdtypes", "typesmapping"), BaseDict);
            addFunction("file", newLibUrl("functions", "file"), BaseFileInst);
            addFunction("int", newLibUrl("functions", "int"), Type.INT);
            addFunction("long", newLibUrl("functions", "long"), Type.INT);
            addFunction("float", newLibUrl("functions", "float"), Type.FLOAT);
            addFunction("list", newLibUrl("functions", "list"), new InstanceType(BaseList));
            addFunction("object", newLibUrl("functions", "object"), new InstanceType(objectType));
            addFunction("str", newLibUrl("functions", "str"), Type.STR);
            addFunction("tuple", newLibUrl("functions", "tuple"), new InstanceType(BaseTuple));
            addFunction("type", newLibUrl("functions", "type"), new InstanceType(BaseType));

            // XXX:  need to model the following as built-in class types:
            //   basestring, bool, buffer, frozenset, property, set, slice,
            //   staticmethod, super and unicode
            String[] builtin_func_unknown = {
                    "apply", "basestring", "callable", "classmethod",
                    "coerce", "compile", "copyright", "credits", "delattr", "enumerate",
                    "eval", "execfile", "exit", "filter", "frozenset", "getattr",
                    "help", "input", "intern", "iter", "license", "long",
                    "property", "quit", "raw_input", "reduce", "reload", "reversed",
                    "set", "setattr", "slice", "sorted", "staticmethod", "super",
                    "type", "unichr", "unicode",
            };
            for (String f : builtin_func_unknown) {
                addFunction(f, newLibUrl("functions.html#" + f), Type.UNKNOWN);
            }

            String[] builtin_func_num = {
                    "abs", "all", "any", "cmp", "coerce", "divmod",
                    "hasattr", "hash", "id", "isinstance", "issubclass", "len", "max",
                    "min", "ord", "pow", "round", "sum"
            };
            for (String f : builtin_func_num) {
                addFunction(f, newLibUrl("functions.html#" + f), Type.INT);
            }

            for (String f : list("hex", "oct", "repr", "chr")) {
                addFunction(f, newLibUrl("functions.html#" + f), Type.STR);
            }

            addFunction("dir", newLibUrl("functions", "dir"), newList(Type.STR));
            addFunction("map", newLibUrl("functions", "map"), newList(Type.UNKNOWN));
            addFunction("range", newLibUrl("functions", "range"), newList(Type.INT));
            addFunction("xrange", newLibUrl("functions", "range"), newList(Type.INT));
            addFunction("buffer", newLibUrl("functions", "buffer"), newList(Type.UNKNOWN));
            addFunction("zip", newLibUrl("functions", "zip"), newList(newTuple(Type.UNKNOWN)));


            for (String f : list("globals", "vars", "locals")) {
                addFunction(f, newLibUrl("functions.html#" + f), newDict(Type.STR, Type.UNKNOWN));
            }

            for (String f : builtin_exception_types) {
                addClass(f, newDataModelUrl("org/yinwang/pysonar/types"),
                        newClass(f, Analyzer.self.globaltable, objectType));
            }
            BaseException = (ClassType) table.lookupType("BaseException");

            for (String f : list("True", "False")) {
                addAttr(f, newDataModelUrl("org/yinwang/pysonar/types"), Type.BOOL);
            }

            addAttr("None", newDataModelUrl("org/yinwang/pysonar/types"), Type.NONE);
            addFunction("open", newTutUrl("inputoutput.html#reading-and-writing-files"), BaseFileInst);
            addFunction("__import__", newLibUrl("functions"), newModule("<?>"));

            Analyzer.self.globaltable.insert("__builtins__", liburl(), module, ATTRIBUTE);
            Analyzer.self.globaltable.putAll(table);
        }
    }


    class ArrayModule extends NativeModule {
        public ArrayModule() {
            super("array");
        }


        @Override
        public void initBindings() {
            addClass("array", newLibUrl("array", "array"), BaseArray);
            addClass("ArrayType", newLibUrl("array", "ArrayType"), BaseArray);
        }
    }


    class AudioopModule extends NativeModule {
        public AudioopModule() {
            super("audioop");
        }


        @Override
        public void initBindings() {
            addClass("error", liburl(), newException("error", table));

            addStrFuncs("add", "adpcm2lin", "alaw2lin", "bias", "lin2alaw", "lin2lin",
                    "lin2ulaw", "mul", "reverse", "tomono", "ulaw2lin");

            addNumFuncs("avg", "avgpp", "cross", "findfactor", "findmax",
                    "getsample", "max", "maxpp", "rms");

            for (String s : list("adpcm2lin", "findfit", "lin2adpcm", "minmax", "ratecv")) {
                addFunction(s, liburl(), newTuple());
            }
        }
    }


    class BinasciiModule extends NativeModule {
        public BinasciiModule() {
            super("binascii");
        }


        @Override
        public void initBindings() {
            addStrFuncs(
                    "a2b_uu", "b2a_uu", "a2b_base64", "b2a_base64", "a2b_qp",
                    "b2a_qp", "a2b_hqx", "rledecode_hqx", "rlecode_hqx", "b2a_hqx",
                    "b2a_hex", "hexlify", "a2b_hex", "unhexlify");

            addNumFuncs("crc_hqx", "crc32");

            addClass("Error", liburl(), newException("Error", table));
            addClass("Incomplete", liburl(), newException("Incomplete", table));
        }
    }


    class Bz2Module extends NativeModule {
        public Bz2Module() {
            super("bz2");
        }


        @Override
        public void initBindings() {
            ClassType bz2 = newClass("BZ2File", table, BaseFile);  // close enough.
            addClass("BZ2File", liburl(), bz2);

            ClassType bz2c = newClass("BZ2Compressor", table, objectType);
            bz2c.table.insert("compress", newLibUrl("bz2", "sequential-de-compression"),
                    newFunc(Type.STR), METHOD);
            bz2c.table.insert("flush", newLibUrl("bz2", "sequential-de-compression"),
                    newFunc(Type.NONE), METHOD);
            addClass("BZ2Compressor", newLibUrl("bz2", "sequential-de-compression"), bz2c);

            ClassType bz2d = newClass("BZ2Decompressor", table, objectType);
            bz2d.table.insert("decompress", newLibUrl("bz2", "sequential-de-compression"),
                    newFunc(Type.STR), METHOD);
            addClass("BZ2Decompressor", newLibUrl("bz2", "sequential-de-compression"), bz2d);

            addFunction("compress", newLibUrl("bz2", "one-shot-de-compression"), Type.STR);
            addFunction("decompress", newLibUrl("bz2", "one-shot-de-compression"), Type.STR);
        }
    }


    class CPickleModule extends NativeModule {
        public CPickleModule() {
            super("cPickle");
        }


        @NotNull
        @Override
        protected Url liburl() {
            return newLibUrl("pickle", "module-cPickle");
        }


        @Override
        public void initBindings() {
            addUnknownFuncs("dump", "load", "dumps", "loads");

            addClass("PickleError", liburl(), newException("PickleError", table));

            ClassType picklingError = newException("PicklingError", table);
            addClass("PicklingError", liburl(), picklingError);
            update("UnpickleableError", liburl(),
                    newClass("UnpickleableError", table, picklingError), CLASS);
            ClassType unpicklingError = newException("UnpicklingError", table);
            addClass("UnpicklingError", liburl(), unpicklingError);
            update("BadPickleGet", liburl(),
                    newClass("BadPickleGet", table, unpicklingError), CLASS);

            ClassType pickler = newClass("Pickler", table, objectType);
            pickler.table.insert("dump", liburl(), newFunc(), METHOD);
            pickler.table.insert("clear_memo", liburl(), newFunc(), METHOD);
            addClass("Pickler", liburl(), pickler);

            ClassType unpickler = newClass("Unpickler", table, objectType);
            unpickler.table.insert("load", liburl(), newFunc(), METHOD);
            unpickler.table.insert("noload", liburl(), newFunc(), METHOD);
            addClass("Unpickler", liburl(), unpickler);
        }
    }


    class CStringIOModule extends NativeModule {
        public CStringIOModule() {
            super("cStringIO");
        }


        @NotNull
        @Override
        protected Url liburl() {
            return newLibUrl("stringio");
        }


        @NotNull
        @Override
        protected Url liburl(String anchor) {
            return newLibUrl("stringio", anchor);
        }


        @Override
        public void initBindings() {
            ClassType StringIO = newClass("StringIO", table, BaseFile);
            addFunction("StringIO", liburl(), new InstanceType(StringIO));
            addAttr("InputType", liburl(), BaseType);
            addAttr("OutputType", liburl(), BaseType);
            addAttr("cStringIO_CAPI", liburl(), Type.UNKNOWN);
        }
    }


    class CMathModule extends NativeModule {
        public CMathModule() {
            super("cmath");
        }


        @Override
        public void initBindings() {
            addFunction("phase", liburl("conversions-to-and-from-polar-coordinates"), Type.INT);
            addFunction("polar", liburl("conversions-to-and-from-polar-coordinates"),
                    newTuple(Type.INT, Type.INT));
            addFunction("rect", liburl("conversions-to-and-from-polar-coordinates"),
                    Type.COMPLEX);

            for (String plf : list("exp", "log", "log10", "sqrt")) {
                addFunction(plf, liburl("power-and-logarithmic-functions"), Type.INT);
            }

            for (String tf : list("acos", "asin", "atan", "cos", "sin", "tan")) {
                addFunction(tf, liburl("trigonometric-functions"), Type.INT);
            }

            for (String hf : list("acosh", "asinh", "atanh", "cosh", "sinh", "tanh")) {
                addFunction(hf, liburl("hyperbolic-functions"), Type.COMPLEX);
            }

            for (String cf : list("isinf", "isnan")) {
                addFunction(cf, liburl("classification-functions"), Type.BOOL);
            }

            for (String c : list("pi", "e")) {
                addAttr(c, liburl("constants"), Type.INT);
            }
        }
    }


    class CollectionsModule extends NativeModule {
        public CollectionsModule() {
            super("collections");
        }


        @NotNull
        private Url abcUrl() {
            return liburl("abcs-abstract-base-classes");
        }


        @NotNull
        private Url dequeUrl() {
            return liburl("deque-objects");
        }


        @Override
        public void initBindings() {
            ClassType callable = newClass("Callable", table, objectType);
            callable.table.insert("__call__", abcUrl(), newFunc(), METHOD);
            addClass("Callable", abcUrl(), callable);

            ClassType iterableType = newClass("Iterable", table, objectType);
            iterableType.table.insert("__next__", abcUrl(), newFunc(), METHOD);
            iterableType.table.insert("__iter__", abcUrl(), newFunc(), METHOD);
            addClass("Iterable", abcUrl(), iterableType);

            ClassType Hashable = newClass("Hashable", table, objectType);
            Hashable.table.insert("__hash__", abcUrl(), newFunc(Type.INT), METHOD);
            addClass("Hashable", abcUrl(), Hashable);

            ClassType Sized = newClass("Sized", table, objectType);
            Sized.table.insert("__len__", abcUrl(), newFunc(Type.INT), METHOD);
            addClass("Sized", abcUrl(), Sized);

            ClassType containerType = newClass("Container", table, objectType);
            containerType.table.insert("__contains__", abcUrl(), newFunc(Type.INT), METHOD);
            addClass("Container", abcUrl(), containerType);

            ClassType iteratorType = newClass("Iterator", table, iterableType);
            addClass("Iterator", abcUrl(), iteratorType);

            ClassType sequenceType = newClass("Sequence", table, Sized, iterableType, containerType);
            sequenceType.table.insert("__getitem__", abcUrl(), newFunc(), METHOD);
            sequenceType.table.insert("reversed", abcUrl(), newFunc(sequenceType), METHOD);
            sequenceType.table.insert("index", abcUrl(), newFunc(Type.INT), METHOD);
            sequenceType.table.insert("count", abcUrl(), newFunc(Type.INT), METHOD);
            addClass("Sequence", abcUrl(), sequenceType);

            ClassType mutableSequence = newClass("MutableSequence", table, sequenceType);
            mutableSequence.table.insert("__setitem__", abcUrl(), newFunc(), METHOD);
            mutableSequence.table.insert("__delitem__", abcUrl(), newFunc(), METHOD);
            addClass("MutableSequence", abcUrl(), mutableSequence);

            ClassType setType = newClass("Set", table, Sized, iterableType, containerType);
            setType.table.insert("__getitem__", abcUrl(), newFunc(), METHOD);
            addClass("Set", abcUrl(), setType);

            ClassType mutableSet = newClass("MutableSet", table, setType);
            mutableSet.table.insert("add", abcUrl(), newFunc(), METHOD);
            mutableSet.table.insert("discard", abcUrl(), newFunc(), METHOD);
            addClass("MutableSet", abcUrl(), mutableSet);

            ClassType mapping = newClass("Mapping", table, Sized, iterableType, containerType);
            mapping.table.insert("__getitem__", abcUrl(), newFunc(), METHOD);
            addClass("Mapping", abcUrl(), mapping);

            ClassType mutableMapping = newClass("MutableMapping", table, mapping);
            mutableMapping.table.insert("__setitem__", abcUrl(), newFunc(), METHOD);
            mutableMapping.table.insert("__delitem__", abcUrl(), newFunc(), METHOD);
            addClass("MutableMapping", abcUrl(), mutableMapping);

            ClassType MappingView = newClass("MappingView", table, Sized);
            addClass("MappingView", abcUrl(), MappingView);

            ClassType KeysView = newClass("KeysView", table, Sized);
            addClass("KeysView", abcUrl(), KeysView);

            ClassType ItemsView = newClass("ItemsView", table, Sized);
            addClass("ItemsView", abcUrl(), ItemsView);

            ClassType ValuesView = newClass("ValuesView", table, Sized);
            addClass("ValuesView", abcUrl(), ValuesView);

            ClassType deque = newClass("deque", table, objectType);
            for (String n : list("append", "appendLeft", "clear",
                    "extend", "extendLeft", "rotate"))
            {
                deque.table.insert(n, dequeUrl(), newFunc(Type.NONE), METHOD);
            }
            for (String u : list("__getitem__", "__iter__",
                    "pop", "popleft", "remove"))
            {
                deque.table.insert(u, dequeUrl(), newFunc(), METHOD);
            }
            addClass("deque", dequeUrl(), deque);

            ClassType defaultdict = newClass("defaultdict", table, objectType);
            defaultdict.table.insert("__missing__", liburl("defaultdict-objects"),
                    newFunc(), METHOD);
            defaultdict.table.insert("default_factory", liburl("defaultdict-objects"),
                    newFunc(), METHOD);
            addClass("defaultdict", liburl("defaultdict-objects"), defaultdict);

            String argh = "namedtuple-factory-function-for-tuples-with-named-fields";
            ClassType namedtuple = newClass("(namedtuple)", table, BaseTuple);
            namedtuple.table.insert("_fields", liburl(argh),
                    new ListType(Type.STR), ATTRIBUTE);
            addFunction("namedtuple", liburl(argh), namedtuple);
        }
    }


    class CTypesModule extends NativeModule {
        public CTypesModule() {
            super("ctypes");
        }


        @Override
        public void initBindings() {
            String[] ctypes_attrs = {
                    "ARRAY", "ArgumentError", "Array", "BigEndianStructure", "CDLL",
                    "CFUNCTYPE", "DEFAULT_MODE", "DllCanUnloadNow", "DllGetClassObject",
                    "FormatError", "GetLastError", "HRESULT", "LibraryLoader",
                    "LittleEndianStructure", "OleDLL", "POINTER", "PYFUNCTYPE", "PyDLL",
                    "RTLD_GLOBAL", "RTLD_LOCAL", "SetPointerType", "Structure", "Union",
                    "WINFUNCTYPE", "WinDLL", "WinError", "_CFuncPtr", "_FUNCFLAG_CDECL",
                    "_FUNCFLAG_PYTHONAPI", "_FUNCFLAG_STDCALL", "_FUNCFLAG_USE_ERRNO",
                    "_FUNCFLAG_USE_LASTERROR", "_Pointer", "_SimpleCData",
                    "_c_functype_cache", "_calcsize", "_cast", "_cast_addr",
                    "_check_HRESULT", "_check_size", "_ctypes_version", "_dlopen",
                    "_endian", "_memmove_addr", "_memset_addr", "_os",
                    "_pointer_type_cache", "_string_at", "_string_at_addr", "_sys",
                    "_win_functype_cache", "_wstring_at", "_wstring_at_addr",
                    "addressof", "alignment", "byref", "c_bool", "c_buffer", "c_byte",
                    "c_char", "c_char_p", "c_double", "c_float", "c_int", "c_int16",
                    "c_int32", "c_int64", "c_int8", "c_long", "c_longdouble",
                    "c_longlong", "c_short", "c_size_t", "c_ubyte", "c_uint",
                    "c_uint16", "c_uint32", "c_uint64", "c_uint8", "c_ulong",
                    "c_ulonglong", "c_ushort", "c_void_p", "c_voidp", "c_wchar",
                    "c_wchar_p", "cast", "cdll", "create_string_buffer",
                    "create_unicode_buffer", "get_errno", "get_last_error", "memmove",
                    "memset", "oledll", "pointer", "py_object", "pydll", "pythonapi",
                    "resize", "set_conversion_mode", "set_errno", "set_last_error",
                    "sizeof", "string_at", "windll", "wstring_at"
            };
            for (String attr : ctypes_attrs) {
                addAttr(attr, liburl(attr), Type.UNKNOWN);
            }
        }
    }


    class CryptModule extends NativeModule {
        public CryptModule() {
            super("crypt");
        }


        @Override
        public void initBindings() {
            addStrFuncs("crypt");
        }
    }


    class DatetimeModule extends NativeModule {
        public DatetimeModule() {
            super("datetime");
        }


        @NotNull
        private Url dtUrl(String anchor) {
            return liburl("datetime." + anchor);
        }


        @Override
        public void initBindings() {
            // XXX:  make datetime, time, date, timedelta and tzinfo Base* objects,
            // so built-in functions can return them.

            addNumAttrs("MINYEAR", "MAXYEAR");

            ClassType timedelta = Datetime_timedelta = newClass("timedelta", table, objectType);
            addClass("timedelta", dtUrl("timedelta"), timedelta);
            State tdtable = Datetime_timedelta.table;
            tdtable.insert("min", dtUrl("timedelta"), timedelta, ATTRIBUTE);
            tdtable.insert("max", dtUrl("timedelta"), timedelta, ATTRIBUTE);
            tdtable.insert("resolution", dtUrl("timedelta"), timedelta, ATTRIBUTE);

            tdtable.insert("days", dtUrl("timedelta"), Type.INT, ATTRIBUTE);
            tdtable.insert("seconds", dtUrl("timedelta"), Type.INT, ATTRIBUTE);
            tdtable.insert("microseconds", dtUrl("timedelta"), Type.INT, ATTRIBUTE);

            ClassType tzinfo = Datetime_tzinfo = newClass("tzinfo", table, objectType);
            addClass("tzinfo", dtUrl("tzinfo"), tzinfo);
            State tztable = Datetime_tzinfo.table;
            tztable.insert("utcoffset", dtUrl("tzinfo"), newFunc(timedelta), METHOD);
            tztable.insert("dst", dtUrl("tzinfo"), newFunc(timedelta), METHOD);
            tztable.insert("tzname", dtUrl("tzinfo"), newFunc(Type.STR), METHOD);
            tztable.insert("fromutc", dtUrl("tzinfo"), newFunc(tzinfo), METHOD);

            ClassType date = Datetime_date = newClass("date", table, objectType);
            addClass("date", dtUrl("date"), date);
            State dtable = Datetime_date.table;
            dtable.insert("min", dtUrl("date"), date, ATTRIBUTE);
            dtable.insert("max", dtUrl("date"), date, ATTRIBUTE);
            dtable.insert("resolution", dtUrl("date"), timedelta, ATTRIBUTE);

            dtable.insert("today", dtUrl("date"), newFunc(date), METHOD);
            dtable.insert("fromtimestamp", dtUrl("date"), newFunc(date), METHOD);
            dtable.insert("fromordinal", dtUrl("date"), newFunc(date), METHOD);

            dtable.insert("year", dtUrl("date"), Type.INT, ATTRIBUTE);
            dtable.insert("month", dtUrl("date"), Type.INT, ATTRIBUTE);
            dtable.insert("day", dtUrl("date"), Type.INT, ATTRIBUTE);

            dtable.insert("replace", dtUrl("date"), newFunc(date), METHOD);
            dtable.insert("timetuple", dtUrl("date"), newFunc(Time_struct_time), METHOD);

            for (String n : list("toordinal", "weekday", "isoweekday")) {
                dtable.insert(n, dtUrl("date"), newFunc(Type.INT), METHOD);
            }
            for (String r : list("ctime", "strftime", "isoformat")) {
                dtable.insert(r, dtUrl("date"), newFunc(Type.STR), METHOD);
            }
            dtable.insert("isocalendar", dtUrl("date"),
                    newFunc(newTuple(Type.INT, Type.INT, Type.INT)), METHOD);

            ClassType time = Datetime_time = newClass("time", table, objectType);
            addClass("time", dtUrl("time"), time);
            State ttable = Datetime_time.table;

            ttable.insert("min", dtUrl("time"), time, ATTRIBUTE);
            ttable.insert("max", dtUrl("time"), time, ATTRIBUTE);
            ttable.insert("resolution", dtUrl("time"), timedelta, ATTRIBUTE);

            ttable.insert("hour", dtUrl("time"), Type.INT, ATTRIBUTE);
            ttable.insert("minute", dtUrl("time"), Type.INT, ATTRIBUTE);
            ttable.insert("second", dtUrl("time"), Type.INT, ATTRIBUTE);
            ttable.insert("microsecond", dtUrl("time"), Type.INT, ATTRIBUTE);
            ttable.insert("tzinfo", dtUrl("time"), tzinfo, ATTRIBUTE);

            ttable.insert("replace", dtUrl("time"), newFunc(time), METHOD);

            for (String l : list("isoformat", "strftime", "tzname")) {
                ttable.insert(l, dtUrl("time"), newFunc(Type.STR), METHOD);
            }
            for (String f : list("utcoffset", "dst")) {
                ttable.insert(f, dtUrl("time"), newFunc(timedelta), METHOD);
            }

            ClassType datetime = Datetime_datetime = newClass("datetime", table, date, time);
            addClass("datetime", dtUrl("datetime"), datetime);
            State dttable = Datetime_datetime.table;

            for (String c : list("combine", "fromordinal", "fromtimestamp", "now",
                    "strptime", "today", "utcfromtimestamp", "utcnow"))
            {
                dttable.insert(c, dtUrl("datetime"), newFunc(datetime), METHOD);
            }

            dttable.insert("min", dtUrl("datetime"), datetime, ATTRIBUTE);
            dttable.insert("max", dtUrl("datetime"), datetime, ATTRIBUTE);
            dttable.insert("resolution", dtUrl("datetime"), timedelta, ATTRIBUTE);

            dttable.insert("date", dtUrl("datetime"), newFunc(date), METHOD);

            for (String x : list("time", "timetz")) {
                dttable.insert(x, dtUrl("datetime"), newFunc(time), METHOD);
            }

            for (String y : list("replace", "astimezone")) {
                dttable.insert(y, dtUrl("datetime"), newFunc(datetime), METHOD);
            }

            dttable.insert("utctimetuple", dtUrl("datetime"), newFunc(Time_struct_time), METHOD);
        }
    }


    class DbmModule extends NativeModule {
        public DbmModule() {
            super("dbm");
        }


        @Override
        public void initBindings() {
            ClassType dbm = new ClassType("dbm", table, BaseDict);
            addClass("dbm", liburl(), dbm);
            addClass("error", liburl(), newException("error", table));
            addStrAttrs("library");
            addFunction("open", liburl(), dbm);
        }
    }


    class ErrnoModule extends NativeModule {
        public ErrnoModule() {
            super("errno");
        }


        @Override
        public void initBindings() {
            addNumAttrs(
                    "E2BIG", "EACCES", "EADDRINUSE", "EADDRNOTAVAIL", "EAFNOSUPPORT",
                    "EAGAIN", "EALREADY", "EBADF", "EBUSY", "ECHILD", "ECONNABORTED",
                    "ECONNREFUSED", "ECONNRESET", "EDEADLK", "EDEADLOCK",
                    "EDESTADDRREQ", "EDOM", "EDQUOT", "EEXIST", "EFAULT", "EFBIG",
                    "EHOSTDOWN", "EHOSTUNREACH", "EILSEQ", "EINPROGRESS", "EINTR",
                    "EINVAL", "EIO", "EISCONN", "EISDIR", "ELOOP", "EMFILE", "EMLINK",
                    "EMSGSIZE", "ENAMETOOLONG", "ENETDOWN", "ENETRESET", "ENETUNREACH",
                    "ENFILE", "ENOBUFS", "ENODEV", "ENOENT", "ENOEXEC", "ENOLCK",
                    "ENOMEM", "ENOPROTOOPT", "ENOSPC", "ENOSYS", "ENOTCONN", "ENOTDIR",
                    "ENOTEMPTY", "ENOTSOCK", "ENOTTY", "ENXIO", "EOPNOTSUPP", "EPERM",
                    "EPFNOSUPPORT", "EPIPE", "EPROTONOSUPPORT", "EPROTOTYPE", "ERANGE",
                    "EREMOTE", "EROFS", "ESHUTDOWN", "ESOCKTNOSUPPORT", "ESPIPE",
                    "ESRCH", "ESTALE", "ETIMEDOUT", "ETOOMANYREFS", "EUSERS",
                    "EWOULDBLOCK", "EXDEV", "WSABASEERR", "WSAEACCES", "WSAEADDRINUSE",
                    "WSAEADDRNOTAVAIL", "WSAEAFNOSUPPORT", "WSAEALREADY", "WSAEBADF",
                    "WSAECONNABORTED", "WSAECONNREFUSED", "WSAECONNRESET",
                    "WSAEDESTADDRREQ", "WSAEDISCON", "WSAEDQUOT", "WSAEFAULT",
                    "WSAEHOSTDOWN", "WSAEHOSTUNREACH", "WSAEINPROGRESS", "WSAEINTR",
                    "WSAEINVAL", "WSAEISCONN", "WSAELOOP", "WSAEMFILE", "WSAEMSGSIZE",
                    "WSAENAMETOOLONG", "WSAENETDOWN", "WSAENETRESET", "WSAENETUNREACH",
                    "WSAENOBUFS", "WSAENOPROTOOPT", "WSAENOTCONN", "WSAENOTEMPTY",
                    "WSAENOTSOCK", "WSAEOPNOTSUPP", "WSAEPFNOSUPPORT", "WSAEPROCLIM",
                    "WSAEPROTONOSUPPORT", "WSAEPROTOTYPE", "WSAEREMOTE", "WSAESHUTDOWN",
                    "WSAESOCKTNOSUPPORT", "WSAESTALE", "WSAETIMEDOUT",
                    "WSAETOOMANYREFS", "WSAEUSERS", "WSAEWOULDBLOCK",
                    "WSANOTINITIALISED", "WSASYSNOTREADY", "WSAVERNOTSUPPORTED");

            addAttr("errorcode", liburl("errorcode"), newDict(Type.INT, Type.STR));
        }
    }


    class ExceptionsModule extends NativeModule {
        public ExceptionsModule() {
            super("exceptions");
        }


        @Override
        public void initBindings() {
            ModuleType builtins = get("__builtin__");
            for (String s : builtin_exception_types) {
//                Binding b = builtins.getTable().lookup(s);
//                table.update(b.getName(), b.getFirstNode(), b.getType(), b.getKind());
            }
        }
    }


    class FcntlModule extends NativeModule {
        public FcntlModule() {
            super("fcntl");
        }


        @Override
        public void initBindings() {
            for (String s : list("fcntl", "ioctl")) {
                addFunction(s, liburl(), newUnion(Type.INT, Type.STR));
            }
            addNumFuncs("flock");
            addUnknownFuncs("lockf");

            addNumAttrs(
                    "DN_ACCESS", "DN_ATTRIB", "DN_CREATE", "DN_DELETE", "DN_MODIFY",
                    "DN_MULTISHOT", "DN_RENAME", "FASYNC", "FD_CLOEXEC", "F_DUPFD",
                    "F_EXLCK", "F_GETFD", "F_GETFL", "F_GETLEASE", "F_GETLK", "F_GETLK64",
                    "F_GETOWN", "F_GETSIG", "F_NOTIFY", "F_RDLCK", "F_SETFD", "F_SETFL",
                    "F_SETLEASE", "F_SETLK", "F_SETLK64", "F_SETLKW", "F_SETLKW64",
                    "F_SETOWN", "F_SETSIG", "F_SHLCK", "F_UNLCK", "F_WRLCK", "I_ATMARK",
                    "I_CANPUT", "I_CKBAND", "I_FDINSERT", "I_FIND", "I_FLUSH",
                    "I_FLUSHBAND", "I_GETBAND", "I_GETCLTIME", "I_GETSIG", "I_GRDOPT",
                    "I_GWROPT", "I_LINK", "I_LIST", "I_LOOK", "I_NREAD", "I_PEEK",
                    "I_PLINK", "I_POP", "I_PUNLINK", "I_PUSH", "I_RECVFD", "I_SENDFD",
                    "I_SETCLTIME", "I_SETSIG", "I_SRDOPT", "I_STR", "I_SWROPT",
                    "I_UNLINK", "LOCK_EX", "LOCK_MAND", "LOCK_NB", "LOCK_READ", "LOCK_RW",
                    "LOCK_SH", "LOCK_UN", "LOCK_WRITE");
        }
    }


    class FpectlModule extends NativeModule {
        public FpectlModule() {
            super("fpectl");
        }


        @Override
        public void initBindings() {
            addNoneFuncs("turnon_sigfpe", "turnoff_sigfpe");
            addClass("FloatingPointError", liburl(), newException("FloatingPointError", table));
        }
    }


    class GcModule extends NativeModule {
        public GcModule() {
            super("gc");
        }


        @Override
        public void initBindings() {
            addNoneFuncs("enable", "disable", "set_debug", "set_threshold");
            addNumFuncs("isenabled", "collect", "get_debug", "get_count", "get_threshold");
            for (String s : list("get_objects", "get_referrers", "get_referents")) {
                addFunction(s, liburl(), newList());
            }
            addAttr("garbage", liburl(), newList());
            addNumAttrs("DEBUG_STATS", "DEBUG_COLLECTABLE", "DEBUG_UNCOLLECTABLE",
                    "DEBUG_INSTANCES", "DEBUG_OBJECTS", "DEBUG_SAVEALL", "DEBUG_LEAK");
        }
    }


    class GdbmModule extends NativeModule {
        public GdbmModule() {
            super("gdbm");
        }


        @Override
        public void initBindings() {
            addClass("error", liburl(), newException("error", table));

            ClassType gdbm = new ClassType("gdbm", table, BaseDict);
            gdbm.table.insert("firstkey", liburl(), newFunc(Type.STR), METHOD);
            gdbm.table.insert("nextkey", liburl(), newFunc(Type.STR), METHOD);
            gdbm.table.insert("reorganize", liburl(), newFunc(Type.NONE), METHOD);
            gdbm.table.insert("sync", liburl(), newFunc(Type.NONE), METHOD);

            addFunction("open", liburl(), gdbm);
        }

    }


    class GrpModule extends NativeModule {
        public GrpModule() {
            super("grp");
        }


        @Override
        public void initBindings() {
            Builtins.this.get("struct");
            ClassType struct_group = newClass("struct_group", table, BaseStruct);
            struct_group.table.insert("gr_name", liburl(), Type.STR, ATTRIBUTE);
            struct_group.table.insert("gr_passwd", liburl(), Type.STR, ATTRIBUTE);
            struct_group.table.insert("gr_gid", liburl(), Type.INT, ATTRIBUTE);
            struct_group.table.insert("gr_mem", liburl(), newList(Type.STR), ATTRIBUTE);

            addClass("struct_group", liburl(), struct_group);

            for (String s : list("getgrgid", "getgrnam")) {
                addFunction(s, liburl(), struct_group);
            }
            addFunction("getgrall", liburl(), new ListType(struct_group));
        }
    }


    class ImpModule extends NativeModule {
        public ImpModule() {
            super("imp");
        }


        @Override
        public void initBindings() {
            addStrFuncs("get_magic");
            addFunction("get_suffixes", liburl(), newList(newTuple(Type.STR, Type.STR, Type.INT)));
            addFunction("find_module", liburl(), newTuple(Type.STR, Type.STR, Type.INT));

            String[] module_methods = {
                    "load_module", "new_module", "init_builtin", "init_frozen",
                    "load_compiled", "load_dynamic", "load_source"
            };
            for (String mm : module_methods) {
                addFunction(mm, liburl(), newModule("<?>"));
            }

            addUnknownFuncs("acquire_lock", "release_lock");

            addNumAttrs("PY_SOURCE", "PY_COMPILED", "C_EXTENSION",
                    "PKG_DIRECTORY", "C_BUILTIN", "PY_FROZEN", "SEARCH_ERROR");

            addNumFuncs("lock_held", "is_builtin", "is_frozen");

            ClassType impNullImporter = newClass("NullImporter", table, objectType);
            impNullImporter.table.insert("find_module", liburl(), newFunc(Type.NONE), FUNCTION);
            addClass("NullImporter", liburl(), impNullImporter);
        }
    }


    class ItertoolsModule extends NativeModule {
        public ItertoolsModule() {
            super("itertools");
        }


        @Override
        public void initBindings() {
            ClassType iterator = newClass("iterator", table, objectType);
            iterator.table.insert("from_iterable", liburl("itertool-functions"),
                    newFunc(iterator), METHOD);
            iterator.table.insert("next", liburl(), newFunc(), METHOD);

            for (String s : list("chain", "combinations", "count", "cycle",
                    "dropwhile", "groupby", "ifilter",
                    "ifilterfalse", "imap", "islice", "izip",
                    "izip_longest", "permutations", "product",
                    "repeat", "starmap", "takewhile", "tee"))
            {
                addClass(s, liburl("itertool-functions"), iterator);
            }
        }
    }


    class MarshalModule extends NativeModule {
        public MarshalModule() {
            super("marshal");
        }


        @Override
        public void initBindings() {
            addNumAttrs("version");
            addStrFuncs("dumps");
            addUnknownFuncs("dump", "load", "loads");
        }
    }


    class MathModule extends NativeModule {
        public MathModule() {
            super("math");
        }


        @Override
        public void initBindings() {
            addNumFuncs(
                    "acos", "acosh", "asin", "asinh", "atan", "atan2", "atanh", "ceil",
                    "copysign", "cos", "cosh", "degrees", "exp", "fabs", "factorial",
                    "floor", "fmod", "frexp", "fsum", "hypot", "isinf", "isnan",
                    "ldexp", "log", "log10", "log1p", "modf", "pow", "radians", "sin",
                    "sinh", "sqrt", "tan", "tanh", "trunc");
            addNumAttrs("pi", "e");
        }
    }


    class Md5Module extends NativeModule {
        public Md5Module() {
            super("md5");
        }


        @Override
        public void initBindings() {
            addNumAttrs("blocksize", "digest_size");

            ClassType md5 = newClass("md5", table, objectType);
            md5.table.insert("update", liburl(), newFunc(), METHOD);
            md5.table.insert("digest", liburl(), newFunc(Type.STR), METHOD);
            md5.table.insert("hexdigest", liburl(), newFunc(Type.STR), METHOD);
            md5.table.insert("copy", liburl(), newFunc(md5), METHOD);

            update("new", liburl(), newFunc(md5), CONSTRUCTOR);
            update("md5", liburl(), newFunc(md5), CONSTRUCTOR);
        }
    }


    class MmapModule extends NativeModule {
        public MmapModule() {
            super("mmap");
        }


        @Override
        public void initBindings() {
            ClassType mmap = newClass("mmap", table, objectType);

            for (String s : list("ACCESS_COPY", "ACCESS_READ", "ACCESS_WRITE",
                    "ALLOCATIONGRANULARITY", "MAP_ANON", "MAP_ANONYMOUS",
                    "MAP_DENYWRITE", "MAP_EXECUTABLE", "MAP_PRIVATE",
                    "MAP_SHARED", "PAGESIZE", "PROT_EXEC", "PROT_READ",
                    "PROT_WRITE"))
            {
                mmap.table.insert(s, liburl(), Type.INT, ATTRIBUTE);
            }

            for (String fstr : list("read", "read_byte", "readline")) {
                mmap.table.insert(fstr, liburl(), newFunc(Type.STR), METHOD);
            }

            for (String fnum : list("find", "rfind", "tell")) {
                mmap.table.insert(fnum, liburl(), newFunc(Type.INT), METHOD);
            }

            for (String fnone : list("close", "flush", "move", "resize", "seek",
                    "write", "write_byte"))
            {
                mmap.table.insert(fnone, liburl(), newFunc(Type.NONE), METHOD);
            }

            addClass("mmap", liburl(), mmap);
        }
    }


    class NisModule extends NativeModule {
        public NisModule() {
            super("nis");
        }


        @Override
        public void initBindings() {
            addStrFuncs("match", "cat", "get_default_domain");
            addFunction("maps", liburl(), newList(Type.STR));
            addClass("error", liburl(), newException("error", table));
        }
    }


    class OsModule extends NativeModule {
        public OsModule() {
            super("os");
        }


        @Override
        public void initBindings() {
            addAttr("name", liburl(), Type.STR);
            addClass("error", liburl(), newException("error", table));  // XXX: OSError

            initProcBindings();
            initProcMgmtBindings();
            initFileBindings();
            initFileAndDirBindings();
            initMiscSystemInfo();
            initOsPathModule();

            addAttr("errno", liburl(), newModule("errno"));

            addFunction("urandom", liburl("miscellaneous-functions"), Type.STR);
            addAttr("NGROUPS_MAX", liburl(), Type.INT);

            for (String s : list("_Environ", "_copy_reg", "_execvpe", "_exists",
                    "_get_exports_list", "_make_stat_result",
                    "_make_statvfs_result", "_pickle_stat_result",
                    "_pickle_statvfs_result", "_spawnvef"))
            {
                addFunction(s, liburl(), Type.UNKNOWN);
            }
        }


        private void initProcBindings() {
            String a = "process-parameters";

            addAttr("environ", liburl(a), newDict(Type.STR, Type.STR));

            for (String s : list("chdir", "fchdir", "putenv", "setegid", "seteuid",
                    "setgid", "setgroups", "setpgrp", "setpgid",
                    "setreuid", "setregid", "setuid", "unsetenv"))
            {
                addFunction(s, liburl(a), Type.NONE);
            }

            for (String s : list("getegid", "getgid", "getpgid", "getpgrp",
                    "getppid", "getuid", "getsid", "umask"))
            {
                addFunction(s, liburl(a), Type.INT);
            }

            for (String s : list("getcwd", "ctermid", "getlogin", "getenv", "strerror")) {
                addFunction(s, liburl(a), Type.STR);
            }

            addFunction("getgroups", liburl(a), newList(Type.STR));
            addFunction("uname", liburl(a), newTuple(Type.STR, Type.STR, Type.STR,
                    Type.STR, Type.STR));
        }


        private void initProcMgmtBindings() {
            String a = "process-management";

            for (String s : list("EX_CANTCREAT", "EX_CONFIG", "EX_DATAERR",
                    "EX_IOERR", "EX_NOHOST", "EX_NOINPUT",
                    "EX_NOPERM", "EX_NOUSER", "EX_OK", "EX_OSERR",
                    "EX_OSFILE", "EX_PROTOCOL", "EX_SOFTWARE",
                    "EX_TEMPFAIL", "EX_UNAVAILABLE", "EX_USAGE",
                    "P_NOWAIT", "P_NOWAITO", "P_WAIT", "P_DETACH",
                    "P_OVERLAY", "WCONTINUED", "WCOREDUMP",
                    "WEXITSTATUS", "WIFCONTINUED", "WIFEXITED",
                    "WIFSIGNALED", "WIFSTOPPED", "WNOHANG", "WSTOPSIG",
                    "WTERMSIG", "WUNTRACED"))
            {
                addAttr(s, liburl(a), Type.INT);
            }

            for (String s : list("abort", "execl", "execle", "execlp", "execlpe",
                    "execv", "execve", "execvp", "execvpe", "_exit",
                    "kill", "killpg", "plock", "startfile"))
            {
                addFunction(s, liburl(a), Type.NONE);
            }

            for (String s : list("nice", "spawnl", "spawnle", "spawnlp", "spawnlpe",
                    "spawnv", "spawnve", "spawnvp", "spawnvpe", "system"))
            {
                addFunction(s, liburl(a), Type.INT);
            }

            addFunction("fork", liburl(a), newUnion(BaseFileInst, Type.INT));
            addFunction("times", liburl(a), newTuple(Type.INT, Type.INT, Type.INT, Type.INT, Type.INT));

            for (String s : list("forkpty", "wait", "waitpid")) {
                addFunction(s, liburl(a), newTuple(Type.INT, Type.INT));
            }

            for (String s : list("wait3", "wait4")) {
                addFunction(s, liburl(a), newTuple(Type.INT, Type.INT, Type.INT));
            }
        }


        private void initFileBindings() {
            String a = "file-object-creation";

            for (String s : list("fdopen", "popen", "tmpfile")) {
                addFunction(s, liburl(a), BaseFileInst);
            }

            addFunction("popen2", liburl(a), newTuple(BaseFileInst, BaseFileInst));
            addFunction("popen3", liburl(a), newTuple(BaseFileInst, BaseFileInst, BaseFileInst));
            addFunction("popen4", liburl(a), newTuple(BaseFileInst, BaseFileInst));

            a = "file-descriptor-operations";

            addFunction("open", liburl(a), BaseFileInst);

            for (String s : list("close", "closerange", "dup2", "fchmod",
                    "fchown", "fdatasync", "fsync", "ftruncate",
                    "lseek", "tcsetpgrp", "write"))
            {
                addFunction(s, liburl(a), Type.NONE);
            }

            for (String s : list("dup2", "fpathconf", "fstat", "fstatvfs",
                    "isatty", "tcgetpgrp"))
            {
                addFunction(s, liburl(a), Type.INT);
            }

            for (String s : list("read", "ttyname")) {
                addFunction(s, liburl(a), Type.STR);
            }

            for (String s : list("openpty", "pipe", "fstat", "fstatvfs",
                    "isatty"))
            {
                addFunction(s, liburl(a), newTuple(Type.INT, Type.INT));
            }

            for (String s : list("O_APPEND", "O_CREAT", "O_DIRECT", "O_DIRECTORY",
                    "O_DSYNC", "O_EXCL", "O_LARGEFILE", "O_NDELAY",
                    "O_NOCTTY", "O_NOFOLLOW", "O_NONBLOCK", "O_RDONLY",
                    "O_RDWR", "O_RSYNC", "O_SYNC", "O_TRUNC", "O_WRONLY",
                    "SEEK_CUR", "SEEK_END", "SEEK_SET"))
            {
                addAttr(s, liburl(a), Type.INT);
            }
        }


        private void initFileAndDirBindings() {
            String a = "files-and-directories";

            for (String s : list("F_OK", "R_OK", "W_OK", "X_OK")) {
                addAttr(s, liburl(a), Type.INT);
            }

            for (String s : list("chflags", "chroot", "chmod", "chown", "lchflags",
                    "lchmod", "lchown", "link", "mknod", "mkdir",
                    "mkdirs", "remove", "removedirs", "rename", "renames",
                    "rmdir", "symlink", "unlink", "utime"))
            {
                addAttr(s, liburl(a), Type.NONE);
            }

            for (String s : list("access", "lstat", "major", "minor",
                    "makedev", "pathconf", "stat_float_times"))
            {
                addFunction(s, liburl(a), Type.INT);
            }

            for (String s : list("getcwdu", "readlink", "tempnam", "tmpnam")) {
                addFunction(s, liburl(a), Type.STR);
            }

            for (String s : list("listdir")) {
                addFunction(s, liburl(a), newList(Type.STR));
            }

            addFunction("mkfifo", liburl(a), BaseFileInst);

            addFunction("stat", liburl(a), newList(Type.INT));  // XXX: posix.stat_result
            addFunction("statvfs", liburl(a), newList(Type.INT));  // XXX: pos.statvfs_result

            addAttr("pathconf_names", liburl(a), newDict(Type.STR, Type.INT));
            addAttr("TMP_MAX", liburl(a), Type.INT);

            addFunction("walk", liburl(a), newList(newTuple(Type.STR, Type.STR, Type.STR)));
        }


        private void initMiscSystemInfo() {
            String a = "miscellaneous-system-information";

            addAttr("confstr_names", liburl(a), newDict(Type.STR, Type.INT));
            addAttr("sysconf_names", liburl(a), newDict(Type.STR, Type.INT));

            for (String s : list("curdir", "pardir", "sep", "altsep", "extsep",
                    "pathsep", "defpath", "linesep", "devnull"))
            {
                addAttr(s, liburl(a), Type.STR);
            }

            for (String s : list("getloadavg", "sysconf")) {
                addFunction(s, liburl(a), Type.INT);
            }

            addFunction("confstr", liburl(a), Type.STR);
        }


        private void initOsPathModule() {
            ModuleType m = newModule("path");
            State ospath = m.table;
            ospath.setPath("os.path");  // make sure global qnames are correct

            update("path", newLibUrl("os.path.html#module-os.path"), m, MODULE);

            String[] str_funcs = {
                    "_resolve_link", "abspath", "basename", "commonprefix",
                    "dirname", "expanduser", "expandvars", "join",
                    "normcase", "normpath", "realpath", "relpath",
            };
            for (String s : str_funcs) {
                ospath.insert(s, newLibUrl("os.path", s), newFunc(Type.STR), FUNCTION);
            }

            String[] num_funcs = {
                    "exists", "lexists", "getatime", "getctime", "getmtime", "getsize",
                    "isabs", "isdir", "isfile", "islink", "ismount", "samefile",
                    "sameopenfile", "samestat", "supports_unicode_filenames",
            };
            for (String s : num_funcs) {
                ospath.insert(s, newLibUrl("os.path", s), newFunc(Type.INT), FUNCTION);
            }

            for (String s : list("split", "splitdrive", "splitext", "splitunc")) {
                ospath.insert(s, newLibUrl("os.path", s),
                        newFunc(newTuple(Type.STR, Type.STR)), FUNCTION);
            }

            ospath.insert("walk", newLibUrl("os.path"), newFunc(Type.NONE), FUNCTION);

            String[] str_attrs = {
                    "altsep", "curdir", "devnull", "defpath", "pardir", "pathsep", "sep",
            };
            for (String s : str_attrs) {
                ospath.insert(s, newLibUrl("os.path", s), Type.STR, ATTRIBUTE);
            }

            ospath.insert("os", liburl(), this.module, ATTRIBUTE);
            ospath.insert("stat", newLibUrl("stat"),
                    // moduleTable.lookupLocal("stat").getType(),
                    newModule("<stat-fixme>"), ATTRIBUTE);

            // XXX:  this is an re object, I think
            ospath.insert("_varprog", newLibUrl("os.path"), Type.UNKNOWN, ATTRIBUTE);
        }
    }


    class OperatorModule extends NativeModule {
        public OperatorModule() {
            super("operator");
        }


        @Override
        public void initBindings() {
            // XXX:  mark __getslice__, __setslice__ and __delslice__ as deprecated.
            addNumFuncs(
                    "__abs__", "__add__", "__and__", "__concat__", "__contains__",
                    "__div__", "__doc__", "__eq__", "__floordiv__", "__ge__",
                    "__getitem__", "__getslice__", "__gt__", "__iadd__", "__iand__",
                    "__iconcat__", "__idiv__", "__ifloordiv__", "__ilshift__",
                    "__imod__", "__imul__", "__index__", "__inv__", "__invert__",
                    "__ior__", "__ipow__", "__irepeat__", "__irshift__", "__isub__",
                    "__itruediv__", "__ixor__", "__le__", "__lshift__", "__lt__",
                    "__mod__", "__mul__", "__name__", "__ne__", "__neg__", "__not__",
                    "__or__", "__package__", "__pos__", "__pow__", "__repeat__",
                    "__rshift__", "__setitem__", "__setslice__", "__sub__",
                    "__truediv__", "__xor__", "abs", "add", "and_", "concat",
                    "contains", "countOf", "div", "eq", "floordiv", "ge", "getitem",
                    "getslice", "gt", "iadd", "iand", "iconcat", "idiv", "ifloordiv",
                    "ilshift", "imod", "imul", "index", "indexOf", "inv", "invert",
                    "ior", "ipow", "irepeat", "irshift", "isCallable",
                    "isMappingType", "isNumberType", "isSequenceType", "is_",
                    "is_not", "isub", "itruediv", "ixor", "le", "lshift", "lt", "mod",
                    "mul", "ne", "neg", "not_", "or_", "pos", "pow", "repeat",
                    "rshift", "sequenceIncludes", "setitem", "setslice", "sub",
                    "truediv", "truth", "xor");

            addUnknownFuncs("attrgetter", "itemgetter", "methodcaller");
            addNoneFuncs("__delitem__", "__delslice__", "delitem", "delclice");
        }
    }


    class ParserModule extends NativeModule {
        public ParserModule() {
            super("parser");
        }


        @Override
        public void initBindings() {
            ClassType st = newClass("st", table, objectType);
            st.table.insert("compile", newLibUrl("parser", "st-objects"),
                    newFunc(), METHOD);
            st.table.insert("isexpr", newLibUrl("parser", "st-objects"),
                    newFunc(Type.INT), METHOD);
            st.table.insert("issuite", newLibUrl("parser", "st-objects"),
                    newFunc(Type.INT), METHOD);
            st.table.insert("tolist", newLibUrl("parser", "st-objects"),
                    newFunc(newList()), METHOD);
            st.table.insert("totuple", newLibUrl("parser", "st-objects"),
                    newFunc(newTuple()), METHOD);

            addAttr("STType", liburl("st-objects"), BaseType);

            for (String s : list("expr", "suite", "sequence2st", "tuple2st")) {
                addFunction(s, liburl("creating-st-objects"), st);
            }

            addFunction("st2list", liburl("converting-st-objects"), newList());
            addFunction("st2tuple", liburl("converting-st-objects"), newTuple());
            addFunction("compilest", liburl("converting-st-objects"), Type.UNKNOWN);

            addFunction("isexpr", liburl("queries-on-st-objects"), Type.BOOL);
            addFunction("issuite", liburl("queries-on-st-objects"), Type.BOOL);

            addClass("ParserError", liburl("exceptions-and-error-handling"),
                    newException("ParserError", table));
        }
    }


    class PosixModule extends NativeModule {
        public PosixModule() {
            super("posix");
        }


        @Override
        public void initBindings() {
            addAttr("environ", liburl(), newDict(Type.STR, Type.STR));
        }
    }


    class PwdModule extends NativeModule {
        public PwdModule() {
            super("pwd");
        }


        @Override
        public void initBindings() {
            ClassType struct_pwd = newClass("struct_pwd", table, objectType);
            for (String s : list("pw_nam", "pw_passwd", "pw_uid", "pw_gid",
                    "pw_gecos", "pw_dir", "pw_shell"))
            {
                struct_pwd.table.insert(s, liburl(), Type.INT, ATTRIBUTE);
            }
            addAttr("struct_pwd", liburl(), struct_pwd);

            addFunction("getpwuid", liburl(), struct_pwd);
            addFunction("getpwnam", liburl(), struct_pwd);
            addFunction("getpwall", liburl(), newList(struct_pwd));
        }
    }


    class PyexpatModule extends NativeModule {
        public PyexpatModule() {
            super("pyexpat");
        }


        @Override
        public void initBindings() {
            // XXX
        }
    }


    class ReadlineModule extends NativeModule {
        public ReadlineModule() {
            super("readline");
        }


        @Override
        public void initBindings() {
            addNoneFuncs("parse_and_bind", "insert_text", "read_init_file",
                    "read_history_file", "write_history_file",
                    "clear_history", "set_history_length",
                    "remove_history_item", "replace_history_item",
                    "redisplay", "set_startup_hook", "set_pre_input_hook",
                    "set_completer", "set_completer_delims",
                    "set_completion_display_matches_hook", "add_history");

            addNumFuncs("get_history_length", "get_current_history_length",
                    "get_begidx", "get_endidx");

            addStrFuncs("get_line_buffer", "get_history_item");

            addUnknownFuncs("get_completion_type");

            addFunction("get_completer", liburl(), newFunc());
            addFunction("get_completer_delims", liburl(), newList(Type.STR));
        }
    }


    class ResourceModule extends NativeModule {
        public ResourceModule() {
            super("resource");
        }


        @Override
        public void initBindings() {
            addFunction("getrlimit", liburl(), newTuple(Type.INT, Type.INT));
            addFunction("getrlimit", liburl(), Type.UNKNOWN);

            String[] constants = {
                    "RLIMIT_CORE", "RLIMIT_CPU", "RLIMIT_FSIZE", "RLIMIT_DATA",
                    "RLIMIT_STACK", "RLIMIT_RSS", "RLIMIT_NPROC", "RLIMIT_NOFILE",
                    "RLIMIT_OFILE", "RLIMIT_MEMLOCK", "RLIMIT_VMEM", "RLIMIT_AS"
            };
            for (String c : constants) {
                addAttr(c, liburl("resource-limits"), Type.INT);
            }

            ClassType ru = newClass("struct_rusage", table, objectType);
            String[] ru_fields = {
                    "ru_utime", "ru_stime", "ru_maxrss", "ru_ixrss", "ru_idrss",
                    "ru_isrss", "ru_minflt", "ru_majflt", "ru_nswap", "ru_inblock",
                    "ru_oublock", "ru_msgsnd", "ru_msgrcv", "ru_nsignals",
                    "ru_nvcsw", "ru_nivcsw"
            };
            for (String ruf : ru_fields) {
                ru.table.insert(ruf, liburl("resource-usage"), Type.INT, ATTRIBUTE);
            }

            addFunction("getrusage", liburl("resource-usage"), ru);
            addFunction("getpagesize", liburl("resource-usage"), Type.INT);

            for (String s : list("RUSAGE_SELF", "RUSAGE_CHILDREN", "RUSAGE_BOTH")) {
                addAttr(s, liburl("resource-usage"), Type.INT);
            }
        }
    }


    class SelectModule extends NativeModule {
        public SelectModule() {
            super("select");
        }


        @Override
        public void initBindings() {
            addClass("error", liburl(), newException("error", table));

            addFunction("select", liburl(), newTuple(newList(), newList(), newList()));

            String a = "edge-and-level-trigger-polling-epoll-objects";

            ClassType epoll = newClass("epoll", table, objectType);
            epoll.table.insert("close", newLibUrl("select", a), newFunc(Type.NONE), METHOD);
            epoll.table.insert("fileno", newLibUrl("select", a), newFunc(Type.INT), METHOD);
            epoll.table.insert("fromfd", newLibUrl("select", a), newFunc(epoll), METHOD);
            for (String s : list("register", "modify", "unregister", "poll")) {
                epoll.table.insert(s, newLibUrl("select", a), newFunc(), METHOD);
            }
            addClass("epoll", liburl(a), epoll);

            for (String s : list("EPOLLERR", "EPOLLET", "EPOLLHUP", "EPOLLIN", "EPOLLMSG",
                    "EPOLLONESHOT", "EPOLLOUT", "EPOLLPRI", "EPOLLRDBAND",
                    "EPOLLRDNORM", "EPOLLWRBAND", "EPOLLWRNORM"))
            {
                addAttr(s, liburl(a), Type.INT);
            }

            a = "polling-objects";

            ClassType poll = newClass("poll", table, objectType);
            poll.table.insert("register", newLibUrl("select", a), newFunc(), METHOD);
            poll.table.insert("modify", newLibUrl("select", a), newFunc(), METHOD);
            poll.table.insert("unregister", newLibUrl("select", a), newFunc(), METHOD);
            poll.table.insert("poll", newLibUrl("select", a),
                    newFunc(newList(newTuple(Type.INT, Type.INT))), METHOD);
            addClass("poll", liburl(a), poll);

            for (String s : list("POLLERR", "POLLHUP", "POLLIN", "POLLMSG",
                    "POLLNVAL", "POLLOUT", "POLLPRI", "POLLRDBAND",
                    "POLLRDNORM", "POLLWRBAND", "POLLWRNORM"))
            {
                addAttr(s, liburl(a), Type.INT);
            }

            a = "kqueue-objects";

            ClassType kqueue = newClass("kqueue", table, objectType);
            kqueue.table.insert("close", newLibUrl("select", a), newFunc(Type.NONE), METHOD);
            kqueue.table.insert("fileno", newLibUrl("select", a), newFunc(Type.INT), METHOD);
            kqueue.table.insert("fromfd", newLibUrl("select", a), newFunc(kqueue), METHOD);
            kqueue.table.insert("control", newLibUrl("select", a),
                    newFunc(newList(newTuple(Type.INT, Type.INT))), METHOD);
            addClass("kqueue", liburl(a), kqueue);

            a = "kevent-objects";

            ClassType kevent = newClass("kevent", table, objectType);
            for (String s : list("ident", "filter", "flags", "fflags", "data", "udata")) {
                kevent.table.insert(s, newLibUrl("select", a), Type.UNKNOWN, ATTRIBUTE);
            }
            addClass("kevent", liburl(a), kevent);
        }
    }


    class SignalModule extends NativeModule {
        public SignalModule() {
            super("signal");
        }


        @Override
        public void initBindings() {
            addNumAttrs(
                    "NSIG", "SIGABRT", "SIGALRM", "SIGBUS", "SIGCHLD", "SIGCLD",
                    "SIGCONT", "SIGFPE", "SIGHUP", "SIGILL", "SIGINT", "SIGIO",
                    "SIGIOT", "SIGKILL", "SIGPIPE", "SIGPOLL", "SIGPROF", "SIGPWR",
                    "SIGQUIT", "SIGRTMAX", "SIGRTMIN", "SIGSEGV", "SIGSTOP", "SIGSYS",
                    "SIGTERM", "SIGTRAP", "SIGTSTP", "SIGTTIN", "SIGTTOU", "SIGURG",
                    "SIGUSR1", "SIGUSR2", "SIGVTALRM", "SIGWINCH", "SIGXCPU", "SIGXFSZ",
                    "SIG_DFL", "SIG_IGN");

            addUnknownFuncs("default_int_handler", "getsignal", "set_wakeup_fd", "signal");
        }
    }


    class ShaModule extends NativeModule {
        public ShaModule() {
            super("sha");
        }


        @Override
        public void initBindings() {
            addNumAttrs("blocksize", "digest_size");

            ClassType sha = newClass("sha", table, objectType);
            sha.table.insert("update", liburl(), newFunc(), METHOD);
            sha.table.insert("digest", liburl(), newFunc(Type.STR), METHOD);
            sha.table.insert("hexdigest", liburl(), newFunc(Type.STR), METHOD);
            sha.table.insert("copy", liburl(), newFunc(sha), METHOD);
            addClass("sha", liburl(), sha);

            update("new", liburl(), newFunc(sha), CONSTRUCTOR);
        }
    }


    class SpwdModule extends NativeModule {
        public SpwdModule() {
            super("spwd");
        }


        @Override
        public void initBindings() {
            ClassType struct_spwd = newClass("struct_spwd", table, objectType);
            for (String s : list("sp_nam", "sp_pwd", "sp_lstchg", "sp_min",
                    "sp_max", "sp_warn", "sp_inact", "sp_expire",
                    "sp_flag"))
            {
                struct_spwd.table.insert(s, liburl(), Type.INT, ATTRIBUTE);
            }
            addAttr("struct_spwd", liburl(), struct_spwd);

            addFunction("getspnam", liburl(), struct_spwd);
            addFunction("getspall", liburl(), newList(struct_spwd));
        }
    }


    class StropModule extends NativeModule {
        public StropModule() {
            super("strop");
        }


        @Override
        public void initBindings() {
            table.putAll(Type.STR.table);
        }
    }


    class StructModule extends NativeModule {
        public StructModule() {
            super("struct");
        }


        @Override
        public void initBindings() {
            addClass("error", liburl(), newException("error", table));
            addStrFuncs("pack");
            addUnknownFuncs("pack_into");
            addNumFuncs("calcsize");
            addFunction("unpack", liburl(), newTuple());
            addFunction("unpack_from", liburl(), newTuple());

            BaseStruct = newClass("Struct", table, objectType);
            addClass("Struct", liburl("struct-objects"), BaseStruct);
            State t = BaseStruct.table;
            t.insert("pack", liburl("struct-objects"), newFunc(Type.STR), METHOD);
            t.insert("pack_into", liburl("struct-objects"), newFunc(), METHOD);
            t.insert("unpack", liburl("struct-objects"), newFunc(newTuple()), METHOD);
            t.insert("unpack_from", liburl("struct-objects"), newFunc(newTuple()), METHOD);
            t.insert("format", liburl("struct-objects"), Type.STR, ATTRIBUTE);
            t.insert("size", liburl("struct-objects"), Type.INT, ATTRIBUTE);
        }
    }


    class SysModule extends NativeModule {
        public SysModule() {
            super("sys");
        }


        @Override
        public void initBindings() {
            addUnknownFuncs(
                    "_clear_type_cache", "call_tracing", "callstats", "_current_frames",
                    "_getframe", "displayhook", "dont_write_bytecode", "exitfunc",
                    "exc_clear", "exc_info", "excepthook", "exit",
                    "last_traceback", "last_type", "last_value", "modules",
                    "path_hooks", "path_importer_cache", "getprofile", "gettrace",
                    "setcheckinterval", "setprofile", "setrecursionlimit", "settrace");

            addAttr("exc_type", liburl(), Type.NONE);

            addUnknownAttrs("__stderr__", "__stdin__", "__stdout__",
                    "stderr", "stdin", "stdout", "version_info");

            addNumAttrs("api_version", "hexversion", "winver", "maxint", "maxsize",
                    "maxunicode", "py3kwarning", "dllhandle");

            addStrAttrs("platform", "byteorder", "copyright", "prefix", "version",
                    "exec_prefix", "executable");

            addNumFuncs("getrecursionlimit", "getwindowsversion", "getrefcount",
                    "getsizeof", "getcheckinterval");

            addStrFuncs("getdefaultencoding", "getfilesystemencoding");

            for (String s : list("argv", "builtin_module_names", "path",
                    "meta_path", "subversion"))
            {
                addAttr(s, liburl(), newList(Type.STR));
            }

            for (String s : list("flags", "warnoptions", "float_info")) {
                addAttr(s, liburl(), newDict(Type.STR, Type.INT));
            }
        }
    }


    class SyslogModule extends NativeModule {
        public SyslogModule() {
            super("syslog");
        }


        @Override
        public void initBindings() {
            addNoneFuncs("syslog", "openlog", "closelog", "setlogmask");
            addNumAttrs("LOG_ALERT", "LOG_AUTH", "LOG_CONS", "LOG_CRIT", "LOG_CRON",
                    "LOG_DAEMON", "LOG_DEBUG", "LOG_EMERG", "LOG_ERR", "LOG_INFO",
                    "LOG_KERN", "LOG_LOCAL0", "LOG_LOCAL1", "LOG_LOCAL2", "LOG_LOCAL3",
                    "LOG_LOCAL4", "LOG_LOCAL5", "LOG_LOCAL6", "LOG_LOCAL7", "LOG_LPR",
                    "LOG_MAIL", "LOG_MASK", "LOG_NDELAY", "LOG_NEWS", "LOG_NOTICE",
                    "LOG_NOWAIT", "LOG_PERROR", "LOG_PID", "LOG_SYSLOG", "LOG_UPTO",
                    "LOG_USER", "LOG_UUCP", "LOG_WARNING");
        }
    }


    class TermiosModule extends NativeModule {
        public TermiosModule() {
            super("termios");
        }


        @Override
        public void initBindings() {
            addFunction("tcgetattr", liburl(), newList());
            addUnknownFuncs("tcsetattr", "tcsendbreak", "tcdrain", "tcflush", "tcflow");
        }
    }


    class ThreadModule extends NativeModule {
        public ThreadModule() {
            super("thread");
        }


        @Override
        public void initBindings() {
            addClass("error", liburl(), newException("error", table));

            ClassType lock = newClass("lock", table, objectType);
            lock.table.insert("acquire", liburl(), Type.INT, METHOD);
            lock.table.insert("locked", liburl(), Type.INT, METHOD);
            lock.table.insert("release", liburl(), Type.NONE, METHOD);
            addAttr("LockType", liburl(), BaseType);

            addNoneFuncs("interrupt_main", "exit", "exit_thread");
            addNumFuncs("start_new", "start_new_thread", "get_ident", "stack_size");

            addFunction("allocate", liburl(), lock);
            addFunction("allocate_lock", liburl(), lock);  // synonym

            addAttr("_local", liburl(), BaseType);
        }
    }


    class TimeModule extends NativeModule {
        public TimeModule() {
            super("time");
        }


        @Override
        public void initBindings() {
            InstanceType struct_time = Time_struct_time = new InstanceType(newClass("datetime", table, objectType));
            addAttr("struct_time", liburl(), struct_time);

            String[] struct_time_attrs = {
                    "n_fields", "n_sequence_fields", "n_unnamed_fields",
                    "tm_hour", "tm_isdst", "tm_mday", "tm_min",
                    "tm_mon", "tm_wday", "tm_yday", "tm_year",
            };
            for (String s : struct_time_attrs) {
                struct_time.table.insert(s, liburl("struct_time"), Type.INT, ATTRIBUTE);
            }

            addNumAttrs("accept2dyear", "altzone", "daylight", "timezone");

            addAttr("tzname", liburl(), newTuple(Type.STR, Type.STR));
            addNoneFuncs("sleep", "tzset");

            addNumFuncs("clock", "mktime", "time", "tzname");
            addStrFuncs("asctime", "ctime", "strftime");

            addFunctions_beCareful(struct_time, "gmtime", "localtime", "strptime");
        }
    }


    class UnicodedataModule extends NativeModule {
        public UnicodedataModule() {
            super("unicodedata");
        }


        @Override
        public void initBindings() {
            addNumFuncs("decimal", "digit", "numeric", "combining",
                    "east_asian_width", "mirrored");
            addStrFuncs("lookup", "name", "category", "bidirectional",
                    "decomposition", "normalize");
            addNumAttrs("unidata_version");
            addUnknownAttrs("ucd_3_2_0");
        }
    }


    class ZipimportModule extends NativeModule {
        public ZipimportModule() {
            super("zipimport");
        }


        @Override
        public void initBindings() {
            addClass("ZipImportError", liburl(), newException("ZipImportError", table));

            ClassType zipimporter = newClass("zipimporter", table, objectType);
            State t = zipimporter.table;
            t.insert("find_module", liburl(), zipimporter, METHOD);
            t.insert("get_code", liburl(), Type.UNKNOWN, METHOD);  // XXX:  code object
            t.insert("get_data", liburl(), Type.UNKNOWN, METHOD);
            t.insert("get_source", liburl(), Type.STR, METHOD);
            t.insert("is_package", liburl(), Type.INT, METHOD);
            t.insert("load_module", liburl(), newModule("<?>"), METHOD);
            t.insert("archive", liburl(), Type.STR, ATTRIBUTE);
            t.insert("prefix", liburl(), Type.STR, ATTRIBUTE);

            addClass("zipimporter", liburl(), zipimporter);
            addAttr("_zip_directory_cache", liburl(), newDict(Type.STR, Type.UNKNOWN));
        }
    }


    class ZlibModule extends NativeModule {
        public ZlibModule() {
            super("zlib");
        }


        @Override
        public void initBindings() {
            ClassType compress = newClass("Compress", table, objectType);
            for (String s : list("compress", "flush")) {
                compress.table.insert(s, newLibUrl("zlib"), Type.STR, METHOD);
            }
            compress.table.insert("copy", newLibUrl("zlib"), compress, METHOD);
            addClass("Compress", liburl(), compress);

            ClassType decompress = newClass("Decompress", table, objectType);
            for (String s : list("unused_data", "unconsumed_tail")) {
                decompress.table.insert(s, newLibUrl("zlib"), Type.STR, ATTRIBUTE);
            }
            for (String s : list("decompress", "flush")) {
                decompress.table.insert(s, newLibUrl("zlib"), Type.STR, METHOD);
            }
            decompress.table.insert("copy", newLibUrl("zlib"), decompress, METHOD);
            addClass("Decompress", liburl(), decompress);

            addFunction("adler32", liburl(), Type.INT);
            addFunction("compress", liburl(), Type.STR);
            addFunction("compressobj", liburl(), compress);
            addFunction("crc32", liburl(), Type.INT);
            addFunction("decompress", liburl(), Type.STR);
            addFunction("decompressobj", liburl(), decompress);
        }
    }
}

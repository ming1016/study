package org.yinwang.pysonar.ast;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.yinwang.pysonar.Analyzer;
import org.yinwang.pysonar.Binding;
import org.yinwang.pysonar.State;
import org.yinwang.pysonar.types.ListType;
import org.yinwang.pysonar.types.Type;

import java.util.ArrayList;
import java.util.List;
import java.util.Map.Entry;
import java.util.Set;


public class ImportFrom extends Node {

    public List<Name> module;
    public List<Alias> names;
    public int level;


    public ImportFrom(List<Name> module, List<Alias> names, int level, String file, int start, int end) {
        super(file, start, end);
        this.module = module;
        this.level = level;
        this.names = names;
        addChildren(names);
    }


    @NotNull
    @Override
    public Type transform(@NotNull State s) {
        if (module == null) {
            return Type.CONT;
        }

        Type mod = Analyzer.self.loadModule(module, s);

        if (mod == null) {
            Analyzer.self.putProblem(this, "Cannot load module");
        } else if (isImportStar()) {
            importStar(s, mod);
        } else {
            for (Alias a : names) {
                Name first = a.name.get(0);
                Set<Binding> bs = mod.table.lookup(first.id);
                if (bs != null) {
                    if (a.asname != null) {
                        s.update(a.asname.id, bs);
                        Analyzer.self.putRef(a.asname, bs);
                    } else {
                        s.update(first.id, bs);
                        Analyzer.self.putRef(first, bs);
                    }
                } else {
                    List<Name> ext = new ArrayList<>(module);
                    ext.add(first);
                    Type mod2 = Analyzer.self.loadModule(ext, s);
                    if (mod2 != null) {
                        if (a.asname != null) {
                            s.insert(a.asname.id, a.asname, mod2, Binding.Kind.VARIABLE);
                        } else {
                            s.insert(first.id, first, mod2, Binding.Kind.VARIABLE);
                        }
                    }
                }
            }
        }

        return Type.CONT;
    }


    public boolean isImportStar() {
        return names.size() == 1 && "*".equals(names.get(0).name.get(0).id);
    }


    private void importStar(@NotNull State s, @Nullable Type mt) {
        if (mt == null || mt.file == null) {
            return;
        }

        Node node = Analyzer.self.getAstForFile(mt.file);
        if (node == null) {
            return;
        }

        List<String> names = new ArrayList<>();
        Type allType = mt.table.lookupType("__all__");

        if (allType != null && allType instanceof ListType) {
            ListType lt = (ListType) allType;

            for (Object o : lt.values) {
                if (o instanceof String) {
                    names.add((String) o);
                }
            }
        }

        if (!names.isEmpty()) {
            int start = this.start;

            for (String name : names) {
                Set<Binding> b = mt.table.lookupLocal(name);
                if (b != null) {
                    s.update(name, b);
                } else {
                    List<Name> m2 = new ArrayList<>(module);
                    Name fakeName = new Name(name, this.file, start, start + name.length());
                    m2.add(fakeName);
                    Type type = Analyzer.self.loadModule(m2, s);
                    if (type != null) {
                        start += name.length();
                        s.insert(name, fakeName, type, Binding.Kind.VARIABLE);
                    }
                }
            }
        } else {
            // Fall back to importing all names not starting with "_".
            for (Entry<String, Set<Binding>> e : mt.table.entrySet()) {
                if (!e.getKey().startsWith("_")) {
                    s.update(e.getKey(), e.getValue());
                }
            }
        }
    }


    @NotNull
    @Override
    public String toString() {
        return "<FromImport:" + module + ":" + names + ">";
    }

}

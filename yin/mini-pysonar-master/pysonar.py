# pysonar.py - a Python version of PySonar static analyzer for Python
# Copyright (C) 2011 Yin Wang (yinwang0@gmail.com)

import sys
import re
from ast import *
from lists import *




####################################################################
## global parameters
####################################################################
IS = isinstance



####################################################################
## utilities
####################################################################
def iter_fields(node):
    """Iterate over all existing fields, excluding 'ctx'."""
    for field in node._fields:
        try:
            if field <> 'ctx':
                yield field, getattr(node, field)
        except AttributeError:
            pass

# for debugging
def sz(s):
    return nodeSize(parse(s), True)

def dp(s):
    return map(dump, parse(s).body)

def pf(file):
    import cProfile
    cProfile.run("sonar(" + file + ")", sort="cumulative")



####################################################################
## test on AST nodes
####################################################################
def isAtom(x):
    return type(x) in [int, str, bool, float]

def isDef(node):
    return IS(node, FunctionDef) or IS(node, ClassDef)




##################################################################
# per-node information store
##################################################################
history = {}
def putInfo(exp, item):
    if history.has_key(exp):
        seen = history[exp]
    else:
        seen = []
    history[exp] = union([seen, item])


def getInfo(exp):
    return history[exp]




##################################################################
# types used by pysonar
##################################################################
class Type:
    pass


nUnknown = 0
class UnknownType(Type):
    def __init__(self, name=None):
        global nUnknown
        if name <> None:
            self.name = name + str(nUnknown)
        else:
            self.name = '_' + str(nUnknown)
        nUnknown += 1
    def __repr__(self):
        return str(self.name)


class PrimType(Type):
    def __init__(self, name):
        self.name = name
    def __repr__(self):
        return str(self.name)
    def __eq__(self, other):
        if IS(other, PrimType):
            return self.name == other.name
        else:
            return False
    def __ne__(self, other):
        return not self.__eq__(other)


class ClassType(Type):
    def __init__(self, name):
        self.name = name
    def __repr__(self):
        return "class:" + self.name
    def __eq__(self, other):
        if IS(other, ClassType):
            return self.name == other.name
        else:
            return False
    def __ne__(self, other):
        return not self.__eq__(other)


class FuncType(Type):
    def __init__(self, fromtype, totype):
        self.fromtype = fromtype
        self.totype = totype
    def __repr__(self):
        return str(self.fromtype) + " -> " + str(self.totype)
    def __eq__(self, other):
        if IS(other, FuncType):
            return ((self.fromtype == other.fromtype) and
                    self.totype == other.totype)
        else:
            return False
    def __ne__(self, other):
        return not self.__eq__(other)


class Closure(Type):
    def __init__(self, func, env):
        self.func = func
        self.env = env
        self.defaults = []
    def __repr__(self):
        return str(self.func)


class TupleType(Type):
    def __init__(self, elts):
        self.elts = elts
    def __repr__(self):
        return "tup:" + str(self.elts)
    def __eq__(self, other):
        if IS(other, TupleType):
            if len(self.elts) <> len(other.elts):
                return False
            else:
                for i in xrange(len(self.elts)):
                    if self.elts[i] <> other.elts[i]:
                        return False
                return True
        else:
            return False
    def __ne__(self, other):
        return not self.__eq__(other)


class ListType(Type):
    def __init__(self, elts):
        self.elts = elts
    def __repr__(self):
        return "list:" + str(self.elts)
    def __eq__(self, other):
        if IS(other, ListType):
            if len(self.elts) <> len(other.elts):
                return False
            else:
                for i in xrange(len(self.elts)):
                    if self.elts[i] <> other.elts[i]:
                        return False
                return True
        else:
            return False
    def __ne__(self, other):
        return not self.__eq__(other)


class DictType(Type):
    def __init__(self, dic):
        self.dic = dic
    def __repr__(self):
        return "dict:" + str(self.dic)

    # any hashable value can be used as keys
    # any object can be used as values
    # so we can know almost nothing about the dictionaries
    def __eq__(self, other):
        if IS(other, DictType):
            return True
        else:
            return False
    def __ne__(self, other):
        return not self.__eq__(other)


class UnionType(Type):
    def __init__(self, elts):
        self.elts = elts
    def __repr__(self):
        return "U:" + str(self.elts)


# singleton primtive types
contType = PrimType('cont')             # continuation type
bottomType = PrimType('_|_')            # non-terminating recursion


# need to rewrite this when we have recursive types
def typeEqual(t1, t2):
    if IS(t1, list) and IS(t2, list):
        for bd1 in t1:
            if bd1 not in t2:
                return False
        return True
    else:
        return t1 == t2


def subtypeBindings(rec1, rec2):
    def find(a, rec2):
        for b in rec2:
            if (first(a) == first(b)) and typeEqual(rest(a), rest(b)):
                return True
        return False
    for a in rec1:
        if not find(a, rec2):
            return False
    return True


def union(ts):
    u = []
    for t in ts:
        if IS(t, list):                 # already a union (list)
            for b in t:
                if b not in u:
                    u.append(b)
        else:
            if t not in u:
                u.append(t)
    return u



####################################################################
## type inferencer
####################################################################
class Bind:
    def __init__(self, typ, loc):
        self.typ = typ
        self.loc = loc
    def __repr__(self):
        return "(" + str(self.typ) + " <~~ " + str(self.loc) + ")"
    def __iter__(self):
        return BindIterator(self)
    def __eq__(self, other):
        return (IS(other, Bind) and
                self.typ == other.typ and
                self.loc == other.loc)


class BindIterator:
    def __init__(self, p):
        self.p = p
        self.cur = 0
    def next(self):
        if self.cur == 2:
            raise StopIteration
        elif self.cur == 0:
            self.cur += 1
            return self.p.typ
        else:
            self.cur += 1
            return self.p.loc


def typeOnly(bs):
    return union(bs)


# test whether a type is in a union
def inUnion(t, u):
    for t2 in u:
        if t == t2:
            return True
    return False


def removeType(t, u):
    return filter(lambda x: x <> t, u)


# combine two environments, make unions when necessary
# only assocs appear in both envs are preserved
# use a variable bound in only one branch will cause type error
def mergeEnv(env1, env2):
    ret = nil
    for p1 in env1:
        p2 = assq(first(p1), env2)
        if p2 <> None:
            ret = ext(first(p1), union([rest(p1), rest(p2)]), ret)
    return ret


# compare both str's and Name's for equivalence, because
# keywords are str's (bad design of the ast)
def getId(x):
    if IS(x, Name):
        return x.id
    else:
        return x


def bind(target, value, env):
    if IS(target, Name) or IS(target, str):
        u = value
        putInfo(target, u)
        return ext(getId(target), u, env)

    # ignored for now
    # elif IS(target, Tuple) or IS(target, List):
    #     if IS(value, TupleType) or IS(value, List):
    #         if len(target.elts) == len(value.elts):
    #             for i in xrange(len(value.elts)):
    #                 env = bind(target.elts[i], value.elts[i], env)
    #             return env
    #         elif len(target.elts) < len(value.elts):
    #             putInfo(target, ValueError('too many values to unpack'))
    #             return env
    #         else:
    #             putInfo(target, ValueError('too few values to unpack'))
    #             return env
    #     else:
    #         putInfo(value, TypeError('non-iterable object'))
    #         return env
    else:
        putInfo(target, SyntaxError("not assignable"))
        return env


def onStack(call, args, stk):
    for p1 in stk:
        call2 = first(p1)
        args2 = rest(p1)
        if call == call2 and subtypeBindings(args, args2):
            return True
    return False


# invoke one closure
def invoke1(call, clo, env, stk):

    if (clo == bottomType):
        return [bottomType]

    # Even if operator is not a closure, resolve the
    # arguments for partial information.
    if not IS(clo, Closure):
        for a in call.args:
            t1 = infer(a, env, stk)
        for k in call.keywords:
            t2 = infer(k.value, env, stk)
        err = TypeError('calling non-callable', clo)
        putInfo(call, err)
        return [err]

    func = clo.func
    fenv = clo.env
    pos = nil
    kwarg = nil

    # bind positionals first
    poslen = min(len(func.args.args), len(call.args))
    for i in xrange(poslen):
        t = infer(call.args[i], env, stk)
        pos = bind(func.args.args[i], t, pos)

    # put extra positionals into vararg if provided
    # report error and go on otherwise
    if len(call.args) > len(func.args.args):
        if func.args.vararg == None:
            err = TypeError('excess arguments to function')
            putInfo(call, err)
            return [err]
        else:
            ts = []
            for i in xrange(len(func.args.args), len(call.args)):
                t = infer(call.args[i], env, stk)
                ts = ts + t
            pos = bind(func.args.vararg, ts, pos)

    # bind keywords, collect kwarg
    ids = map(getId, func.args.args)
    for k in call.keywords:
        ts = infer(k.value, env, stk)
        tloc1 = lookup(k.arg, pos)
        if tloc1 <> None:
            putInfo(call, TypeError('multiple values for keyword argument',
                                     k.arg, loc))
        elif k.arg not in ids:
            kwarg = bind(k.arg, ts, kwarg)
        else:
            pos = bind(k.arg, ts, pos)

    # put extras in kwarg or report them
    if kwarg <> nil:
        if func.args.kwarg <> None:
            pos = bind(func.args.kwarg,
                       DictType(reverse(kwarg)),
                       pos)
        else:
            putInfo(call, TypeError("unexpected keyword arguements", kwarg))
    elif func.args.kwarg <> None:
        pos = bind(func.args.kwarg, DictType(nil), pos)

    # bind defaults, avoid overwriting bound vars
    # types for defaults are already inferred when the function was defined
    i = len(func.args.args) - len(func.args.defaults)
    ndefaults = len(func.args.args)
    for j in xrange(len(clo.defaults)):
        tloc = lookup(getId(func.args.args[i]), pos)
        if tloc == None:
            pos = bind(func.args.args[i], clo.defaults[j], pos)
            i += 1

    # finish building the input type
    fromtype = maplist(lambda p: Pair(first(p), typeOnly(rest(p))), pos)

    # check whether the same call site is on stack with same input types
    # if so, we are back to a loop, terminate
    if onStack(call, fromtype, stk):
        return [bottomType]

    # push the call site onto the stack and analyze the function body
    stk = ext(call, fromtype, stk)
    fenv = append(pos, fenv)
    to = infer(func.body, fenv, stk)

    # record the function type
    putInfo(func, FuncType(reverse(fromtype), to))
    return to



# invoke a union of closures. call invoke1 on each of them and collect
# their return types into a union
def invoke(call, env, stk):
    clos = infer(call.func, env, stk)
    totypes = []
    for clo in clos:
        t = invoke1(call, clo, env, stk)
        totypes = totypes + t
    return totypes



# pre-bind names to functions in sequences (should add classes later)
def close(ls, env):
    for e in ls:
        if IS(e, FunctionDef):
            c = Closure(e, None)
            env = ext(e.name, [c], env)
    return env



def isTerminating(t):
    return not inUnion(contType, t)


def finalize(t):
    return removeType(contType, t)



# infer a sequence of statements
def inferSeq(exp, env, stk):

    if exp == []:                       # reached end without return
        return ([contType], env)

    e = exp[0]
    if IS(e, If):
        tt = infer(e.test, env, stk)
        (t1, env1) = inferSeq(e.body, close(e.body, env), stk)
        (t2, env2) = inferSeq(e.orelse, close(e.orelse, env), stk)

        if isTerminating(t1) and isTerminating(t2):                   # both terminates
            for e2 in exp[1:]:
                putInfo(e2, TypeError('unreachable code'))
            return (union([t1, t2]), env)

        elif isTerminating(t1) and not isTerminating(t2):             # t1 terminates
            (t3, env3) = inferSeq(exp[1:], env2, stk)
            t2 = finalize(t2)
            return (union([t1, t2, t3]), env3)

        elif not isTerminating(t1) and isTerminating(t2):             # t2 terminates
            (t3, env3) = inferSeq(exp[1:], env1, stk)
            t1 = finalize(t1)
            return (union([t1, t2, t3]), env3)
        else:                                                         # both non-terminating
            (t3, env3) = inferSeq(exp[1:], mergeEnv(env1, env2), stk)
            t1 = finalize(t1)
            t2 = finalize(t2)
            return (union([t1, t2, t3]), env3)

    elif IS(e, Assign):
        t = infer(e.value, env, stk)
        for x in e.targets:
            env = bind(x, t, env)
        return inferSeq(exp[1:], env, stk)

    elif IS(e, FunctionDef):
        cs = lookup(e.name, env)
        for c in cs:
            c.env = env                          # create circular env to support recursion
        for d in e.args.defaults:                # infer types for default arguments
            dt = infer(d, env, stk)
            c.defaults.append(dt)
        return inferSeq(exp[1:], env, stk)

    elif IS(e, Return):
        t1 = infer(e.value, env, stk)
        (t2, env2) = inferSeq(exp[1:], env, stk)
        for e2 in exp[1:] :
            putInfo(e2, TypeError('unreachable code'))
        return (t1, env)

    elif IS(e, Expr):
        t1 = infer(e.value, env, stk)
        return inferSeq(exp[1:], env, stk)

    else:
        raise TypeError('recognized node in effect context', e)



# main type inferencer
def infer(exp, env, stk):

    if IS(exp, Module):
        return infer(exp.body, env, stk)

    elif IS(exp, list):
        env = close(exp, env)
        (t, ignoreEnv) = inferSeq(exp, env, stk)    # env ignored (out of scope)
        return t

    elif IS(exp, Num):
        return [PrimType(type(exp.n))]

    elif IS(exp, Str):
        return [PrimType(type(exp.s))]

    elif IS(exp, Name):
        b = lookup(exp.id, env)
        if (b <> None):
            putInfo(exp, b)
            return b
        else:
            try:
                t = type(eval(exp.id))     # try use information from Python interpreter
                return [PrimType(t)]
            except NameError as err:
                putInfo(exp, err)
                return [err]

    elif IS(exp, Lambda):
        c = Closure(exp, env)
        for d in exp.args.defaults:
            dt = infer(d, env, stk)
            c.defaults.append(dt)
        return [c]

    elif IS(exp, Call):
        return invoke(exp, env, stk)

    ## ignore complex types for now
    # elif IS(exp, List):
    #     eltTypes = []
    #     for e in exp.elts:
    #         t = infer(e, env, stk)
    #         eltTypes.append(t)
    #     return [Bind(ListType(eltTypes), exp)]

    # elif IS(exp, Tuple):
    #     eltTypes = []
    #     for e in exp.elts:
    #         t = infer(e, env, stk)
    #         eltTypes.append(t)
    #     return [Bind(TupleType(eltTypes), exp)]

    else:
        return [UnknownType()]



##################################################################
# drivers(wrappers)
##################################################################
def parseFile(filename):
    f = open(filename, 'r');
    return parse(f.read())


# clean up globals
def clear():
    history.clear()
    global nUnknown
    nUnknown = 0


def nodekey(node):
    if hasattr(node, 'lineno'):
        return node.lineno
    else:
        return sys.maxint


# check a single (parsed) expression
def checkExp(exp):
    clear()
    ret = infer(exp, nil, nil)
    if history.keys() <> []:
        print "---------------------------- history ----------------------------"
        for k in sorted(history.keys(), key=nodekey):
            print(k, ":", history[k])
        print("\n")


# check a string
def checkString(s):
    return checkExp(parse(s))


# check a file
def checkFile(filename):
    f = open(filename, 'r');
    checkString(f.read())



###################################################################
# hacky printing support for AST
###################################################################
def dump(node, annotate_fields=True, include_attributes=False):
    def _format(node):
        if isinstance(node, AST):
            fields = [(a, _format(b)) for a, b in iter_fields(node)]
            rv = '%s(%s' % (node.__class__.__name__, ', '.join(
                ('%s=%s' % field for field in fields)
                if annotate_fields else
                (b for a, b in fields)
            ))
            if include_attributes and node._attributes:
                rv += fields and ', ' or ' '
                rv += ', '.join('%s=%s' % (a, _format(getattr(node, a)))
                                for a in node._attributes)
            return rv + ')'
        elif isinstance(node, list):
            return '[%s]' % ', '.join(_format(x) for x in node)
        return repr(node)
    if not isinstance(node, AST):
        raise TypeError('expected AST, got %r' % node.__class__.__name__)
    return _format(node)


def printList(ls):
    if (ls == None or ls == []):
        return ""
    elif (len(ls) == 1):
        return str(ls[0])
    else:
        return str(ls)


def printAst(node):
    if (IS(node, Module)):
        ret = "module:" + str(node.body)
    elif (IS(node, FunctionDef)):
        ret = "fun:" + str(node.name)
    elif (IS(node, ClassDef)):
        ret = "class:" + str(node.name)
    elif (IS(node, Call)):
        ret = ("call:" + str(node.func)
               + ":(" + printList(node.args) + ")")
    elif (IS(node, Assign)):
        ret = ("(" + printList(node.targets)
               + " <- " + printAst(node.value) + ")")
    elif (IS(node, If)):
        ret = ("if " + str(node.test)
               + ":" + printList(node.body)
               + ":" + printList(node.orelse))
    elif (IS(node, Compare)):
        ret = (str(node.left) + ":" + printList(node.ops)
               + ":" + printList(node.comparators))
    elif (IS(node, Name)):
        ret = str(node.id)
    elif (IS(node, Num)):
        ret = str(node.n)
    elif (IS(node, Str)):
        ret = '"' + str(node.s) + '"'
    elif (IS(node, Return)):
        ret = "return " + repr(node.value)
    elif (IS(node, Print)):
        ret = ("print(" + (str(node.dest)
               + ", " if (node.dest!=None) else "")
               + printList(node.values) + ")")
    elif (IS(node, Expr)):
        ret = "expr:" + str(node.value)
    elif (IS(node, BinOp)):
        ret = (str(node.left) + " "
               + str(node.op) + " "
               + str(node.right))
    elif (IS(node, Mult)):
        ret = '*'
    elif (IS(node, Add)):
        ret = '+'
    elif (IS(node, Pass)):
        ret = "pass"
    elif IS(node,list):
        ret = printList(node)
    else:
        ret = str(type(node))

    if hasattr(node, 'lineno'):
        return (re.sub("@[0-9]+", '', ret)
                + "@" + str(node.lineno))
    else:
        return ret


def installPrinter():
    import inspect
    import ast
    for name, obj in inspect.getmembers(ast):
        if (inspect.isclass(obj) and not (obj == AST)):
            obj.__repr__ = printAst

installPrinter()


# test the checker on a file
checkFile('tests/chain.py')

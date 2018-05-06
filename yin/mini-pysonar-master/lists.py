# pysonar.py - a Python version of PySonar static analyzer for Python
# Copyright (C) 2011 Yin Wang (yinwang0@gmail.com)



#-------------------------------------------------------------
# a library for Lisp lists
#-------------------------------------------------------------

class PairIterator:
    def __init__(self, p):
        self.p = p
    def next(self):
        if self.p == nil:
            raise StopIteration
        ret = self.p.fst
        self.p = self.p.snd
        return ret

class Nil:
    def __repr__(self):
        return "()"
    def __iter__(self):
        return PairIterator(self)

nil = Nil()

class Pair:
    def __init__(self, fst, snd):
        self.fst = fst
        self.snd = snd
    def __repr__(self):
        if (self.snd == nil):
            return "(" + repr(self.fst) + ")"
        elif (isinstance(self.snd, Pair)):
            s = repr(self.snd)
            return "(" + repr(self.fst) + " " + s[1:-1] + ")"
        else:
            return "(" + repr(self.fst) + " . " + repr(self.snd) + ")"
    def __iter__(self):
        return PairIterator(self)
    def __eq__(self, other):
        if not isinstance(other, Pair):
            return False
        else:
            return self.fst == other.fst and self.snd == other.snd

def first(p):
    return p.fst

def rest(p):
    return p.snd


def loner(u):
    return Pair(u, nil)


def foldl(f, x, ls):
    ret = x
    for y in ls:
        ret = f(ret, y)
    return ret

def length(ls):
    ret = 0
    for x in ls:
        ret = ret + 1
    return ret

def remove(x, ls):
    ret = nil
    for y in ls:
        if x <> y:
            ret = Pair(y, ret)
    return reverse(ret)

def assoc(u, v):
    return Pair(Pair(u, v), nil)

def slist(pylist):
    ret = nil
    for i in xrange(len(pylist)):
        ret = Pair(pylist[len(pylist)-i-1], ret)
    return ret

def pylist(ls):
    ret = []
    for x in ls:
        ret.append(x)
    return ret


def maplist(f, ls):
    ret = nil
    for x in ls:
        ret = Pair(f(x), ret)
    return reverse(ret)


def reverse(ls):
    ret = nil
    for x in ls:
        ret = Pair(x, ret)
    return ret


def filterlist(f, ls):
    ret = nil
    for x in ls:
        if f(x):
            ret = Pair(x, ret)
    return reverse(ret)


def append(*lists):    
    def append1(ls1, ls2):
        ret = ls2
        for x in ls1:
            ret = Pair(x, ret)
        return ret
    return foldl(append1, nil, slist(lists))


def assq(x, s):
    for p in s:
        if x == first(p):
            return p
    return None


def ziplist(ls1, ls2):
    ret = nil
    while ls1 <> nil and ls2 <> nil:
        ret = Pair(Pair(first(ls1), first(ls2)), ret)
        ls1 = rest(ls1)
        ls2 = rest(ls2)
    return reverse(ret)


# building association lists
def ext(x, v, s):
    return Pair(Pair(x, v), s)


def lookup(x, s):
    p = assq(x, s)
    if p <> None:
        return rest(p)
    else:
        return None


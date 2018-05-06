class A:
    a = 1

class B:
    a = A()

class C:
    a = B()

o = C()

def f(x):
    return x.a

f(o)

def g(x):
    return x.a

g(g(o))

def h(x):
    return x.a

h(h(h(o)))

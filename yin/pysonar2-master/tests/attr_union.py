class A:
  a = 1

class B:
  a = 'hi'

x = A()
x = B()

print x.a

Y = A
Y = B
Y.b = 3
o = Y()

print o.b

u = A()
def f():
  u = B()
  global u

print u

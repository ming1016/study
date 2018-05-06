class A:
  x = 1
  def f(self):
    self.y = 2
  def g(self):
    print self.y

o1 = A()
o1.f()
o1.g()
print o1.y

o2 = A()
# o2.g()
# print o2.y

print A.__dict__
print o1.__dict__
print o2.__dict__

print A.g.im_class

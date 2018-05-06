class A:
  a = 1

def util(create):
  return create.a
z = lambda:util(create=A())
y = z()
print y

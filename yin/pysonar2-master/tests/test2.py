def util(create):
  return create()
z = lambda:util(create=lambda: str())
y = z()

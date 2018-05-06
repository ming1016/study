def foo(arg=lambda name: name + '!'):
  x = arg('hi')
  print x.lower()

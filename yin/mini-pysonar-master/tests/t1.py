def f(x):
    z = f(True)
    w = f("foo")
    return z

return f(1)


# (('y' . (int=4@3, y@1)) ('x' . (int=3@3, x@1))) -> tup:[int=3@3, int=4@3],
# (('y' . (int=2@2, y@1)) ('x' . (bool=False, x@1))) -> tup:[bool=False, int=2@2],
# (('y' . (int=2@2, y@1)) ('x' . (bool=False, x@1))) -> tup:[bool=False, int=2@2],
# (('y' . (int=4@3, y@1)) ('x' . (int=3@3, x@1))) -> tup:[int=3@3, int=4@3],
# (('y' . (bool=True, y@1)) ('x' . (int=1@6, x@1))) -> tup:[int=1@6, bool=True]

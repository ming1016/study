def app(f, e):
    return f(e)

def id(x):
    return x

n1 = app(id, 1)
n2 = app(id, 2)


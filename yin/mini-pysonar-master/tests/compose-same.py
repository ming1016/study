def composesame(f, x):
    return f(f(x))

def g(x):
    return 0

composesame(g, 1)


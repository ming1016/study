x = 1

def f():
    global x
    x = 'hi'
    print x


def g():
    x = 'hi'
    print x
    global x

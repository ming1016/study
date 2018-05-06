## (\x.xxx)(\x.xxx)
# def f(x):
#     return x(x)(x)

# f(f)


## (\x.xx)(\x.xx)
# def f(x):
#     return x(x)

# f(f)


def g(x):
    if x:
        return 1
    else:
        return g(x)

g(2)

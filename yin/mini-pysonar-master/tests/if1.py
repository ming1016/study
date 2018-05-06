def f(x):
    if x:
        return True
    elif 0:
        return 1
    else:
        return f(x)

return f(2)


# f will not show up in the index because there is no path it can return
def f(x, *y, **kw):
    if x < 1:
        return 1
    elif x < 5:
        tt = kw
        return f(x, y)
    else:
        return f(y, x)

z = f(1, True, 'ok', z=1, w=2)


# knife is not exported
__all__ = ["spoon", "fork"]


def spoon(x):
    return x


def fork(x):
    return [x,x]


# knife is not exported
def knife(x):
    return x+1

# missing return statement
# - can be at any depth
# - we will track down all sources of missing returns

def f(x):

    if x:
        return 1
    else:
        z = 10

    if x:
        return 1
    elif x:
        if x:
            y = 2
#            return 2
        else:
            y = 1
    else:
        return 'ok'

#    z = y

#    return 'pig'
    
t = f(0)


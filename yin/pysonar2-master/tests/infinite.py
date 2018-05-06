class Halting:
    z = 1

class Problem:
    z = Halting()

class Solved:
    z = Problem()

o3 = Solved()

def f(x):
  f(x.z) # move cursor to 'z' will highlight all three 'z' fields above and one error message

f(o3)

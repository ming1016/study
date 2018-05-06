class A5:
   w = 1

class B5:
   w = 'cherry'

ls = [A5(), A5()]
ls[1] = B5()         # Here the type of list 'ls' is "[{A5 | B5}]" meaning "a list of A5 or B5"

print ls[0].w


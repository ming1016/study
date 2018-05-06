# (lambda (id h) (id 1 (lambda (n1) (id 2 (lambda (n2) (h n2))))))


# (lambda (id, h): id(1, (lambda n1: id(2, (lambda n2: h(n2)))))) (lambda (x, k): k(x), lambda x: 0)

(lambda x: x(x)) (lambda x: x(x))


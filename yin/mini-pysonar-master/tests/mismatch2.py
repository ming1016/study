# (let ((f (lambda (x thunk) (if (number? x) (thunk) (lambda() x)))))
# (f 0 (f "foo" "bar")))

def f(x, thunk):
    if x > 0:
        return thunk()
    else:
        return lambda: x

f(0, f("foo", "bar"))


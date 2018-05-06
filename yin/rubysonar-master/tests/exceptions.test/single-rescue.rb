def ok(y)
  y
end


def foo(x)
  bar(x) rescue ok 0
end

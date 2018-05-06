def foo(f, &block)
  block(10)
end


# foo { |x| x }


def bar(x, &block)
  foo(x, &block)
end

bar(42) { |x| x }


def baz(*args, &block)
  foo(*args, &block)
end

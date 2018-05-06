# ------------- class method -----------------
class A
  class << self
    def foo
      "class method foo"
    end
  end
end

puts A.foo
ao = A.new
puts ao.foo    # shouldn't find

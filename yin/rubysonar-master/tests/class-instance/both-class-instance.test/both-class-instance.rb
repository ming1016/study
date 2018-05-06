# ------------- class and instance methods with same name -----------------
class C
  class << self
    def foo
      "class method foo"
    end
  end

  def foo
    "instance method foo"
  end
end

puts C.foo   # refer to the first foo
co = C.new
puts co.foo  # refer to the second foo

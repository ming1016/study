class A
  def foo
    puts 'this is foo'
  end
end

A.baz  # not there


class B
  class << self
    def bar
      puts 'this is bar'
    end
  end
end

B.bar


class C
  class << A
    def baz
      puts 'this is baz'
    end
  end
end

A.baz

class A
  def initialize
    @x = 42
  end
  attr_accessor :x
end


def f
  puts 'okay'
  A.new
end

o1 = f
puts o1.x

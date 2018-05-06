class A
  def initialize
    @x = 42
  end
  attr_accessor :x
end


o1 = A.new
puts o1.x


class B < A
  def initialize
    super
    @y = 43
  end
  attr_accessor :y
end


o2 = B.new
puts o2.x
puts o2.y

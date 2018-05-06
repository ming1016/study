class FieldTest1
  def initialize
    @x = 42
    @y = @x
  end
  attr_accessor :x
end

o1 = FieldTest1.new
puts o1.x

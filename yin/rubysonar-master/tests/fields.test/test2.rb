class FieldTest2
  def initialize
    @data = 42
  end

  def foo
    puts @data
  end
end

o = FieldTest2.new
puts o.data

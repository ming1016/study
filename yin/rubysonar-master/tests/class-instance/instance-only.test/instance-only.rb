class B2
  def foo
    "instance method foo"
  end
end

puts B2.foo    # shouldn't find
bo = B2.new
puts bo.foo

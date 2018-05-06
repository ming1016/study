class Foo
	a = 3
	puts "a is #{a}"
	def self.a
		888
	end
	puts "a is #{a}"
	puts "#a is #{send(:a)}"    # not right here
end

def wow?
  'wow?'
end

puts wow?

def wow!
  'wow!'
end

puts wow!

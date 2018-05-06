# (too) many ways of defining class methods

# -----------------------------------
class A
  def self.cm
    "class method A" 
  end

  def im
    "instance method A"
  end

end

puts A.cm
puts A.im   # should not be found


# -----------------------------------
class B
end

def B.cm
  "B" 
end

puts B.cm


# -----------------------------------
class C
  class << self
    def cm
      "C"
    end
  end
end

puts C.cm


# -----------------------------------
class D
end

class << D
  def cm
    "D"
  end
end

puts D.cm


# -----------------------------------
class E
  class_eval { |kls| 
    def kls.cm
      "E"
    end
    def self.cm2
      "E"
    end 
  }
end

puts E.cm      # error, should be found
puts E.cm2     # error, should be found

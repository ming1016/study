module Italy
   def pizza
     puts 'pizza'
   end
end

class Table
include Italy
   def sushi
     puts 'sushi'
   end
end

food=Table.new
food.pizza
food.sushi

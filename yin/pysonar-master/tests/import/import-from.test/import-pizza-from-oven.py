# import Pizza and not Bread from module oven.py

from kitchen.oven import Pizza

pizza = Pizza()
print(pizza.size)

# Bread is not imported, should not find it
bread = Bread()
size = bread.size
print(size)

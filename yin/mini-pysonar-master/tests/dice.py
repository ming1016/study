import random
class Dice(object):
  def __init__(self):
    self.__random = random.Random()
    def set_seed(self, seed):
      self.__random.seed(seed)

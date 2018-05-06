def aa():
  xx = 'foo'
  class hh:
    xx = 5
    class bb:
      xx = 10
      def cc(self):
        print bb.xx
        print xx
    o1 = bb()
    o1.cc()
  o2 = hh()

aa()

# import * from __init__.py of kitchen package

from kitchen import *

spoon(1)
fork(2)

# knife is not export from __init__.py
# should not be able to find it
knife(3)

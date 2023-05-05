# __result__

def f(x):
  class C(object):
    x = 0
    def meth(self):
      return x
  return C

__result__ = f(1) ().meth()

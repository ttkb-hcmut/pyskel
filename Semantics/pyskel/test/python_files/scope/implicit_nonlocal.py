# __result__

def f():
    def g():
        x
    g()
    x = 0




try:
    __result__ = f()
except NameError:
    __result__ = 1

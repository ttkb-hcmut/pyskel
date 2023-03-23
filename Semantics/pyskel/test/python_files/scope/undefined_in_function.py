# __result__

try:
    def f():
        x = y
        y = 0
    __result__ = f()
except UnboundLocalError:
    __result__ = True

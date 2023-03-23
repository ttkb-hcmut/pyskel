# __result__


try:
    class C:
        x = y
        y = 0
    __result__ = False
except NameError:
    __result__ = True

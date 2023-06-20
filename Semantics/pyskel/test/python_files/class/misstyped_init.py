# __result__

class C:
    __init__ = 0


try:
    __result__ = C()
except TypeError:
    __result__ = 1

# __result__

x = 3
def foo():
    x = 1
    def bar():
        global x
        return x
    return bar()

__result__ = foo()

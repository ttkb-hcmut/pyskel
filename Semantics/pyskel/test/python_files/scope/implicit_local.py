# __result__

x = 42

def foo():
    x = 5

    def bar():
        return x

    return bar()

__result__ = foo()

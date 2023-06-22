# __result__

x = 3

def foo():
    x = 1
    def bar():
        global x
        def baz():
            return x
        return baz()
    return bar()
__result__ = foo()

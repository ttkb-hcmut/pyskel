# __result__

def foo():
    def bar():
        def baz():
            nonlocal x
            x = 40
            return x
        return baz()
    x = 1
    return bar()

__result__ = foo()

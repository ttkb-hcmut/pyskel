#0

def foo():
    def bar():
        def baz():
            nonlocal x
            x = 0
            return x
        return baz()
    x = 1
    return bar()

__result__ = foo()

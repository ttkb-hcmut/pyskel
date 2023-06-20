# f\"\\\"{__result__}\\\"\"

def f(x):
    class C:
        y = x
        def g(self):
            return C.y
    return C


__result__ = f("hello")().g()

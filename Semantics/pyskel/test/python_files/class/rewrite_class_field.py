# __result__ 

def foo():
    class C:
        x = 1
        def bar():
            C.x = C.x + 1
    return C

test = foo()
test.bar()
test.bar()
__result__ = test.x

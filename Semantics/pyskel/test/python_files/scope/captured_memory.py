# __result__

def f():
    y = 0
    def set_and_return(n):
        nonlocal y
        y = n
        return y
    return set_and_return


set_and_return = f()
__result__ = set_and_return(42)

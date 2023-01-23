# __result__

z = 8
def f():
    global z
    y = z
    def set_and_return(n):
        nonlocal y
        y = n
        return y
    return set_and_return


__result__ = f()(42)

# __result__
def foo():
    global set
    global get

    x = 0

    def set(y):
        nonlocal x
        x = y

    def get():
        nonlocal x
        return x


foo()
set(42)

__result__ = get()

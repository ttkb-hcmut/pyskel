#42
def foo():
    global set
    global incr
    global get

    x = 0

    def set():
        nonlocal x
        x = 0

    def incr():
        nonlocal x
        x = 42

    def get():
        nonlocal x
        return x

    return get


foo()

set()
incr()

__result__ = get()

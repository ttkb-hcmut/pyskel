#42

set = None
incr = None
get = None

def foo():
    global set
    global incr
    global get

    x = 0

    def setf():
        nonlocal x
        x = 0

    def incrf():
        nonlocal x
        x = 42

    def getf():
        nonlocal x
        return x


    set = setf
    incr = incrf
    get = getf
    return get


foo()

set()
incr()

__result__ = get()

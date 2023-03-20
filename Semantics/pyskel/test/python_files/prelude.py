class object:
    pass

class BaseException(object):
    def __init__(self):
        pass

class Exception(BaseException): pass

class NameError(Exception): pass

class UnboundLocalError(NameError): pass

class TypeError(Exception): pass

class int(object):
    @pyskel_internal("IntAdd")
    def __add__(self, other):
        pass

    show = __add__

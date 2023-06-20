class object:
    pass

class BaseException(object):
    def __init__(self):
        pass

class Exception(BaseException): pass

class NameError(Exception): pass

class AttributeError(Exception): pass

class UnboundLocalError(NameError): pass

class TypeError(Exception): pass

class int(object):
    @pyskel_internal("IntAdd")
    def __add__(self, other):
        pass

class function:
    pass

class method:
    pass

class list:
    pass

class tuple:
    pass

class NotImplementedType:
    pass

class NoneType:
    pass

class str:
    pass

class bool:
    pass

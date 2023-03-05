class object:
    pass

class BaseException(object):
    def __init__(self):
        pass

class Exception(BaseException): pass

class NameError(Exception): pass

class UnboundLocalError(NameError): pass

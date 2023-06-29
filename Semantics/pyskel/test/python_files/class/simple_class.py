# f"class {__result__.__name__} {{foo = {__result__.foo.__code__.co_varnames}, x = {__result__.x}, y = {__result__.y}}}"

class __result__:
    x = 0
    y = x

    def foo():
        x = 42
        return 0

# f\"class {__result__.__name__} {{bar = <function bar(x, ) with locals = {__result__.bar.__code__.co_varnames}>}}\"

class Foo:
    def bar(x):
        return x

__result__ = Foo.bar(Foo)


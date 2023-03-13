# __result__


class Foo:
    def m_foo(self):
        self.y = 0

class Bar(Foo):
    pass

bar = Bar()
bar.m_foo()
__result__ = bar.y

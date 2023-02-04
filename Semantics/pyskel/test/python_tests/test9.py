# __result__


class Foo:
    x = 0
    def m_foo(self):
        self.y = 0

class Bar(Foo):
    z = 0


bar = Bar()
bar.m_foo()
__result__ = bar.y

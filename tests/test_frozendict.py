# mypy: disable-error-code="misc"

from collections.abc import MutableMapping
import pytest

from freezabledict import FrozenDict, PyFrozenDict


# TODO: testing deepcopy

class FrozenDictMixin:
    FrozenDict = NotImplemented

    SKIP_METHODS = {
        "__abstractmethods__",
        "__slots__",
        "__static_attributes__",
        "__firstlineno__",
    }

    def test___class_getitem__(self) -> None:
        assert self.FrozenDict[str] is not None

    def test_subclass(self) -> None:
        assert issubclass(self.FrozenDict, MutableMapping)

    # based on Python's test.test_dict module
    def test_invalid_keyword_arguments(self):
        class Custom(self.FrozenDict):
            pass
        for invalid in {1 : 2}, Custom({1 : 2}):
            with pytest.raises(TypeError):
                dict(**invalid)
            with pytest.raises(TypeError):
                {}.update(**invalid)

    def test_constructor(self):
        # calling built-in types without argument must return empty
        assert self.FrozenDict() == {}

    def test_freezability(self):
        d = self.FrozenDict()
        
        d['a'] = 1
        d.freeze()
        assert d.frozen
        assert d['a'] == 1
        with pytest.raises(RuntimeError):
            d['b'] = 2



class TestFrozenDict(FrozenDictMixin):
    FrozenDict = FrozenDict  # type: ignore[assignment]  # FIXME


class TestFrozenDictPy(FrozenDictMixin):
    FrozenDict = PyFrozenDict  # type: ignore[assignment]  # FIXME


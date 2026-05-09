# mypy: disable-error-code="misc"

from collections.abc import MutableMapping
import pytest

from freezabledict import FrozenDict, PyFrozenDict

from copy import copy

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

    def test_copy_unfrozen(self) -> None:
        orig = self.FrozenDict({"1":1, "2":2, "3": 3})
        copied = copy(orig)
        assert copied == orig
        assert copied is not orig
        assert not copied.frozen
        # Verify the copy has independent storage
        orig["4"] = 4
        assert len(orig) == 4
        assert len(copied) == 3

    def test_copy_frozen(self) -> None:
        orig = self.FrozenDict({"1":1, "2":2, "3": 3})
        orig.freeze()
        copied = copy(orig)
        assert copied == orig
        assert copied is not orig
        assert copied.frozen
        # Verify the copy is also frozen
        with pytest.raises(RuntimeError):
            copied["4"] = 4

    def test_copy_preserves_items(self) -> None:
        inner = [1, 2]
        orig = self.FrozenDict({"1":inner, "3":3})
        copied = copy(orig)
        # Shallow copy: inner objects are shared (same as list behavior)
        assert copied["1"] is orig["1"]
        # But the FrozenDict containers are independent
        assert copied is not orig
        orig["4"] = 4
        assert len(orig) == 3
        assert len(copied) == 2


class TestFrozenDict(FrozenDictMixin):
    FrozenDict = FrozenDict  # type: ignore[assignment]  # FIXME


class TestFrozenDictPy(FrozenDictMixin):
    FrozenDict = PyFrozenDict  # type: ignore[assignment]  # FIXME


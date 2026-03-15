"""
FrozenDict
----------

A freezable dictionary object.
"""

import os
import types
from collections.abc import MutableMapping
from functools import total_ordering

__version__ = "0.1.0"

__all__ = ("FrozenDict", "PyFrozenDict")  # type: tuple[str, ...]

NO_EXTENSIONS = bool(os.environ.get("FROZENDICT_NO_EXTENSIONS"))  # type: bool


@total_ordering
class FrozenDict(MutableMapping):
    __slots__ = ("_frozen", "_items")
    __class_getitem__ = classmethod(types.GenericAlias)

    def __init__(self, *args, **kwargs):
        self._frozen = False
        self._items = dict(*args, **kwargs)

    @property
    def frozen(self):
        return self._frozen

    def freeze(self):
        self._frozen = True

    def __getitem__(self, key):
        return self._items.__getitem__(key)

    def __setitem__(self, key, value):
        if self._frozen:
            raise RuntimeError("Cannot modify frozen dict.")
        self._items[key] = value

    def __delitem__(self, key):
        if self._frozen:
            raise RuntimeError("Cannot modify frozen dict.")
        del self._items[key]

    def __len__(self):
        return self._items.__len__()

    def __iter__(self):
        return self._items.__iter__()

    def __reversed__(self):
        return self._items.__reversed__()

    def __eq__(self, other):
        return dict(self) == other

    def __le__(self, other):
        return dict(self) <= other

    def __repr__(self):
        return "<{}(frozen={}, {!r})".format(
            self.__class__.__name__, self._frozen, self._items
        )

    def clear(self):
        if self._frozen:
            raise RuntimeError("Cannot modify frozen dict.")
        self._items.clear()

    def items(self):
        return self._items.items()

    def keys(self):
        return self._items.keys()

    def values(self):
        return self._items.values()

    def update(self, *args, **kwargs):
        if self._frozen:
            raise RuntimeError("Cannot modify frozen dict.")
        return self._items.update(*args, **kwargs)


PyFrozenDict = FrozenDict

if not NO_EXTENSIONS:
    try:
        from ._frozendict import FrozenDict as CFrozenDict  # type: ignore
    except ImportError:  # pragma: no cover
        pass
    else:
        FrozenList = CFrozenDict  # type: ignore

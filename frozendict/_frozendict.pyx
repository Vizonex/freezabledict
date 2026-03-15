# cython: freethreading_compatible = True
# distutils: language = c++

from cpython.bool cimport PyBool_FromLong
from libcpp.atomic cimport atomic

import copy
import types
from collections.abc import MutableMapping

# Some Portions of code are inspired by or copied from frozenlist to 
# prevent reinvention of the wheel.

cdef class FrozenDict:
    __class_getitem__ = classmethod(types.GenericAlias)

    cdef atomic[bint] _frozen
    cdef dict _items
    
    def __init__(self, *args, **kwargs) -> None:
        self._frozen.store(False)
        self._items = dict(*args, **kwargs)
    
    @property
    def frozen(self):
        return PyBool_FromLong(self._frozen.load())

    cdef object _check_frozen(self):
        if self._frozen.load():
            raise RuntimeError("Cannot modify frozen dict.")

    cdef inline object _fast_len(self):
        return len(self._items)

    def freeze(self):
        self._frozen.store(True)

    def __getitem__(self, key):
        return self._items.__getitem__(key)

    def __setitem__(self, key, value):
        self._check_frozen()
        self._items[key] = value
  
    def __delitem__(self, key):
        self._check_frozen()
        del self._items[key]

    def __len__(self):
        return self._fast_len()
    
    def __richcmp__(self, other, op):
        if op == 0:  # <
            return dict(self) < other
        if op == 1:  # <=
            return dict(self) <= other
        if op == 2:  # ==
            return dict(self) == other
        if op == 3:  # !=
            return dict(self) != other
        if op == 4:  # >
            return dict(self) > other
        if op == 5:  # =>
            return dict(self) >= other
    
    def __iter__(self):
        return self._items.__iter__()
    
    def __reversed__(self):
        return self._items.__reversed__()
    
    def setdefault(self, *args, **kwargs):
        self._check_frozen()
        return self._items.setdefault(*args, **kwargs)

    def get(self, *args, **kwargs):
        return self._items.get(*args, **kwargs)  

    def items(self):
        return self._items.items()
    
    def keys(self):
        return self._items.keys()
    
    def values(self):
        return self._items.values()

    # we do not need multiple checks so define update to add
    # some addtional speed.
    def update(self, *args, **kwargs):
        self._check_frozen()
        return self._items.update(*args, **kwargs)

    def __contains__(self, item):
        return item in self._items

    def __hash__(self):
        if self._frozen.load():
            return hash(tuple(self._items.items()))
        else:
            raise RuntimeError("Cannot hash unfrozen dict.")

    def __repr__(self):
        return '<{}(frozen={}, {!r})'.format(
            self.__class__.__name__, self._frozen.load(), self._items
        )
    
    def __deepcopy__(self, memo):
        cdef FrozenDict new_dict
        obj_id = id(self)

        # Return existing copy if already processed (circular reference)
        if obj_id in memo:
            return memo[obj_id]

        # Create new instance and register immediately
        new_dict = self.__class__()
        memo[obj_id] = new_dict

        # Deep copy items
        new_dict._items.update([(copy.deepcopy(k, memo), copy.deepcopy(v, memo)) for k, v in self._items.items()])

        # Preserve frozen state
        if self._frozen.load():
            new_dict.freeze()

        return new_dict

MutableMapping.register(FrozenDict)

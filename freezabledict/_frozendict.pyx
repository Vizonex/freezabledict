# cython: freethreading_compatible = True, nonecheck=False
# distutils: language = c++


from cpython.bool cimport PyBool_FromLong
from cpython.exc cimport PyErr_SetString
from cpython.dict cimport PyDict_Clear, PyDict_Contains, PyDict_SetItem, PyDict_Size, PyDict_DelItem
from libcpp.atomic cimport atomic
from cpython.mapping cimport PyMapping_Values, PyMapping_Items, PyMapping_Keys
cimport cython

import copy
import types
from collections.abc import MutableMapping, MappingView, Sized, KeysView as _KeysView

# Some Portions of code are inspired by or copied from frozenlist to 
# prevent reinvention of the wheel.

cdef extern from "Python.h":
    # Pythonized it.
    object PyDict_SetDefault(object p, object key, object default)

cdef object __marker = object()

@cython.nonecheck(False)
cdef class FrozenDict:
    __class_getitem__ = classmethod(types.GenericAlias)
    cdef:
        atomic[bint] _frozen
        dict _items
    
    def __init__(self, *args, **kwargs) -> None:
        self._frozen.store(False)
        self._items = dict(*args, **kwargs)

    @property
    def frozen(self):
        return PyBool_FromLong(self._frozen.load())

    cdef int _check_frozen(self) except -1:
        if self._frozen.load():
            PyErr_SetString(RuntimeError, "Cannot modify frozen dict.")
            return -1
        return 0
    
    def freeze(self):
        self._frozen.store(True)

    def __getitem__(self, key):
        return self._items[key]

    def __setitem__(self, key, value):
        self._check_frozen()
        PyDict_SetItem(self._items, key, value)
  
    def __delitem__(self, key):
        self._check_frozen()
        PyDict_DelItem(self._items, key)

    def __len__(self):
        return PyDict_Size(self._items)
    
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
        return iter(self._items)

    def __reversed__(self):
        return reversed(self._items)

    def setdefault(self, key, default=None):
        self._check_frozen()
        return PyDict_SetDefault(self._items, key, default)

    def get(self, key, default=None):
        return self._items.get(key, default)

    def items(self):
        return PyMapping_Items(self._items)
    
    def keys(self):
        return PyMapping_Keys(self._items)

    def values(self):
        return PyMapping_Values(self._items)

    def popitem(self):
        self._check_frozen()
        return self._items.popitem()
    
    def pop(self, key, default=__marker):
        self._check_frozen()
        if default is __marker:
            return self._items.pop(key)
        else:
            return self._items.pop(key, default)

    # we do not need multiple checks so define update to add
    # some addtional speed.
    @cython.boundscheck(False)
    @cython.nonecheck(False)
    def update(self, other=(), /, **kwds):
        self._check_frozen()
        return self._items.update(other, **kwds)

    def __contains__(self, item):
        return PyBool_FromLong(PyDict_Contains(self._items, item))


    def __hash__(self):
        if self._frozen.load():
            return hash(tuple(self._items.items()))
        else:
            raise RuntimeError("Cannot hash unfrozen dict.")

    def __repr__(self):
        return '<{}(frozen={}, {!r})'.format(
            self.__class__.__name__, self._frozen.load(), self._items
        )

    def __copy__(self):
        cdef FrozenDict new_dict
        new_dict = self.__class__(self._items)
        if self._frozen.load():
            new_dict.freeze()
        return new_dict
    
    def clear(self):
        self._check_frozen()
        PyDict_Clear(self._items)
    
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

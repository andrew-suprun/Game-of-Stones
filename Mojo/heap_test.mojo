from random import shuffle
from testing import assert_true

from heap import Heap


def test_heap():
    @parameter
    fn less(a: Int, b: Int, out r: Bool):
        r = a < b

    var heap = Heap[20, less]()
    var values = List(0)
    for i in range(100):
        values.append(i + 1)

    shuffle(values)
    for i in range(100):
        heap.add(values[i])

    for i in range(20):
        print(i, heap.items[i])
    for i in range(1, 20):
        var parent = heap.items[(i - 1) / 2]
        var child = heap.items[i]
        assert_true(parent < child)

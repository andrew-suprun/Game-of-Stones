from random import shuffle
from testing import assert_true

from heap import heap_add


def test_heap():
    @parameter
    fn less(a: Int, b: Int, out r: Bool) capturing:
        r = a < b

    var values = List[Int]()
    var items = List[Int]()
    for i in range(100):
        values.append(i + 1)

    shuffle(values)
    for i in range(100):
        heap_add[less](values[i], 20, items)

    for i in range(20):
        print(i, items[i])
    for i in range(1, 20):
        var parent = items[(i - 1) // 2]
        var child = items[i]
        assert_true(parent < child)

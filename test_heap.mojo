from std.random import shuffle
from std.testing import assert_true, assert_false

from engine import Value, Win, Loss, Draw, heap_add


def lt[T: Comparable](a: T, b: T) -> Bool:
    return a < b


def test_heap() raises:
    var values = List[Int]()
    var items = List[Int](capacity=20)
    for i in range(100):
        values.append(i + 1)

    shuffle(values)
    for i in range(100):
        heap_add[lt[Int]](values[i], items)

    for i in range(20):
        print(i, items[i])
    for i in range(1, 20):
        var parent = items[(i - 1) / 2]
        var child = items[i]
        assert_true(parent < child)


def main() raises:
    test_heap()

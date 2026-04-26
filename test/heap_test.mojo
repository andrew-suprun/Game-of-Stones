from std.random import shuffle
from std.testing import assert_true, assert_false

from score import Score, Win, Loss, Draw
from heap import heap_add


def less[T: Comparable](a: T, b: T) -> Bool:
    return a < b


def test_heap() raises:
    var values = List[Int]()
    var items = List[Int](capacity=20)
    for i in range(100):
        values.append(i + 1)

    shuffle(values)
    for i in range(100):
        heap_add[less[Int]](values[i], items)

    for i in range(20):
        print(i, items[i])
    for i in range(1, 20):
        var parent = items[(i - 1) / 2]
        var child = items[i]
        assert_true(parent < child)


def test_scores() raises:
    var items = List[Score](capacity=6)
    heap_add[less[Score]](Loss, items)
    heap_add[less[Score]](Draw, items)
    heap_add[less[Score]](1, items)
    heap_add[less[Score]](-1, items)
    heap_add[less[Score]](2, items)
    heap_add[less[Score]](-2, items)
    heap_add[less[Score]](0, items)
    heap_add[less[Score]](Win, items)
    for item in items:
        print(item)
    for i in range(1, 6):
        print(items[i / 2], items[i])
        assert_true(items[i / 2] <= items[i])


def main() raises:
    test_heap()
    test_scores()

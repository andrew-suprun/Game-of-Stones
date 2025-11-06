from random import shuffle
from testing import assert_true, assert_false

from score import Score
from heap import heap_add


def test_heap():
    @parameter
    fn less(a: Int, b: Int) capturing -> Bool:
        return a < b

    var values = List[Int]()
    var items = List[Int](capacity=20)
    for i in range(100):
        values.append(i + 1)

    shuffle(values)
    for i in range(100):
        heap_add[less](values[i], items)

    for i in range(20):
        print(i, items[i])
    for i in range(1, 20):
        var parent = items[(i - 1) // 2]
        var child = items[i]
        assert_true(parent < child)


def test_scores():
    @parameter
    fn less(a: Score, b: Score) capturing -> Bool:
        print(a, b, a < b)
        return a < b

    var items = List[Score](capacity=6)
    heap_add[less](Score.loss(), items)
    heap_add[less](Score.draw(), items)
    heap_add[less](Score(1), items)
    heap_add[less](Score(-1), items)
    heap_add[less](Score(2), items)
    heap_add[less](Score(-2), items)
    heap_add[less](Score(0), items)
    heap_add[less](Score.win(), items)
    for item in items:
        print(item)
    for i in range(1, 6):
        print(items[i // 2], items[i])
        assert_true(items[i // 2] <= items[i])

def main():
    test_heap()
    test_scores()
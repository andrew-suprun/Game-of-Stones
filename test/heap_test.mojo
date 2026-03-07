from std.random import shuffle
from std.testing import assert_true, assert_false

from score import Score
from heap import heap_add


fn test_heap() raises:
    var values = List[Int]()
    var items = List[Int](capacity=20)
    for i in range(100):
        values.append(i + 1)

    shuffle(values)
    for i in range(100):
        heap_add(values[i], items)

    for i in range(20):
        print(i, items[i])
    for i in range(1, 20):
        var parent = items[(i - 1) / 2]
        var child = items[i]
        assert_true(parent < child)


fn test_scores() raises:
    var items = List[Score](capacity=6)
    heap_add(Score.loss(), items)
    heap_add(Score.draw(), items)
    heap_add(Score(1), items)
    heap_add(Score(-1), items)
    heap_add(Score(2), items)
    heap_add(Score(-2), items)
    heap_add(Score(0), items)
    heap_add(Score.win(), items)
    for item in items:
        print(item)
    for i in range(1, 6):
        print(items[i / 2], items[i])
        assert_true(items[i / 2] <= items[i])


def main():
    test_heap()
    test_scores()

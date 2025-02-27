from collections import InlineArray

struct Heap[
    T: AnyTrivialRegType, //,
    max_items: Int,
    less: fn (a: T, b: T, out r: Bool) capturing,
]:
    var items: List[T]

    fn __init__(out self):
        self.items = List[T]()

    fn clear(mut self):
        self.items.clear()

    fn add(mut self, item: T):
        if self.items.size == max_items:
            if not less(self.items[0], item):
                return
            self.items[0] = item
            self.sift_down()
            return
        self.items.append(item)
        self.sift_up()

    fn sift_up(mut self):
        var child_idx = self.items.size - 1
        var child = self.items[child_idx]
        while child_idx > 0 and less(child, self.items[(child_idx - 1) // 2]):
            var parent_idx = (child_idx - 1) // 2
            var parent = self.items[parent_idx]
            self.items[child_idx] = parent
            child_idx = parent_idx
        self.items[child_idx] = child

    fn sift_down(mut self):
        var idx = 0
        var elem = self.items[idx]
        while True:
            var first = idx
            var leftChildIdx = idx*2 + 1
            if leftChildIdx < self.items.size and less(self.items[leftChildIdx], elem):
                first = leftChildIdx
            var rightChildIdx = idx*2 + 2
            if rightChildIdx < self.items.size and
                less(self.items[rightChildIdx], elem) and
                less(self.items[rightChildIdx], self.items[leftChildIdx]):
                first = rightChildIdx
            if idx == first:
                break

            self.items[idx] = self.items[first]
            idx = first
        self.items[idx] = elem

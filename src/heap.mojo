struct Heap[
    T: Copyable & ImplicitlyDestructible, size: Int, less: fn (T, T) -> Bool
]:
    var items: List[Self.T]

    fn __init__(out self):
        self.items = List[Self.T](capacity=Self.size)

    fn add(
        mut self,
        item: Self.T,
    ):
        if len(self.items) == Self.size:
            if not Self.less(self.items[0], item):
                return

            var idx = 0
            while True:
                var first = idx
                var left_child_idx = idx * 2 + 1
                if left_child_idx < len(self.items) and Self.less(
                    self.items[left_child_idx], item
                ):
                    first = left_child_idx
                var right_child_idx = idx * 2 + 2
                if (
                    right_child_idx < len(self.items)
                    and Self.less(self.items[right_child_idx], item)
                    and Self.less(
                        self.items[right_child_idx], self.items[left_child_idx]
                    )
                ):
                    first = right_child_idx
                if idx == first:
                    break

                self.items[idx] = self.items[first].copy()
                idx = first
            self.items[idx] = item.copy()
            return

        self.items.append(item.copy())
        var child_idx = len(self.items) - 1
        var child = self.items[child_idx].copy()
        while child_idx > 0 and Self.less(
            child, self.items[(child_idx - 1) // 2]
        ):
            var parent_idx = (child_idx - 1) // 2
            self.items[child_idx] = self.items[parent_idx].copy()
            child_idx = parent_idx
        self.items[child_idx] = child.copy()

    fn clear(mut self):
        self.items.clear()

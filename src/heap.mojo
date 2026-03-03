fn heap_add[T: Copyable & Comparable](item: T, mut items: List[T]):
    if len(items) == items.capacity:
        if items[0] >= item:
            return

        var idx = 0
        while True:
            var first = idx
            var left_child_idx = idx * 2 + 1
            if left_child_idx < len(items) and items[left_child_idx] < item:
                first = left_child_idx
            var right_child_idx = idx * 2 + 2
            if right_child_idx < len(items) and items[right_child_idx] < item and items[right_child_idx] < items[left_child_idx]:
                first = right_child_idx
            if idx == first:
                break

            items[idx] = items[first].copy()
            idx = first
        items[idx] = item.copy()
        return

    items.append(item.copy())
    var child_idx = len(items) - 1
    var child = items[child_idx].copy()
    while child_idx > 0 and child < items[(child_idx - 1) / 2]:
        var parent_idx = (child_idx - 1) / 2
        items[child_idx] = items[parent_idx].copy()
        child_idx = parent_idx
    items[child_idx] = child.copy()

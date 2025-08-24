fn heap_add[T: Movable & Copyable & Writable, //, less: fn (T, T, out Bool) capturing](item: T, mut items: List[T]):
    if len(items) == items.capacity:
        if not less(items[0], item):
            return
        items[0] = item
        var idx = 0
        var elem = items[idx]
        while True:
            var first = idx
            var left_child_idx = idx * 2 + 1
            if left_child_idx < len(items) and less(items[left_child_idx], elem):
                first = left_child_idx
            var right_child_idx = idx * 2 + 2
            if right_child_idx < len(items) and less(items[right_child_idx], elem) and less(items[right_child_idx], items[left_child_idx]):
                first = right_child_idx
            if idx == first:
                break

            items[idx] = items[first]
            idx = first
        items[idx] = elem
        return
    items.append(item)
    var child_idx = len(items) - 1
    var child = items[child_idx]
    while child_idx > 0 and less(child, items[(child_idx - 1) // 2]):
        var parent_idx = (child_idx - 1) // 2
        items[child_idx] = items[parent_idx]
        child_idx = parent_idx
    items[child_idx] = child

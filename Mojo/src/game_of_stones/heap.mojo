# TODO make T Infer-only parameter
fn add[T: Movable & Copyable, max_items: Int, less: fn (T, T, out Bool) capturing](item: T, mut items: List[T]):
    if len(items) == max_items:
        if not less(items[0], item):
            return
        items[0] = item
        sift_down[less](items)
        return
    items.append(item)
    sift_up[less](items)

fn sift_up[T: Movable & Copyable, //, less: fn (T, T, out Bool) capturing](mut items: List[T]):
    var child_idx = len(items) - 1
    var child = items[child_idx]
    while child_idx > 0 and less(child, items[(child_idx - 1) // 2]):
        var parent_idx = (child_idx - 1) // 2
        items[child_idx] = items[parent_idx]
        child_idx = parent_idx
    items[child_idx] = child

fn sift_down[T: Movable & Copyable, //, less: fn (T, T, out Bool) capturing](mut items: List[T]):
    var idx = 0
    var elem = items[idx]
    while True:
        var first = idx
        var left_child_idx = idx*2 + 1
        if left_child_idx < len(items) and less(items[left_child_idx], elem):
            first = left_child_idx
        var right_child_idx = idx*2 + 2
        if right_child_idx < len(items) and
            less(items[right_child_idx], elem) and
            less(items[right_child_idx], items[left_child_idx]):
            first = right_child_idx
        if idx == first:
            break
        
        items[idx] = items[first]
        idx = first
    items[idx] = elem

struct Heap[T: CollectionElement, max_items: Int, less: fn (T, T, out Bool) capturing]:
    var storage: InlineArray[T, max_items]
    var len: Int

    fn __init__(out self):
        self.storage = InlineArray[T, max_items](uninitialized = True)
        self.len = 0

    fn add(mut self, item: T):
        if self.len == max_items:
            if not less(self.storage[0], item):
                return
            self.storage[0] = item
            self.sift_down()
            return
        self.storage[self.len] = item
        self.len += 1
        self.sift_up()

    fn sift_up(mut self):
        var child_idx = self.len - 1
        var child = self.storage[child_idx]
        while child_idx > 0 and less(child, self.storage[(child_idx - 1) // 2]):
            var parent_idx = (child_idx - 1) // 2
            self.storage[child_idx] = self.storage[parent_idx]
            child_idx = parent_idx
        self.storage[child_idx] = child

    fn sift_down(mut self):
        var idx = 0
        var elem = self.storage[idx]
        while True:
            var first = idx
            var left_child_idx = idx*2 + 1
            if left_child_idx < len(self.storage) and less(self.storage[left_child_idx], elem):
                first = left_child_idx
            var right_child_idx = idx*2 + 2
            if right_child_idx < len(self.storage) and
                less(self.storage[right_child_idx], elem) and
                less(self.storage[right_child_idx], self.storage[left_child_idx]):
                first = right_child_idx
            if idx == first:
                break
            
            self.storage[idx] = self.storage[first]
            idx = first
        self.storage[idx] = elem

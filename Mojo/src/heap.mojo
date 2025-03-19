# make T Infer-only parameter
fn add[T: WritableCollectionElement, max_items: Int, less: fn (T, T, out Bool) capturing](item: T, mut items: List[T]):
    if len(items) == max_items:
        if not less(items[0], item):
            return
        items[0] = item
        sift_down[less](items)
        return
    items.append(item)
    sift_up[less](items)

fn sift_up[T: WritableCollectionElement, //, less: fn (T, T, out Bool) capturing](mut items: List[T]):
    var child_idx = len(items) - 1
    var child = items[child_idx]
    while child_idx > 0 and less(child, items[(child_idx - 1) // 2]):
        var parent_idx = (child_idx - 1) // 2
        var parent = items[parent_idx]
        items[child_idx] = parent
        child_idx = parent_idx
    items[child_idx] = child

fn sift_down[T: WritableCollectionElement, //, less: fn (T, T, out Bool) capturing](mut items: List[T]):
    var idx = 0
    var elem = items[idx]
    while True:
        var first = idx
        var leftChildIdx = idx*2 + 1
        if leftChildIdx < len(items) and less(items[leftChildIdx], elem):
            first = leftChildIdx
        var rightChildIdx = idx*2 + 2
        if rightChildIdx < len(items) and
            less(items[rightChildIdx], elem) and
            less(items[rightChildIdx], items[leftChildIdx]):
            first = rightChildIdx
        if idx == first:
            break
        
        items[idx] = items[first]
        idx = first
    items[idx] = elem

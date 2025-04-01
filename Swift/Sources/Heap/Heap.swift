import Foundation

public func heap_add<T: Comparable>(
    _ item: T, to items: inout [T], maxItems: Int, less: (T, T) -> Bool
) {
    if items.count == maxItems {
        if !less(items[0], item) {
            return
        }
        items[0] = item
        siftDown(&items, less)
        return
    }
    items.append(item)
    siftUp(&items, less)
}

func siftUp<T: Comparable>(_ items: inout [T], _ less: (T, T) -> Bool) {
    var childIdx = items.count - 1
    let child = items[childIdx]
    while childIdx > 0 && less(child, items[(childIdx - 1) / 2]) {
        let parentIdx = (childIdx - 1) / 2
        items[childIdx] = items[parentIdx]
        childIdx = parentIdx
    }
    items[childIdx] = child
}

func siftDown<T: Comparable>(_ items: inout [T], _ less: (T, T) -> Bool) {
    var idx = 0
    let elem = items[idx]
    while true {
        var first = idx
        let leftChildIdx = idx * 2 + 1
        if leftChildIdx < items.count && less(items[leftChildIdx], elem) {
            first = leftChildIdx
        }
        let rightChildIdx = idx * 2 + 2
        if rightChildIdx < items.count
            && less(items[rightChildIdx], elem)
            && less(items[rightChildIdx], items[leftChildIdx])
        {
            first = rightChildIdx
        }
        if idx == first {
            break
        }

        items[idx] = items[first]
        idx = first
    }
    items[idx] = elem
}

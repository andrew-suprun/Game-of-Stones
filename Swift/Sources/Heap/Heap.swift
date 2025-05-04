import Foundation

 @inlinable 
 public func heap_add<T: Comparable>(_ item: T, to items: inout [T], maxItems: Int) {
    if items.count == maxItems {
        if item < items[0] {
            return
        }
        items[0] = item
        siftDown(&items)
        return
    }
    items.append(item)
    siftUp(&items)
}

@inlinable 
func siftUp<T: Comparable>(_ items: inout [T]) {
    var childIdx = items.count - 1
    let child = items[childIdx]
    while childIdx > 0 && child < items[(childIdx - 1) / 2] {
        let parentIdx = (childIdx - 1) / 2
        items[childIdx] = items[parentIdx]
        childIdx = parentIdx
    }
    items[childIdx] = child
}

@inlinable 
func siftDown<T: Comparable>(_ items: inout [T]) {
    var idx = 0
    let elem = items[idx]
    while true {
        var first = idx
        let leftChildIdx = idx * 2 + 1
        if leftChildIdx < items.count && items[leftChildIdx] < elem {
            first = leftChildIdx
        }
        let rightChildIdx = idx * 2 + 2
        if rightChildIdx < items.count
            && items[rightChildIdx] < elem
            && items[rightChildIdx] < items[leftChildIdx]
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

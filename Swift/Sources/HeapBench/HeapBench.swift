import Foundation
import Heap

var heap = [Int]()

for _ in 0..<5 {
    let start = Date.now
    for _ in 0..<1_000_000 {
        heap.removeAll(keepingCapacity: true)
        for i in 0..<100 {
            heapAdd(100 - i, to: &heap, maxItems: 20, less: <)
        }
    }
    let end = Date.now
    print(start.distance(to: end))
}
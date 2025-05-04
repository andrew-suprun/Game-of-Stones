import Foundation
import Heap

var heap = [Int]()

for _ in 0..<5 {
    let start = Date.now
    for _ in 0..<1_000_000 {
        heap.removeAll(keepingCapacity: true)
        for i in 0..<100 {
            heap_add(i * 17 % 100, to: &heap, maxItems: 20)
        }
    }
    let end = Date.now
    print(start.distance(to: end))
}

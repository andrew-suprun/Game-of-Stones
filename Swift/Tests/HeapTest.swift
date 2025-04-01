import Heap
import Testing

@Test func heapTest() {
    var values = [Int]()
    var items = [Int]()
    for i in 0..<100 {
        values.append(i)
    }

    values.shuffle()

    for i in 0..<100 {
        heap_add(values[i], to: &items, maxItems: 20) { $0 < $1 }
    }

    for i in 1..<20 {
        let parent = items[(i - 1) / 2]
        let child = items[i]
        assert(parent < child)
    }
}

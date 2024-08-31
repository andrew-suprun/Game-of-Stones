package heap

type Less[E any] func(E, E) bool

type Heap[E any] struct {
	items []E
	less  Less[E]
}

func NewHeap[E any](capacity int, less Less[E]) Heap[E] {
	return Heap[E]{
		items: make([]E, 0, capacity),
		less:  less,
	}
}

func (h *Heap[E]) Add(e E) (E, bool) {
	if len(h.items) == cap(h.items) {
		if h.less(h.items[0], e) {
			result := h.items[0]
			h.items[0] = e
			h.siftDown()
			return result, true
		}
	} else {
		h.items = append(h.items, e)
		h.siftUp()
	}
	var dummy E
	return dummy, false
}

func (h *Heap[E]) Remove() E {
	if len(h.items) == 0 {
		panic("Cannot remove element from empty Heap.")
	}
	if len(h.items) == 1 {
		result := h.items[0]
		h.items = nil
		return result
	}
	result := h.items[0]
	h.items[0] = h.items[len(h.items)-1]
	h.items = h.items[:len(h.items)-1]
	h.siftDown()
	return result
}

func (h *Heap[E]) Sorted() []E {
	size := len(h.items)
	result := make([]E, size)
	for i := range size {
		result[size-i-1] = h.Remove()
	}
	return result
}

func (h *Heap[E]) siftUp() {
	childIdx := len(h.items) - 1
	child := h.items[childIdx]
	for childIdx > 0 && h.less(child, h.items[(childIdx-1)/2]) {
		parentIdx := (childIdx - 1) / 2
		h.items[childIdx] = h.items[parentIdx]
		childIdx = parentIdx
	}
	h.items[childIdx] = child
}

func (h *Heap[E]) siftDown() {
	parentIdx := 0
	topElement := h.items[0]
	for {
		first := parentIdx
		leftChildIdx := parentIdx*2 + 1
		if leftChildIdx < len(h.items) && h.less(h.items[leftChildIdx], topElement) {
			first = leftChildIdx
		}
		rightChildIdx := parentIdx*2 + 2
		if rightChildIdx < len(h.items) &&
			h.less(h.items[rightChildIdx], topElement) &&
			h.less(h.items[rightChildIdx], h.items[leftChildIdx]) {
			first = rightChildIdx
		}
		if parentIdx == first {
			break
		}

		h.items[parentIdx] = h.items[first]
		parentIdx = first
	}
	h.items[parentIdx] = topElement
}

// fn cmp(ctxt: usize, a: usize, b: usize) bool {
//     _ = ctxt;
//     return a < b;
// }

// const Prng = std.rand.Random.DefaultPrng;
// const assert = std.debug.assert;

// test "unsorted" {
//     var prng = Prng.init(@intCast(std.time.microTimestamp()));
//     var heap = Heap(usize, usize, cmp, 20).init(42);
//     for (0..100) |_| {
//         heap.add(prng.next() % 100);
//     }
//     assert(heap.len == 20);
//     var buf: [20]usize = undefined;
//     const unsorted = heap.unsorted(&buf);
//     std.debug.print("unsorted {any}\n", .{unsorted});
//     const sorted = heap.sorted(&buf);
//     std.debug.print("sorted   {any}\n", .{sorted});
//     for (1..sorted.len) |i| {
//         assert(sorted[i - 1] >= sorted[i]);
//     }
// }

// test "heap" {
//     var prng = Prng.init(@intCast(std.time.microTimestamp()));
//     var timer = try std.time.Timer.start();
//     for (0..1_000_000) |_| {
//         var heap = Heap(usize, usize, cmp, 100).init(42);
//         for (0..1000) |_| {
//             heap.add(prng.next() % 1000);
//         }
//         var buf: [100]usize = undefined;
//         const sorted = heap.unsorted(&buf);
//         assert(sorted.len == 100);
//     }
//     std.debug.print("\ntime {d}ms\n", .{timer.read() / 1_000_000});
// }

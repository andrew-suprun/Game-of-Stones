package heap2

type Less[Item any] func(Item, Item) bool

type Heap[Item any] struct {
	items *[]Item
	less  Less[Item]
}

func MakeHeap[Item any](items *[]Item, less Less[Item]) Heap[Item] {
	return Heap[Item]{
		items: items,
		less:  less,
	}
}

func (h *Heap[Item]) Add(item Item) (minItem Item, pushedOut bool) {
	if len(*h.items) == cap(*h.items) {
		if h.less((*h.items)[0], item) {
			minItem = (*h.items)[0]
			(*h.items)[0] = item
			siftDown(*h.items, h.less)
			return minItem, true
		} else {
			return minItem, false
		}
	} else {
		*h.items = append(*h.items, item)
		siftUp(*h.items, h.less)
	}
	return minItem, false
}

func (h *Heap[E]) Sort() {
	for i := len(*h.items) - 1; i > 0; i-- {
		(*h.items)[0], (*h.items)[i] = (*h.items)[i], (*h.items)[0]
		siftDown((*h.items)[:i], h.less)
	}
}

func siftUp[Item any](items []Item, less Less[Item]) {
	childIdx := len(items) - 1
	child := items[childIdx]
	for childIdx > 0 && less(child, items[(childIdx-1)/2]) {
		parentIdx := (childIdx - 1) / 2
		parent := items[parentIdx]
		items[childIdx] = parent
		childIdx = parentIdx
	}
	items[childIdx] = child
}

func siftDown[Item any](items []Item, less Less[Item]) {
	idx := 0
	elem := items[idx]
	for {
		first := idx
		leftChildIdx := idx*2 + 1
		if leftChildIdx < len(items) && less(items[leftChildIdx], elem) {
			first = leftChildIdx
		}
		rightChildIdx := idx*2 + 2
		if rightChildIdx < len(items) &&
			less(items[rightChildIdx], elem) &&
			less(items[rightChildIdx], items[leftChildIdx]) {
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

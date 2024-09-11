package heap

import (
	"bytes"
	"fmt"
)

type Less[E any] func(E, E) bool

type Heap[E any] struct {
	items []E
	less  Less[E]
}

func NewHeap[E any](capacity int, less Less[E]) *Heap[E] {
	return &Heap[E]{
		items: make([]E, 0, capacity),
		less:  less,
	}
}

func (h *Heap[E]) Add(e E) (E, bool) {
	if len(h.items) == cap(h.items) {
		if h.less(h.items[0], e) {
			result := h.items[0]
			h.items[0] = e
			h.siftDown(0)
			return result, true
		} else {
			return e, true
		}
	} else {
		h.items = append(h.items, e)
		h.siftUp()
	}
	var nilE E
	return nilE, false
}

func (h *Heap[E]) Len() int {
	return len(h.items)
}

func (h *Heap[E]) Peek() E {
	return h.items[0]
}

func (h *Heap[E]) Remove() E {
	if len(h.items) == 1 {
		result := h.items[0]
		h.items = nil
		return result
	}
	result := h.items[0]
	h.items[0] = h.items[len(h.items)-1]
	h.items = h.items[:len(h.items)-1]
	h.siftDown(0)
	fmt.Println("heap.4: remove", result, "size", len(h.items))
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
		parent := h.items[parentIdx]
		h.items[childIdx] = parent
		childIdx = parentIdx
	}
	h.items[childIdx] = child
}

func (h *Heap[E]) siftDown(idx int) {
	elem := h.items[idx]
	for {
		first := idx
		leftChildIdx := idx*2 + 1
		if leftChildIdx < len(h.items) && h.less(h.items[leftChildIdx], elem) {
			first = leftChildIdx
		}
		rightChildIdx := idx*2 + 2
		if rightChildIdx < len(h.items) &&
			h.less(h.items[rightChildIdx], elem) &&
			h.less(h.items[rightChildIdx], h.items[leftChildIdx]) {
			first = rightChildIdx
		}
		if idx == first {
			break
		}

		h.items[idx] = h.items[first]
		idx = first
	}
	h.items[idx] = elem
}

func (h *Heap[E]) String() string {
	buf := &bytes.Buffer{}
	fmt.Fprintln(buf, "---- Heap")
	for _, item := range h.items {
		fmt.Fprintf(buf, "  - %v\n", item)
	}
	return buf.String()
}

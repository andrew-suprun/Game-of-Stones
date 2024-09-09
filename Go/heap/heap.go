package heap

import (
	"bytes"
	"fmt"
)

type Less[E any] func(E, E) bool

type Heap[E comparable] struct {
	items   []E
	less    Less[E]
	indices map[E]int
}

func NewHeap[E comparable](capacity int, less Less[E]) *Heap[E] {
	return &Heap[E]{
		items:   make([]E, 0, capacity),
		less:    less,
		indices: map[E]int{},
	}
}

func (h *Heap[E]) Add(e E) (E, bool) {
	if len(h.items) == cap(h.items) {
		if h.less(h.items[0], e) {
			result := h.items[0]
			h.items[0] = e
			h.indices[e] = 0
			h.siftDown(0)
			delete(h.indices, result)
			return result, true
		}
	} else {
		h.items = append(h.items, e)
		h.indices[e] = len(h.items) - 1
		h.siftUp()
	}
	var nilE E
	return nilE, false
}

func (h *Heap[E]) Peek() (result E, ok bool) {
	if len(h.indices) > 0 {
		return h.items[0], true
	}
	return
}

func (h *Heap[E]) Remove(e E) {
	idx, found := h.indices[e]
	if !found {
		return
	}
	h.items[idx] = h.items[len(h.items)-1]
	h.siftDown(idx)
	h.items = h.items[:len(h.items)-1]
	delete(h.indices, e)
}

func (h *Heap[E]) RemoveMin() E {
	if len(h.items) == 1 {
		result := h.items[0]
		h.items = nil
		clear(h.indices)
		return result
	}
	result := h.items[0]
	h.items[0] = h.items[len(h.items)-1]
	h.items = h.items[:len(h.items)-1]
	h.siftDown(0)
	delete(h.indices, result)
	return result
}

func (h *Heap[E]) Sorted() []E {
	size := len(h.items)
	result := make([]E, size)
	for i := range size {
		result[size-i-1] = h.RemoveMin()
	}
	return result
}

func (h *Heap[E]) Clear() {
	h.items = nil
	clear(h.indices)
}

func (h *Heap[E]) siftUp() {
	childIdx := len(h.items) - 1
	child := h.items[childIdx]
	for childIdx > 0 && h.less(child, h.items[(childIdx-1)/2]) {
		parentIdx := (childIdx - 1) / 2
		parent := h.items[parentIdx]
		h.items[childIdx] = parent
		h.indices[parent] = childIdx
		childIdx = parentIdx
	}
	h.items[childIdx] = child
	h.indices[child] = childIdx
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
		h.indices[h.items[first]] = idx
		idx = first
	}
	h.items[idx] = elem
	h.indices[elem] = idx
}

func (h *Heap[E]) String() string {
	buf := &bytes.Buffer{}
	fmt.Fprintln(buf, "---- Heap")
	for _, item := range h.items {
		fmt.Fprintf(buf, "  - %v\n", item)
	}
	return buf.String()
}

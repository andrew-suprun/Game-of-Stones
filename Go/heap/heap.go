package heap

import (
	"bytes"
	"fmt"
)

type Less[E any] func(E, E) bool

type Heap[E any] struct {
	Items []E
	less  Less[E]
}

func NewHeap[E any](capacity int, less Less[E]) *Heap[E] {
	return &Heap[E]{
		Items: make([]E, 0, capacity),
		less:  less,
	}
}

func (h *Heap[E]) Add(e E) (E, bool) {
	var nilE E
	if len(h.Items) == cap(h.Items) {
		if !h.less(h.Items[0], e) {
			return nilE, false
		}
		result := h.Items[0]
		h.Items[0] = e
		h.siftDown()
		return result, true
	}
	h.Items = append(h.Items, e)
	h.siftUp()
	return nilE, false
}

func (h *Heap[E]) Remove() E {
	if len(h.Items) == 1 {
		result := h.Items[0]
		h.Items = nil
		return result
	}
	result := h.Items[0]
	h.Items[0] = h.Items[len(h.Items)-1]
	h.Items = h.Items[:len(h.Items)-1]
	h.siftDown()
	return result
}

func (h *Heap[E]) Sorted() []E {
	size := len(h.Items)
	result := make([]E, size)
	for i := range size {
		result[size-i-1] = h.Remove()
	}
	return result
}

func (h *Heap[E]) siftUp() {
	childIdx := len(h.Items) - 1
	child := h.Items[childIdx]
	for childIdx > 0 && h.less(child, h.Items[(childIdx-1)/2]) {
		parentIdx := (childIdx - 1) / 2
		parent := h.Items[parentIdx]
		h.Items[childIdx] = parent
		childIdx = parentIdx
	}
	h.Items[childIdx] = child
}

func (h *Heap[E]) siftDown() {
	idx := 0
	elem := h.Items[idx]
	for {
		first := idx
		leftChildIdx := idx*2 + 1
		if leftChildIdx < len(h.Items) && h.less(h.Items[leftChildIdx], elem) {
			first = leftChildIdx
		}
		rightChildIdx := idx*2 + 2
		if rightChildIdx < len(h.Items) &&
			h.less(h.Items[rightChildIdx], elem) &&
			h.less(h.Items[rightChildIdx], h.Items[leftChildIdx]) {
			first = rightChildIdx
		}
		if idx == first {
			break
		}

		h.Items[idx] = h.Items[first]
		idx = first
	}
	h.Items[idx] = elem
}

func (h *Heap[E]) String() string {
	buf := &bytes.Buffer{}
	fmt.Fprintln(buf, "---- Heap")
	for _, item := range h.Items {
		fmt.Fprintf(buf, "  - %v\n", item)
	}
	return buf.String()
}

package heap

import (
	"math/rand"
	"testing"
)

func less(i, j int) bool {
	return i < j
}

func TestHeap(t *testing.T) {
	heap := NewHeap(20, less)
	values := make([]int, 100)
	for i := range 100 {
		values[i] = i + 1
	}
	rand.Shuffle(100, func(i, j int) {
		values[i], values[j] = values[j], values[i]
	})
	for i := range 100 {
		heap.Add(values[i])
	}

	heap.Remove(90)
	heap.Remove(100)
	heap.Remove(81)

	if len(heap.items) != 17 || len(heap.indices) != 17 {
		t.Fail()
	}

	oldElem := 0
	for range 17 {
		elem := heap.RemoveMin()
		if elem == 81 || elem == 90 || elem == 100 || elem <= oldElem {
			t.Fail()
		}
		oldElem = elem
	}
	// t.Fail()
}

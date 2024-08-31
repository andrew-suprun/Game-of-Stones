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
	for range 100 {
		heap.Add(rand.Intn(100))
	}

	sorted := heap.Sorted()
	for i := range 19 {
		if sorted[i] < sorted[i+1] {
			t.Fail()
		}
	}
}

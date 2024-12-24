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

	oldElem := 0
	for range 20 {
		elem := heap.Remove()
		if elem <= oldElem {
			t.Fail()
		}
		oldElem = elem
	}
}

func BenchmarkHeap(b *testing.B) {
	heap := NewHeap(20, less)
	values := make([]int, 100)
	values2 := make([]int, 100)
	for i := range 100 {
		values[i] = i + 1
	}
	rand.Shuffle(100, func(i, j int) {
		values[i], values[j] = values[j], values[i]
	})

	b.ResetTimer()
	for range b.N {
		copy(values2, values)
		for i := range 100 {
			heap.Add(values2[i])
		}
	}
}

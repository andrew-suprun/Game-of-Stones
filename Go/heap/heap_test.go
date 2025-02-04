package heap

import (
	"math/rand"
	"testing"
)

func less(i, j int) bool {
	return i < j
}

func TestHeap(t *testing.T) {
	heap := make([]int, 0, 20)
	values := make([]int, 100)
	for i := range 100 {
		values[i] = i + 1
	}
	rand.Shuffle(100, func(i, j int) {
		values[i], values[j] = values[j], values[i]
	})
	for i := range 100 {
		Add(values[i], &heap, 20, less)
	}

	for i := 1; i < 20; i++ {
		parent := heap[(i-1)/2]
		child := heap[i]
		if parent > child {
			t.Errorf("parent %d is greater than child %d", parent, child)
		}
	}
}

func BenchmarkHeap(b *testing.B) {
	heap := make([]int, 0, 20)
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
			Add(values2[i], &heap, 20, less)
		}
	}
}

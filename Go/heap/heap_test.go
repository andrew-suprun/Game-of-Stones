package heap2

import (
	"math/rand"
	"testing"
)

func less(i, j int) bool {
	return i < j
}

func TestHeap(t *testing.T) {
	items := make([]int, 0, 20)
	heap := MakeHeap(&items, less)
	values := make([]int, 100)
	for i := range 100 {
		values[i] = i + 1
	}
	rand.Shuffle(100, func(i, j int) { values[i], values[j] = values[j], values[i] })
	for i := range 100 {
		heap.Add(values[i])
	}

	heap.Sort()

	for item, i := range items {
		if item+i != 100 {
			t.FailNow()
		}
	}
}

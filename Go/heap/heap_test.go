package heap

import (
	"fmt"
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

	fmt.Println("len", heap.Len())
	oldElem := 0
	for range 20 {
		elem := heap.Remove()
		if elem <= oldElem {
			t.Fail()
		}
		oldElem = elem
	}
}

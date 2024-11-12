package heap

import (
	"math/rand"
	"testing"
)

type IntHeap []int

func (h IntHeap) Len() int           { return len(h) }
func (h IntHeap) Less(i, j int) bool { return h[i] < h[j] }
func (h IntHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }

func (h *IntHeap) Push(i int) {
	*h = append(*h, i)
}

func (h *IntHeap) Pop() int {
	old := *h
	n := len(old)
	i := old[n-1]
	*h = old[0 : n-1]
	return i
}

const N = 100

func TestHeap(t *testing.T) {
	heap := &IntHeap{}
	values := make([]int, N)
	for i := range N {
		values[i] = i
	}
	rand.Shuffle(N, func(i, j int) { values[i], values[j] = values[j], values[i] })
	for i := range N {
		Push(heap, values[i])
	}

	for i := range N {
		item := Pop(heap)
		if item != i {
			t.FailNow()
		}
	}
}

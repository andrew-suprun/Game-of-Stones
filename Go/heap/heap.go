package heap

import "sort"

type Heap[item any] interface {
	sort.Interface
	Push(item item)
	Pop() item
}

func Push[heap Heap[item], item any](h heap, i item) {
	h.Push(i)
	j := h.Len() - 1
	for {
		i := (j - 1) / 2
		if i == j || !h.Less(j, i) {
			break
		}
		h.Swap(i, j)
		j = i
	}
}

func Pop[heap Heap[item], item any](h heap) item {
	h.Swap(0, h.Len()-1)
	i := 0
	n := h.Len() - 1
	for {
		j1 := 2*i + 1
		if j1 >= n {
			break
		}
		j := j1
		if j2 := j1 + 1; j2 < n && h.Less(j2, j1) {
			j = j2
		}
		if !h.Less(j, i) {
			break
		}
		h.Swap(i, j)
		i = j
	}
	return h.Pop()
}

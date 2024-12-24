package heap

type Less[E any] func(E, E) bool

func Add[I any](item I, items *[]I, less Less[I]) {
	if len(*items) == cap(*items) {
		if !less((*items)[0], item) {
			return
		}
		(*items)[0] = item
		siftDown(items, less)
		return
	}
	*items = append(*items, item)
	siftUp(items, less)
}

func siftUp[E any](items *[]E, less Less[E]) {
	childIdx := len(*items) - 1
	child := (*items)[childIdx]
	for childIdx > 0 && less(child, (*items)[(childIdx-1)/2]) {
		parentIdx := (childIdx - 1) / 2
		parent := (*items)[parentIdx]
		(*items)[childIdx] = parent
		childIdx = parentIdx
	}
	(*items)[childIdx] = child
}

func siftDown[E any](items *[]E, less Less[E]) {
	idx := 0
	elem := (*items)[idx]
	for {
		first := idx
		leftChildIdx := idx*2 + 1
		if leftChildIdx < len(*items) && less((*items)[leftChildIdx], elem) {
			first = leftChildIdx
		}
		rightChildIdx := idx*2 + 2
		if rightChildIdx < len(*items) &&
			less((*items)[rightChildIdx], elem) &&
			less((*items)[rightChildIdx], (*items)[leftChildIdx]) {
			first = rightChildIdx
		}
		if idx == first {
			break
		}

		(*items)[idx] = (*items)[first]
		idx = first
	}
	(*items)[idx] = elem
}

package heap


Heap :: struct($E: typeid) {
	items:   []E,
	less:    proc(_: E, _: E) -> bool,
	indices: map[E]int,
}


make :: proc(capacity: int, less: proc(a, b: $E) -> bool) -> Heap(E) {
	items := make_slice([]E, capacity)
	return Heap(E){items = items, less = less, indices = make_map(map[E]int, capacity)}
}

deinit :: proc(h: ^Heap($E)) {
	delete(h.items)
	delete(h.indices)
}


add :: proc(h: ^Heap($E), e: E) -> (E, bool) {
	if len(h.indices) == len(h.items) {
		if h.less(h.items[0], e) {
			result := h.items[0]
			delete_key(&h.indices, result)
			h.items[0] = e
			h.indices[e] = 0
			sift_down(h, 0)
			return result, true
		}
	} else {
		length := len(h.indices)
		h.items[length] = e
		h.indices[e] = length
		sift_up(h)
	}
	return E{}, false
}

remove :: proc(h: ^Heap($E), e: E) {
	idx := h.indices[e]
	h.items[idx] = h.items[len(h.indices) - 1]
	delete_key(&h.indices, e)
	sift_down(h, idx)
}

remove_top :: proc(h: ^Heap($E)) -> E {
	if len(h.indices) == 1 {
		result := h.items[0]
		clear(&h.indices)
		return result
	}
	result := h.items[0]
	h.items[0] = h.items[len(h.indices) - 1]
	sift_down(h, 0)
	delete_key(&h.indices, result)
	return result
}


@(private)
sift_up :: proc(h: ^Heap($E)) {
	childIdx := len(h.indices) - 1
	child := h.items[childIdx]
	for childIdx > 0 && h.less(child, h.items[(childIdx - 1) / 2]) {
		parentIdx := (childIdx - 1) / 2
		parent := h.items[parentIdx]
		h.items[childIdx] = parent
		h.indices[parent] = childIdx
		childIdx = parentIdx
	}
	h.items[childIdx] = child
	h.indices[child] = childIdx
}

@(private)
sift_down :: proc(h: ^Heap($E), idx: int) {
	i := idx
	elem := h.items[i]
	for {
		first := i
		leftChildIdx := i * 2 + 1
		if leftChildIdx < len(h.indices) && h.less(h.items[leftChildIdx], elem) {
			first = leftChildIdx
		}
		rightChildIdx := i * 2 + 2
		if rightChildIdx < len(h.indices) &&
		   h.less(h.items[rightChildIdx], elem) &&
		   h.less(h.items[rightChildIdx], h.items[leftChildIdx]) {
			first = rightChildIdx
		}
		if i == first {
			break
		}

		h.items[i] = h.items[first]
		h.indices[h.items[first]] = i
		i = first
	}

	h.items[i] = elem
	h.indices[elem] = i
}

sorted :: proc(h: ^Heap($E)) -> []E {
	size := len(h.indices)
	result := make_slice([]E, size)
	for i in 0 ..< size {
		result[size - i - 1] = remove_top(h)
	}
	return result
}

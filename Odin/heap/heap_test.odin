
package heap

import "core:math/rand"
import "core:testing"

testing_less :: proc(a, b: int) -> bool {
	return a < b
}

@(test)
test_remove_2 :: proc(t: ^testing.T) {
	heap := make(20, testing_less)
	defer {
		deinit(&heap)
	}
	values := make_slice([]int, 100)
	defer delete(values)

	for i in 0 ..< 100 {
		values[i] = i + 1
	}
	rand.shuffle(values)
	for i in 0 ..< 100 {
		add(&heap, values[i])
	}

	remove(&heap, 90)
	remove(&heap, 100)
	remove(&heap, 81)

	if len(heap.indices) != 17 {
		testing.fail(t)
	}

	oldElem := 0
	for _ in 0 ..< 17 {
		elem := remove_top(&heap)
		if elem == 81 || elem == 90 || elem == 100 || elem <= oldElem {
			testing.fail(t)
		}
		oldElem = elem
	}
}

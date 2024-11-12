package pool

import (
	"testing"
)

func TestPool(t *testing.T) {
	pool := Pool[int]{}
	pool.Add(1)
	i1 := pool.Add(2)
	i2 := pool.Add(3)
	pool.Add(4)
	pool.Remove(i1)
	pool.Remove(i2)
	i3 := pool.Add(5)
	pool.Add(6)
	v3 := pool.Get(i3)
	*v3 = 7
	pool.Add(8)
	values := [...]int{1, 6, 7, 4, 8}
	for i, v := range values {
		if v != *pool.Get(Idx(i)) {
			t.FailNow()
		}
	}
}

package pool

type Pool[Item any] struct {
	items    []Item
	freeList []uint32
}

func (pool *Pool[Item]) Add(item Item) uint32 {
	if len(pool.freeList) == 0 {
		pool.items = append(pool.items, item)
		return uint32(len(pool.items) - 1)
	}
	idx := pool.freeList[len(pool.freeList)-1]
	pool.items[idx] = item
	pool.freeList = pool.freeList[:len(pool.freeList)-1]
	return idx
}

func (pool *Pool[Item]) Get(idx uint32) *Item {
	return &pool.items[idx]
}

func (pool *Pool[Item]) Remove(idx uint32) {
	pool.freeList = append(pool.freeList, idx)
}

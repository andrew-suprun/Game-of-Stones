package pool

type Idx uint32

type Pool[Item any] struct {
	items    []Item
	freeList []Idx
}

func MakePool[Item any]() Pool[Item] {
	return Pool[Item]{
		items:    make([]Item, 1),
		freeList: nil,
	}
}

func (pool *Pool[Item]) Add(item Item) Idx {
	if len(pool.freeList) == 0 {
		pool.items = append(pool.items, item)
		return Idx(len(pool.items) - 1)
	}
	idx := pool.freeList[len(pool.freeList)-1]
	pool.items[idx] = item
	pool.freeList = pool.freeList[:len(pool.freeList)-1]
	return idx
}

func (pool *Pool[Item]) Get(idx Idx) *Item {
	return &pool.items[idx]
}

func (pool *Pool[Item]) Remove(idx Idx) {
	pool.freeList = append(pool.freeList, idx)
}

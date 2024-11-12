package tree

import (
	"game_of_stones/pool"
)

type iMove interface {
	IsWinning() bool
}

type iGame[move iMove] interface {
	Turn() Player
	PlayMove(move)
	UndoMove(move)
	PossibleMoves(result *[]move)
}

type Player int

const (
	Maxer  Player = 1
	Minner Player = 2
)

type node[move iMove] struct {
	parent pool.Idx
	child  pool.Idx
	prev   pool.Idx
	next   pool.Idx
	move   move
}

type nodeHeap[move iMove] struct {
	pool    pool.Pool[node[move]]
	indices []pool.Idx
}

func (h *nodeHeap[move]) Less(i, j int) bool {
	iNode := h.pool.Get(pool.Idx(i)).move
	jNode := h.pool.Get(pool.Idx(j)).move
	return iNode.Less(jNode)
}

func (h *nodeHeap) Swap(i, j int) {
	iNode := h.pool.Get(i)
	jNode := h.pool.Get(j)
	(*h)[i], (*h)[j] = (*h)[j], (*h)[i]
}

func (h *nodeHeap) Len() int {
	return len(*h)
}

func (h *nodeHeap) Pop() (v any) {
	*h, v = (*h)[:h.Len()-1], (*h)[h.Len()-1]
	return
}

func (h *nodeHeap) Push(v any) {
	*h = append(*h, v.(int))
}

type Tree[game iGame[move], move iMove] struct {
	game     iGame[move]
	pool     pool.Pool[node[move]]
	heap     nodeHeap[move]
	root     pool.Idx
	current  pool.Idx
	capacity int
}

func NewTree[g iGame[m], m iMove](game g, capacity int) *Tree[g, m] {

	tree := &Tree[g, m]{
		game:     game,
		pool:     pool.MakePool[node[m]](),
		capacity: capacity,
	}
	tree.root = tree.pool.Add(node[m]{})
	return tree
}

func (tree *Tree[game, move]) firstLeaf() {
	for {
		child := tree.pool.Get(tree.current).child
		if child == 0 {
			break
		}
		tree.current = child
	}
}

func (tree *Tree[game, move]) nextSibling() bool {
	for {
		currentNode := tree.pool.Get(tree.current)
		if currentNode.next != 0 {
			break
		}
		if currentNode.parent == 0 {
			return false
		}
		tree.current = currentNode.parent
	}
	tree.firstLeaf()
	return true
}

func (tree *Tree[game, move]) expand() {
}

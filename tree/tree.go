package tree

import (
	"game_of_stones/heap"
)

type Move interface {
	comparable
	String() string
}

type Player int

const (
	firstPlayer Player = iota
	secondPlayer
)

type Tree[move Move] struct {
	root       *Node[move]
	leaves     []*Node[move]
	newLeaves  heap.Heap[*Node[move]]
	rootPlayer Player
	leafPlayer Player
	firstLess  heap.Less[*Node[move]]
	secondLess heap.Less[*Node[move]]
}

func NewTree[move Move](capacity int, firstLess, secondLess heap.Less[*Node[move]]) Tree[move] {
	var rootFakeMove move
	return Tree[move]{
		root:       NewNode(rootFakeMove),
		leaves:     nil,
		newLeaves:  heap.NewHeap(capacity, firstLess),
		rootPlayer: firstPlayer,
		leafPlayer: firstPlayer,
		firstLess:  firstLess,
		secondLess: secondLess,
	}
}

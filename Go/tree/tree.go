package tree

import (
	"game_of_stones/heap"
)

type Game[move Move] interface {
	PossibleMoves([]move) []move
}

type Move interface {
	comparable
	// Score() int
	String() string
}

type Player int

const (
	firstPlayer Player = iota
	secondPlayer
)

type Tree[game Game[move], move Move] struct {
	game     Game[move]
	capacity int
	// root     *Node[move] // TODO `root` or `moves`
	root       map[move]*Node[move] // TODO `root` or `moves`
	leaves     heap.Heap[*Node[move]]
	rootPlayer Player
	leafPlayer Player
	firstLess  heap.Less[*Node[move]]
	secondLess heap.Less[*Node[move]]
	depth      int
}

func NewTree[game Game[move], move Move](g game, capacity int, firstLess, secondLess heap.Less[*Node[move]]) *Tree[game, move] {
	return &Tree[game, move]{
		game:     g,
		capacity: capacity,
		// root:       g.PossibleMoves(nil),
		rootPlayer: firstPlayer,
		leafPlayer: firstPlayer,
		firstLess:  firstLess,
		secondLess: secondLess,
	}
}

func (t *Tree[game, move]) Expand() {
	// var less heap.Less[*Node[move]]
	// if t.leafPlayer == firstPlayer {
	// 	less = t.firstLess
	// } else {
	// 	less = t.secondLess
	// }
	// t.newLeaves = heap.NewHeap(t.capacity, less)
	// for i, node := range t.leaves {
	// 	playedMoves := make([]move, t.depth)
	// 	for node != nil {
	// 		playedMoves[t.depth-i-1] = node.move
	// 	}
	// 	possibleMoves := t.game.PossibleMoves(playedMoves)
	// 	for _, m := range possibleMoves {
	// 		child := node.AddMove(m)
	// 		oldNode, removed := t.newLeaves.Add(child)
	// 		if removed {
	// 			oldNode.Remove()
	// 		}
	// 		if len(t.root.children) == 1 {
	// 			return
	// 		}
	// 	}
	// }
	// t.depth++
	// t.leaves = t.newLeaves.Sorted()
}

// func (t *Tree[game, move]) BestChild() (move, int) {
// 	return t.root.BestChild(t.rootPlayer)
// }

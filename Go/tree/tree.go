package tree

import (
	"fmt"
	"g_of_stones/heap"
	"math"
)

type iGame[move iMove] interface {
	MakeMove(move)
	UnmakeMove(move)
	PossibleMoves(limit int32) []move
}

type iMove interface {
	comparable
	Wins() bool
	Draws() bool
	Score() int32
	String() string
}

type tree[pGame iGame[pMove], pMove iMove] struct {
	gameInit   func() pGame
	capacity   int
	root       node[pMove]
	maxerLess  func(a, b *node[pMove]) bool
	minnerLess func(a, b *node[pMove]) bool
	maxer      bool
	depth      int
}

func newTree[pGame iGame[pMove], pMove iMove](
	gameInit func() pGame,
	capacity int,
	maxerLess func(a, b *node[pMove]) bool,
	minnerLess func(a, b *node[pMove]) bool,
) *tree[pGame, pMove] {
	return &tree[pGame, pMove]{
		gameInit:   gameInit,
		capacity:   capacity,
		maxerLess:  maxerLess,
		minnerLess: minnerLess,
		maxer:      true,
		depth:      0,
	}
}

type expandResult int

const (
	winning expandResult = iota
	losing
	drawing
	inconclusive
)

func (r expandResult) String() string {
	switch r {
	case winning:
		return "winning"
	case losing:
		return "losing"
	case drawing:
		return "drawing"
	case inconclusive:
		return "inconclusive"
	}
	return ""
}

func (tree *tree[pGame, pMove]) expand(game pGame) expandResult {
	fmt.Println("\n===================\n#### expand depth", tree.depth)

	defer func() {
		tree.depth++
	}()

	var leaves *heap.Heap[*node[pMove]]
	if tree.maxer && tree.depth%2 == 0 || !tree.maxer && tree.depth%2 == 1 {
		leaves = heap.NewHeap(tree.capacity, tree.maxerLess)
	} else {
		leaves = heap.NewHeap(tree.capacity, tree.minnerLess)
	}
	return tree.expandNode(&tree.root, game, leaves)
}

func (tree *tree[pGame, pMove]) expandNode(node *node[pMove], game pGame, leaves *heap.Heap[*node[pMove]]) expandResult {
	if len(node.children) == 0 {

		var limit int32

		if elem, ok := leaves.Peek(); ok && leaves.Full() {
			limit = elem.move.Score()
		} else if tree.maxer && tree.depth%2 == 0 || !tree.maxer && tree.depth%2 == 1 {
			limit = math.MinInt32
		} else {
			limit = math.MaxInt32
		}

		moves := game.PossibleMoves(limit)
		if len(moves) == 0 {
			fmt.Println("node", node.move, "is winning")
			return winning
		}
		if moves[0].Wins() {
			fmt.Println("node", node.move, "is losing")
			return losing
		}
		node.addMoves(moves)
		fmt.Println("node", node.move, "added", moves, "limit", limit)
		result := drawing
		for i := range node.children {
			child := &node.children[i]
			if !child.move.Draws() {
				if minNode, pushedOut := leaves.Add(child); pushedOut {
					tree.removeChild(minNode, leaves)
				}
				result = inconclusive
			}
		}
		return result
	}

	result := drawing
	for i := range node.children {
		child := &node.children[i]
		if child.dead {
			continue
		}
		if !child.draw {
			game.MakeMove(child.move)
			expandResult := tree.expandNode(child, game, leaves)
			game.UnmakeMove(child.move)
			switch expandResult {
			case winning:
				return losing
			case losing:
				if len(node.children) == 1 {
					return winning
				}
				tree.removeNode(child, leaves)
			case inconclusive:
				result = inconclusive
			}
		}
	}
	if len(node.children) == 0 {
		return winning
	}
	return result
}

func (tree *tree[_, move]) removeChild(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	if len(parent.children) == 1 {
		tree.removeNode(parent, leaves)
	} else {
		tree.removeLeaves(node, leaves)
		node.removeSelf()
	}
	fmt.Println("node", node.parent.move, "removed", node.move)
}

func (tree *tree[_, move]) removeNode(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	if parent != nil && len(parent.children) == 1 {
		tree.removeChild(node, leaves)
	} else {
		tree.removeLeaves(node, leaves)
		node.removeSelf()
	}
}

func (tree *tree[_, move]) removeLeaves(node *node[move], leaves *heap.Heap[*node[move]]) {
	if len(node.children) == 0 {
		leaves.Remove(node)
	} else {
		for i := range node.children {
			child := &node.children[i]
			if !child.dead {
				tree.removeLeaves(child, leaves)
			}
		}
	}
}

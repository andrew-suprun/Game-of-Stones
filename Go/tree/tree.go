package tree

import (
	"fmt"
	"g_of_stones/heap"
	"math"
)

type iGame[move iMove] interface {
	MakeMove(move)
	UnmakeMove(move)
	PossibleMoves(limit int) []move
}

type iMove interface {
	comparable
	Wins() bool
	Draws() bool
	Score() int
	String() string
}

type tree[pGame iGame[pMove], pMove iMove] struct {
	gameInit   func() pGame
	capacity   int
	root       *node[pMove]
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
		root:       &node[pMove]{children: map[pMove]*node[pMove]{}},
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
	defer fmt.Println("leaves", leaves)
	return tree.expandNode(tree.root, game, leaves)
}

func (tree *tree[pGame, pMove]) expandNode(node *node[pMove], game pGame, leaves *heap.Heap[*node[pMove]]) expandResult {
	if len(node.children) == 0 {

		var limit int
		if minElement, ok := leaves.Peek(); ok {
			limit = minElement.move.Score()
		} else if tree.maxer && tree.depth%2 == 0 || !tree.maxer && tree.depth%2 == 1 {
			limit = math.MinInt
		} else {
			limit = math.MaxInt
		}

		moves := game.PossibleMoves(limit)
		if len(moves) == 0 {
			return winning
		}
		result := drawing
		for _, move := range moves {
			if move.Wins() {
				return losing
			}

			child := node.addMove(move)
			if !move.Draws() {
				if minNode, pushedOut := leaves.Add(child); pushedOut {
					tree.removeChild(minNode, leaves)
				}
				result = inconclusive
			}
		}
		return result
	}

	result := drawing
	i := 0
	for _, child := range node.children {
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
				tree.removeLeaves(child, leaves)
				continue
			case inconclusive:
				result = inconclusive
			}
		}
		i++
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
	}
}

func (tree *tree[_, move]) removeNode(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	if parent != nil && len(parent.children) == 1 {
		tree.removeChild(node, leaves)
	} else {
		tree.removeLeaves(node, leaves)
	}
}

func (tree *tree[_, move]) removeLeaves(node *node[move], leaves *heap.Heap[*node[move]]) {
	if len(node.children) == 0 {
		leaves.Remove(node)
	} else {
		for _, child := range node.children {
			tree.removeLeaves(child, leaves)
		}
	}
	parent := node.parent
	if parent != nil {
		delete(parent.children, node.move)
	}
}

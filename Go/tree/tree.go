package tree

import (
	"fmt"
	"g_of_stones/heap"
	"math"
)

type iMove interface {
	comparable
	Wins() bool
	Draws() bool
	Score() int32
	String() string
}

type iGame[move iMove] interface {
	MakeMove(move)
	UnmakeMove(move)
	PossibleMoves(limit int32) []move
}

type tree[pMove iMove] struct {
	game       iGame[pMove]
	capacity   int
	root       node[pMove]
	maxerLess  func(a, b *node[pMove]) bool
	minnerLess func(a, b *node[pMove]) bool
	maxer      bool
	depth      int
}

func NewTree[pMove iMove](
	game iGame[pMove],
	capacity int,
	maxerLess func(a, b *node[pMove]) bool,
	minnerLess func(a, b *node[pMove]) bool,
) *tree[pMove] {
	return &tree[pMove]{
		game:       game,
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

func (tree *tree[pMove]) Expand() expandResult {
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
	return tree.expandNode(&tree.root, leaves)
}

func (tree *tree[pMove]) expandNode(node *node[pMove], leaves *heap.Heap[*node[pMove]]) expandResult {
	if node.nChildren == 0 {

		var limit int32

		if leaves.Len() == tree.capacity {
			limit = leaves.Peek().move.Score()
		} else if tree.maxer && tree.depth%2 == 0 || !tree.maxer && tree.depth%2 == 1 {
			limit = math.MinInt32
		} else {
			limit = math.MaxInt32
		}

		moves := tree.game.PossibleMoves(limit)
		if len(moves) == 0 {
			fmt.Println("## node", node.move, "is winning")
			return winning
		}
		if moves[0].Wins() {
			fmt.Println("## node", node.move, "is losing")
			return losing
		}
		node.addMoves(moves)
		fmt.Println(">> node", node.move, "added", moves, "limit", limit)
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
			tree.game.MakeMove(child.move)
			expandResult := tree.expandNode(child, leaves)
			tree.game.UnmakeMove(child.move)
			switch expandResult {
			case winning:
				return losing
			case losing:
				if node.nChildren == 1 {
					return winning
				}
				tree.removeNode(child, leaves)
			case inconclusive:
				result = inconclusive
			}
		}
	}
	if node.nChildren == 0 {
		return winning
	}
	return result
}

func (tree *tree[move]) removeChild(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	fmt.Println("  removeChild", node, "siblings", parent.nChildren)
	if parent.nChildren == 1 {
		tree.removeNode(parent, leaves)
	} else {
		parent.nChildren--
		node.dead = true
		node.children = nil
		fmt.Println("<< node", node.move, "removed-1 from ", node.parent.move)
	}
}

func (tree *tree[move]) removeNode(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	if parent != nil && parent.nChildren == 1 {
		tree.removeChild(node, leaves)
	} else {
		parent.nChildren--
		node.dead = true
		node.children = nil
		fmt.Println("<< node", node.move, "removed-2 from ", node.parent.move)
	}
}

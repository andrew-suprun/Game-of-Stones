package tree

import (
	"fmt"
	"game_of_stones/heap"
)

type iMove interface {
	comparable
	IsDraw() bool
	IsWin() bool
	Score() int16
	String() string
}

type iGame[move iMove] interface {
	PlayMove(move)
	UndoMove(move)
	PossibleMoves() func() (move, bool)
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
	if len(node.children) == 0 {

		moves := tree.game.PossibleMoves()
		move, ok := moves()
		if !ok {
			fmt.Println("## node", node.move, "is winning")
			return winning
		}
		if move.IsWin() {
			fmt.Println("## node", node.move, "is losing")
			return losing
		}
		result := drawing
		for {
			move, ok = moves()
			if !ok {
				break
			}
			child := node.addMove(move)
			fmt.Println(">> node", node.move, "added", move)
			if !child.move.IsDraw() {
				if minNode, pushedOut := leaves.Add(child); pushedOut {
					tree.removeChild(minNode, leaves)
				}
				result = inconclusive
			}
		}
		return result
	}

	result := drawing
	for _, child := range node.children {
		if !child.move.IsDraw() {
			tree.game.PlayMove(child.move)
			expandResult := tree.expandNode(child, leaves)
			tree.game.UndoMove(child.move)
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

func (tree *tree[move]) removeChild(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	if len(parent.children) == 1 {
		tree.removeNode(parent, leaves)
	} else {
		lastNode := parent.children[len(parent.children)-1]
		parent.children[node.selfIdx] = lastNode
		lastNode.selfIdx = node.selfIdx
		parent.children = parent.children[:len(parent.children)-1]
		fmt.Println("<< node", node.move, "removed-1 from ", node.parent.move, "siblings", len(parent.children))
	}
}

func (tree *tree[move]) removeNode(node *node[move], leaves *heap.Heap[*node[move]]) {
	parent := node.parent
	if parent != nil && len(parent.children) == 1 {
		tree.removeChild(node, leaves)
	} else {
		lastNode := parent.children[len(parent.children)-1]
		parent.children[node.selfIdx] = lastNode
		lastNode.selfIdx = node.selfIdx
		parent.children = parent.children[:len(parent.children)-1]
		fmt.Println("<< node", node.move, "removed-2 from ", node.parent.move)
	}
}

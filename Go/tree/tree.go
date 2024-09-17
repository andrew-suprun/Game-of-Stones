package tree

import (
	"game_of_stones/heap"
	"math"
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
	PossibleMoves() func(limit int16) (move, bool)
}

type tree[pMove iMove] struct {
	game      iGame[pMove]
	capacity  int
	root      node[pMove]
	freeNodes *node[pMove]
	maxer     bool
	depth     int
}

func NewTree[pMove iMove](
	game iGame[pMove],
	capacity int,
) *tree[pMove] {
	return &tree[pMove]{
		game:     game,
		capacity: capacity,
		maxer:    true,
		depth:    0,
	}
}

func (tree *tree[pMove]) Expand() {
	defer func() {
		tree.depth++
	}()

	var leaves *heap.Heap[*node[pMove]]
	var limit int16
	if tree.maxer && tree.depth%2 == 0 || !tree.maxer && tree.depth%2 == 1 {
		leaves = heap.NewHeap(tree.capacity, maxLess[pMove])
		limit = math.MinInt16
	} else {
		leaves = heap.NewHeap(tree.capacity, minLess[pMove])
		limit = math.MaxInt16
	}
	tree.expandNode(&tree.root, leaves, &limit)
}

func (tree *tree[pMove]) expandNode(node *node[pMove], leaves *heap.Heap[*node[pMove]], limit *int16) {
	node.draw = true
	if node.child == nil {
		hasChildren := false
		moves := tree.game.PossibleMoves()
		for {
			move, ok := moves(*limit)
			if !ok {
				break
			}
			hasChildren = true
			if move.IsWin() {
				tree.removeNode(node)
				return
			}
			child := tree.addChild(node, move)
			if !child.move.IsDraw() {
				node.draw = false
				if minNode, pushedOut := leaves.Add(child); pushedOut {
					if minNode.alive {
						*limit = minNode.move.Score()
						tree.removeNode(minNode)
					}
				}
			}
		}
		if !hasChildren {
			tree.removeNode(node)
		}
		return
	}

	for child := node.child; child != nil; {
		sibling := child.sibling
		if !child.draw {
			tree.game.PlayMove(child.move)
			tree.expandNode(child, leaves, limit)
			tree.game.UndoMove(child.move)
			node.draw = node.draw && child.draw
		}
		child = sibling
	}
}

func (tree *tree[pMove]) addChild(parent *node[pMove], move pMove) *node[pMove] {
	var child *node[pMove]
	if tree.freeNodes != nil {
		child = tree.freeNodes
		tree.freeNodes = child.parent
		child.parent = parent
		child.move = move
		child.draw = move.IsDraw()
		child.alive = true
	} else {
		child = &node[pMove]{parent: parent, move: move, draw: move.IsDraw(), alive: true}
	}
	if parent.child == nil {
		parent.child = child
	} else if parent.child.sibling == nil {
		parent.child.sibling = child
	} else {
		child.sibling = parent.child.sibling
		parent.child.sibling = child
	}
	return child
}

func (tree *tree[move]) removeNode(node *node[move]) {
	if !node.alive {
		return
	}
	if node == nil || node.parent == nil {
		return
	}

	if node.parent.child.sibling != nil {
		tree.detachNode(node)
		tree.freeNode(node)
	} else {
		tree.removeNode(node.parent.parent)
	}
}

func (tree *tree[move]) detachNode(node *node[move]) {
	parent := node.parent
	if parent.child == node {
		parent.child = node.sibling
		return
	}

	for child := parent.child; child != nil; child = child.sibling {
		if child.sibling == node {
			child.sibling = node.sibling
		}
	}
}

func (tree *tree[move]) freeNode(node *node[move]) {
	for child := node.child; child != nil; {
		sibling := child.sibling
		tree.freeNode(child)
		child = sibling
	}
	node.parent = tree.freeNodes
	node.child = nil
	node.sibling = nil
	node.alive = false
	tree.freeNodes = node

}

package tree

import (
	"bytes"
	"fmt"

	"game_of_stones/heap"
)

type GameState int

type iMove interface {
	IsWin() bool
	IsDraw() bool
}

type iGame[move iMove] interface {
	PlayMove(move)
	UndoMove(move)
	PossibleMoves(result *[]move)
	Less(move, move) bool
}

type node[move iMove] struct {
	child *node[move]
	prev  *node[move]
	next  *node[move]
	move  move
}

type Tree[game iGame[move], move iMove] struct {
	game          iGame[move]
	root          *node[move]
	current       *node[move]
	capacity      int
	maxDepth      int
	possibleMoves []move
	freeNodes     []*node[move]
}

func NewTree[g iGame[m], m iMove](game g, capacity int) *Tree[g, m] {

	tree := &Tree[g, m]{
		game:     game,
		capacity: capacity,
	}
	tree.root = &node[m]{}
	tree.current = tree.root
	return tree
}

type nodePair[move iMove] struct {
	child, parent *node[move]
}

func (tree *Tree[game, move]) grow() {
	var less func(a, b nodePair[move]) bool
	if tree.maxDepth%2 == 0 {
		less = func(a, b nodePair[move]) bool {
			return tree.game.Less(a.child.move, b.child.move)
		}
	} else {
		less = func(a, b nodePair[move]) bool {
			return tree.game.Less(b.child.move, a.child.move)
		}
	}
	tree.growRec(heap.NewHeap(tree.capacity, less), tree.root, 0)
	tree.maxDepth++
}

func (tree *Tree[game, move]) growRec(leaves *heap.Heap[nodePair[move]], node *node[move], depth int) {
	if depth < tree.maxDepth {
		child := node.child
		for child != nil {
			tree.game.PlayMove(child.move)
			tree.growRec(leaves, child, depth+1)
			tree.game.UndoMove(child.move)
			child = child.next
		}
		return
	}
	tree.game.PossibleMoves(&tree.possibleMoves)
	for _, childMove := range tree.possibleMoves {
		childNode := tree.acqireNode(childMove)

		pair := nodePair[move]{child: childNode, parent: node}
		if leaves.WillAdd(pair) {
			if node.child != nil {
				childNode.next = node.child
				node.child.prev = childNode
			}
			node.child = childNode

			if minPair, ok := leaves.Add(pair); ok {
				minNode := minPair.child
				if minNode.prev != nil {
					if minNode.next != nil {
						minNode.prev.next = minNode.next
						minNode.next.prev = minNode.prev
					} else {
						minNode.prev.next = nil
					}
				} else {
					minPair.parent.child = minNode.next
				}
				tree.releaseNode(minPair.child)
			}
		} else {
			tree.releaseNode(childNode)
		}
	}
}

func (tree *Tree[game, move]) acqireNode(m move) *node[move] {
	nFreeNodes := len(tree.freeNodes)
	if nFreeNodes > 0 {
		result := tree.freeNodes[nFreeNodes-1]
		result.move = m
		tree.freeNodes = tree.freeNodes[:nFreeNodes-1]
		return result
	}
	return &node[move]{
		move: m,
	}
}

func (tree *Tree[game, move]) releaseNode(node *node[move]) {
	node.next = nil
	node.prev = nil
	node.child = nil
	tree.freeNodes = append(tree.freeNodes, node)
}

func (tree *Tree[game, move]) String() string {
	return tree.root.String()
}

func (node *node[move]) String() string {
	buf := &bytes.Buffer{}
	node.string(buf, 0, "%v\n")
	return buf.String()
}

func (tree *Tree[game, move]) GoString() string {
	buf := &bytes.Buffer{}
	tree.root.string(buf, 0, "%#v\n")
	return buf.String()
}

func (node *node[move]) GoString() string {
	buf := &bytes.Buffer{}
	node.string(buf, 0, "%#v\n")
	return buf.String()
}

func (node *node[move]) string(buf *bytes.Buffer, level int, format string) {
	for range level {
		buf.WriteString("|   ")
	}
	fmt.Fprintf(buf, format, node.move)
	child := node.child
	for child != nil {
		child.string(buf, level+1, format)
		child = child.next
	}
}

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
	parent *node[move]
	child  *node[move]
	prev   *node[move]
	next   *node[move]
	move   move
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

func (tree *Tree[game, move]) Grow() {
	tree.grow(heap.NewHeap(tree.capacity, tree.selectLess()), tree.root, 0)
	tree.trim(tree.root, 0)
	tree.maxDepth++
}

func (tree *Tree[game, move]) selectLess() func(a, b *node[move]) bool {
	if tree.maxDepth%2 == 0 {
		return func(a, b *node[move]) bool {
			return tree.game.Less(a.move, b.move)
		}
	} else {
		return func(a, b *node[move]) bool {
			return tree.game.Less(b.move, a.move)
		}
	}
}

func (tree *Tree[game, move]) grow(leaves *heap.Heap[*node[move]], node *node[move], depth int) {
	if depth < tree.maxDepth {
		child := node.child
		for child != nil {
			tree.game.PlayMove(child.move)
			tree.grow(leaves, child, depth+1)
			tree.game.UndoMove(child.move)
			child = child.next
		}
		return
	}
	tree.game.PossibleMoves(&tree.possibleMoves)
	for _, childMove := range tree.possibleMoves {
		childNode := tree.acqireNode(node, childMove)

		if leaves.WillAdd(childNode) {
			if node.child != nil {
				childNode.next = node.child
				node.child.prev = childNode
			}
			node.child = childNode

			tree.validate()
			if minLeaf, ok := leaves.Add(childNode); ok {
				if minLeaf.prev != nil {
					if minLeaf.next != nil {
						minLeaf.prev.next = minLeaf.next
						minLeaf.next.prev = minLeaf.prev
					} else {
						minLeaf.prev.next = nil
					}
				} else {
					minLeaf.parent.child = minLeaf.next
					if minLeaf.next != nil {
						minLeaf.next.prev = nil
					}
				}
				tree.releaseNode(minLeaf)
			}
		} else {
			tree.releaseNode(childNode)
		}
		tree.validate()
	}
	fmt.Println(tree)
}

type trimResult int

const (
	inconclusive trimResult = iota
	winning
	losing
)

func (tree *Tree[game, move]) trim(node *node[move], depth int) trimResult {
	if depth < tree.maxDepth {
		child := node.child
		for child != nil {
			result := tree.trim(child, depth+1)
			_ = result // TODO
			child = child.next
		}
		return inconclusive
	}

	if node.child == nil {
		return winning
	}

	if node.child.move.IsWin() {
		return losing
	}

	return inconclusive
}

func (tree *Tree[game, move]) acqireNode(parent *node[move], m move) *node[move] {
	fmt.Print(">>> acqire:  ", m)
	if parent.parent != nil {
		fmt.Print(" | parent: ", parent.move)
	}
	fmt.Println()
	nFreeNodes := len(tree.freeNodes)
	if nFreeNodes > 0 {
		result := tree.freeNodes[nFreeNodes-1]
		result.parent = parent
		result.move = m
		tree.freeNodes = tree.freeNodes[:nFreeNodes-1]
		return result
	}
	return &node[move]{
		parent: parent,
		move:   m,
	}
}

func (tree *Tree[game, move]) releaseNode(node *node[move]) {
	fmt.Print("<<< release: ", node.move)
	if node.parent != nil {
		fmt.Print(" | parent: ", node.parent.move)
	}
	if node.child != nil {
		fmt.Print(" | child:", node.child.move)
	}
	if node.next != nil {
		fmt.Print(" | next: ", node.next.move)
	}
	if node.prev != nil {
		fmt.Print(" | prev: ", node.prev.move)
	}
	fmt.Println()
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

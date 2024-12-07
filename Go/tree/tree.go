package tree

import (
	"bytes"
	"fmt"

	"game_of_stones/heap"
)

type GameState int

type iScore interface {
	IsWinning() bool
	IsDrawing() bool
}

type iMove[score iScore] interface {
	Score() score
}

type iGame[move iMove[score], score iScore] interface {
	PlayMove(move)
	UndoMove(move)
	PossibleMoves(result *[]move)
	Less(move, move) bool
}

type node[move iMove[score], score iScore] struct {
	parent *node[move, score]
	child  *node[move, score]
	prev   *node[move, score]
	next   *node[move, score]
	move   move
}

type Tree[game iGame[move, score], move iMove[score], score iScore] struct {
	game          iGame[move, score]
	root          *node[move, score]
	current       *node[move, score]
	capacity      int
	maxDepth      int
	possibleMoves []move
	freeNodes     []*node[move, score]
}

func NewTree[g iGame[m, s], m iMove[s], s iScore](game g, capacity int) *Tree[g, m, s] {

	tree := &Tree[g, m, s]{
		game:     game,
		capacity: capacity,
	}
	tree.root = &node[m, s]{}
	tree.current = tree.root
	return tree
}

func (tree *Tree[game, move, score]) Grow() {
	tree.grow(heap.NewHeap(tree.capacity, tree.selectLess()), tree.root, 0)
	tree.trim(tree.root, 0)
	tree.maxDepth++
}

func (tree *Tree[game, move, score]) selectLess() func(a, b *node[move, score]) bool {
	if tree.maxDepth%2 == 0 {
		return func(a, b *node[move, score]) bool {
			return tree.game.Less(a.move, b.move)
		}
	} else {
		return func(a, b *node[move, score]) bool {
			return tree.game.Less(b.move, a.move)
		}
	}
}

func (tree *Tree[game, move, score]) grow(leaves *heap.Heap[*node[move, score]], node *node[move, score], depth int) {
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

func (tree *Tree[game, move, score]) trim(node *node[move, score], depth int) trimResult {
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

	if node.child.move.Score().IsWinning() {
		return losing
	}

	return inconclusive
}

func (tree *Tree[game, move, score]) acqireNode(parent *node[move, score], m move) *node[move, score] {
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
	return &node[move, score]{
		parent: parent,
		move:   m,
	}
}

func (tree *Tree[game, move, score]) releaseNode(node *node[move, score]) {
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

func (tree *Tree[game, move, score]) String() string {
	return tree.root.String()
}

func (node *node[move, score]) String() string {
	buf := &bytes.Buffer{}
	node.string(buf, 0, "%v\n")
	return buf.String()
}

func (tree *Tree[game, move, score]) GoString() string {
	buf := &bytes.Buffer{}
	tree.root.string(buf, 0, "%#v\n")
	return buf.String()
}

func (node *node[move, score]) GoString() string {
	buf := &bytes.Buffer{}
	node.string(buf, 0, "%#v\n")
	return buf.String()
}

func (node *node[move, score]) string(buf *bytes.Buffer, level int, format string) {
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

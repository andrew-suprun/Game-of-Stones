package tree

import (
	"bytes"
	"fmt"

	"game_of_stones/heap"
	"game_of_stones/score"
)

type GameState int

type iMove interface {
	Score() score.Score
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

func (node *node[move]) addChild(child *node[move]) {
	if node.child != nil {
		child.next = node.child
		node.child.prev = child
	}
	node.child = child
}

func (node *node[move]) remove() {
	if node.prev != nil {
		if node.next != nil {
			node.prev.next = node.next
			node.next.prev = node.prev
		} else {
			node.prev.next = nil
		}
	} else {
		node.parent.child = node.next
		if node.next != nil {
			node.next.prev = nil
		}
	}
}

type Tree[game iGame[move], move iMove] struct {
	game          iGame[move]
	root          *node[move]
	current       *node[move]
	capacity      int
	maxDepth      int
	possibleMoves []move
	freeNodes     []*node[move]
	children      []*node[move]
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
	fmt.Printf("grown\n%#v\n", tree)
	tree.trim(tree.root, 0)
	fmt.Printf("trimmed\n%#v\n", tree)
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
			if child.move.Score().State() != score.Draw {
				tree.game.PlayMove(child.move)
				tree.grow(leaves, child, depth+1)
				tree.game.UndoMove(child.move)
			}
			child = child.next
		}
		return
	}
	tree.game.PossibleMoves(&tree.possibleMoves)
	for _, childMove := range tree.possibleMoves {
		childNode := tree.acqireNode(node, childMove)
		childScoreState := childMove.Score().State()
		if childScoreState == score.Draw || childScoreState == score.Win {
			node.addChild(childNode)
		} else if leaves.WillAdd(childNode) {
			node.addChild(childNode)
			if minLeaf, ok := leaves.Add(childNode); ok {
				minLeaf.remove()
				tree.releaseNode(minLeaf)
			}
		} else {
			tree.releaseNode(childNode)
		}
		tree.validate()
	}
}

func (tree *Tree[game, move]) trim(parent *node[move], depth int) bool {
	// fmt.Printf(">>> trim: %#v, dep: %d, max: %d\n", parent.move, depth, tree.maxDepth)
	if depth > tree.maxDepth {
		// fmt.Printf("<<< trim.1: %#v, %v\n", parent.move, parent.move.Score().State == score.Win)
		return parent.move.Score().State() == score.Win
	}

	if parent.move.Score().State() == score.Draw {
		// fmt.Printf("<<< trim.2: %#v, false\n", parent.move)
		return false
	}

	if parent.child == nil {
		// fmt.Printf("<<< trim.3: %#v, true\n", parent.move)
		return true
	}

	child := parent.child
	tree.children = []*node[move]{}
	for child != nil {
		tree.children = append(tree.children, child)
		child = child.next
	}
	for _, child := range tree.children {
		if tree.trim(child, depth+1) {
			tree.trimBranch(child)
		}
	}
	// fmt.Printf("<<< trim.4: %#v, %v\n", parent.move, parent.child == nil)
	return parent.child == nil
}

func (tree *Tree[game, move]) trimBranch(node *node[move]) {
	child := node.child
	for child != nil {
		tree.trimBranch(child)
		child = node.child
	}
	node.remove()
	tree.releaseNode(node)
}

func (tree *Tree[game, move]) acqireNode(parent *node[move], m move) *node[move] {
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

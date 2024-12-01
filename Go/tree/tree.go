package tree

import (
	"bytes"
	"fmt"
)

type GameState int

const (
	Inconclusive GameState = iota
	MinnerWin
	Draw
	MaxerWin
)

type Player int

const (
	Maxer  Player = 1
	Minner Player = 2
)

type iMove interface {
	State() GameState
}

type iGame[move iMove] interface {
	Turn() Player
	PlayMove(move)
	UndoMove(move)
	PossibleMoves(result *[]move) GameState
	Less(move, move) bool
}

type node[move iMove] struct {
	parent *node[move]
	child  *node[move]
	prev   *node[move]
	next   *node[move]
	move   move
}

type nodeHeap[game iGame[move], move iMove] struct {
	game  *game
	nodes []*node[move]
}

type nodeHeapMaxer[game iGame[move], move iMove] struct {
	nodeHeap[game, move]
}

type nodeHeapMinner[game iGame[move], move iMove] struct {
	nodeHeap[game, move]
}

func (h *nodeHeapMaxer[game, move]) Less(i, j int) bool {
	return (*h.game).Less(h.nodes[i].move, h.nodes[j].move)
}

func (h *nodeHeapMinner[game, move]) Less(i, j int) bool {
	return (*h.game).Less(h.nodes[j].move, h.nodes[i].move)
}

func (h *nodeHeap[game, move]) Swap(i, j int) {
	h.nodes[i], h.nodes[j] = h.nodes[j], h.nodes[i]
}

func (h *nodeHeap[game, move]) Len() int {
	return len(h.nodes)
}

func (h *nodeHeap[game, move]) Pop() (v *node[move]) {
	h.nodes, v = h.nodes[:h.Len()-1], h.nodes[h.Len()-1]
	return
}

func (h *nodeHeap[game, move]) Push(v *node[move]) {
	h.nodes = append(h.nodes, v)
}

type Tree[game iGame[move], move iMove] struct {
	game          iGame[move]
	root          *node[move]
	current       *node[move]
	capacity      int
	curDepth      int
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

func (tree *Tree[game, move]) Expand() bool {
	tree.findLeaf()
	if tree.curDepth > 0 || tree.maxDepth == 0 {
		tree.expand()
		return true
	}
	return false
}

func (tree *Tree[game, move]) findLeaf() {
	findFirstLeaf := tree.curDepth == 0
	for {
		if findFirstLeaf {
			if tree.current.child != nil {
				tree.current = tree.current.child
				tree.curDepth++
				tree.game.PlayMove(tree.current.move)
				continue
			}

			if tree.curDepth < tree.maxDepth {
				findFirstLeaf = false
				continue
			}

			return
		}

		if tree.current.next != nil {
			tree.game.UndoMove(tree.current.move)
			tree.current = tree.current.next
			tree.game.PlayMove(tree.current.move)
			findFirstLeaf = true
			continue
		}

		if tree.curDepth == 0 {
			tree.maxDepth++
			return
		}

		tree.game.UndoMove(tree.current.move)
		tree.current = tree.current.parent
		tree.curDepth--
	}
}

func (tree *Tree[game, move]) expand() GameState {
	gameState := tree.game.PossibleMoves(&tree.possibleMoves)
	// TODO: Implement terminal moves

	if gameState == Inconclusive {
		parent := tree.current
		next := tree.acqireNode(parent, tree.possibleMoves[0])
		for _, prevMove := range tree.possibleMoves[1:] {
			prev := tree.acqireNode(parent, prevMove)
			prev.next = next
			next.prev = prev
			next = prev
		}
		tree.current.child = next
	}

	return gameState
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

func (tree *Tree[game, move]) releaseNode(n *node[move]) {
	n.next = nil
	n.prev = nil
	n.child = nil
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

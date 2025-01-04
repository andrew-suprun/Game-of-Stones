package tree

import (
	"bytes"
	"fmt"
	. "game_of_stones/turn"
	"math"
)

type Ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 |
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 |
		~float32 | ~float64
}

type Node[m Move[Value], Value Ordered] struct {
	move     m
	nSims    int32
	children []Node[m, Value]
}

type Game[m Move[Value], Value Ordered] interface {
	Turn() Turn
	TopMoves(result *[]m)
	PlayMove(move m)
	UndoMove(move m)
	ParseMove(move string) (m, error)
	SameMove(a, b m) bool
	SetValue(move *m, value Value)
	SetDecisive(move *m, draw bool)
}

type Move[Value Ordered] interface {
	fmt.GoStringer
	fmt.Stringer
	Value() Value
	IsDecisive() bool
	IsTerminal() bool
}

type Tree[g Game[m, v], m Move[v], v Ordered] struct {
	root              *Node[m, v]
	game              Game[m, v]
	topMoves          []m
	maxChildren       int32
	explorationFactor float64
}

func NewTree[g Game[m, v], m Move[v], v Ordered](
	game g,
	maxChildren int,
	explorationFactor float64,
) *Tree[g, m, v] {
	return &Tree[g, m, v]{
		root:              &Node[m, v]{},
		game:              game,
		topMoves:          make([]m, 0, maxChildren),
		maxChildren:       int32(maxChildren),
		explorationFactor: explorationFactor,
	}
}

func (t *Tree[g, m, v]) Expand() (m, int) {
	t.expand(t.root)
	t.validate()
	return t.root.move, int(t.root.nSims)
}

func (tree *Tree[game, move, value]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)
	tree.game.SetValue(&toPlay, 0)
	oldRoot := tree.root
	tree.root = &Node[move, value]{
		move: toPlay,
	}
	for _, child := range oldRoot.children {
		if tree.game.SameMove(toPlay, child.move) {
			tree.root.nSims = child.nSims
			tree.root.children = child.children
			return
		}
	}
}

func (tree *Tree[game, move, value]) BestMove() (move, int) {
	bestNode := tree.root.children[0]

	if tree.game.Turn() == First {
		for _, node := range tree.root.children {
			if bestNode.move.Value() < node.move.Value() {
				bestNode = node
			}
		}
	} else {
		for _, node := range tree.root.children {
			if bestNode.move.Value() > node.move.Value() {
				bestNode = node
			}
		}
	}

	return bestNode.move, int(bestNode.nSims)
}

func (t *Tree[g, m, v]) expand(parent *Node[m, v]) {
	if parent.move.IsDecisive() {
		parent.nSims += int32(cap(t.topMoves))
		if len(parent.children) > 0 {
			t.updateStats(parent)
		}
		return
	}

	if parent.children == nil {
		t.game.TopMoves(&t.topMoves)
		parent.children = make([]Node[m, v], len(t.topMoves))
		for i, childMove := range t.topMoves {
			parent.children[i] = Node[m, v]{
				move:  childMove,
				nSims: 1,
			}
		}
	} else {
		selectedChild := parent.selectChild(t.game.Turn(), t.explorationFactor)
		t.game.PlayMove(selectedChild.move)
		t.expand(selectedChild)
		t.game.UndoMove(selectedChild.move)
	}

	t.updateStats(parent)
}

func (node *Node[move, value]) selectChild(turn Turn, explorationFactor float64) *Node[move, value] {
	var coeff float64 = 1
	if turn == Second {
		coeff = -1
	}
	selectedChild := &node.children[0]
	logParentSims := math.Log(float64(node.nSims))
	maxV := math.Inf(-1)
	for i, child := range node.children {
		if child.move.IsDecisive() {
			continue
		}
		v := coeff*float64(child.move.Value()) + explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
		if v > maxV {
			maxV = v
			selectedChild = &node.children[i]
		}
	}

	return selectedChild
}

func (t *Tree[g, m, v]) updateStats(node *Node[m, v]) {
	node.nSims = 0
	t.game.SetValue(&node.move, node.children[0].move.Value())
	t.game.SetDecisive(&node.move, true)
	if t.game.Turn() == First {
		for _, child := range node.children {
			node.nSims += child.nSims
			t.game.SetValue(&node.move, max(node.move.Value(), child.move.Value()))
			t.game.SetDecisive(&node.move, node.move.IsDecisive() && child.move.IsDecisive())
		}
	} else {
		for _, child := range node.children {
			node.nSims += child.nSims
			t.game.SetValue(&node.move, min(node.move.Value(), child.move.Value()))
			t.game.SetDecisive(&node.move, node.move.IsDecisive() && child.move.IsDecisive())
		}
	}
}

func (tree *Tree[game, move, value]) String() string {
	return tree.root.String()
}

func (tree *Tree[game, move, value]) GoString() string {
	return tree.root.GoString()
}

func (node *Node[move, value]) String() string {
	buf := &bytes.Buffer{}
	node.string(buf, "%v", 0)
	return buf.String()
}

func (node *Node[move, value]) GoString() string {
	buf := &bytes.Buffer{}
	node.string(buf, "%#v", 0)
	return buf.String()
}

func (node *Node[move, value]) string(buf *bytes.Buffer, format string, level int) {
	buf.WriteByte('\n')
	for range level {
		buf.WriteString("|   ")
	}
	fmt.Fprintf(buf, "%#v s: %d", node.move, node.nSims)
	for _, child := range node.children {
		child.string(buf, format, level+1)
	}
}

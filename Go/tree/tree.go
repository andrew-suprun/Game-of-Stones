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

type Game[move Move[value], value Ordered] interface {
	Turn() Turn
	TopMoves(result *[]move)
	PlayMove(move move)
	UndoMove(move move)
	ParseMove(move string) (move, error)
	SameMove(a, b move) bool
	SetValue(move *move, value value)
	SetDecisive(move *move, draw bool)
}

type Move[Value Ordered] interface {
	fmt.GoStringer
	fmt.Stringer
	Value() Value
	IsDecisive() bool
	IsTerminal() bool
}

type Tree[move Move[value], value Ordered] struct {
	root              *node[move, value]
	game              Game[move, value]
	topMoves          []move
	maxChildren       int32
	explorationFactor float64
}

type node[move Move[value], value Ordered] struct {
	move     move
	nSims    int32
	children []node[move, value]
}

func NewTree[move Move[value], value Ordered](
	game Game[move, value],
	maxChildren int,
	explorationFactor float64,
) *Tree[move, value] {
	return &Tree[move, value]{
		root:              &node[move, value]{},
		game:              game,
		topMoves:          make([]move, 0, maxChildren),
		maxChildren:       int32(maxChildren),
		explorationFactor: explorationFactor,
	}
}

func (t *Tree[m, v]) Expand() (m, int) {
	t.expand(t.root)
	t.validate()
	return t.root.move, int(t.root.nSims)
}

func (tree *Tree[move, value]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)
	tree.game.SetValue(&toPlay, 0)
	oldRoot := tree.root
	tree.root = &node[move, value]{
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

func (tree *Tree[move, value]) BestMove() (move, int) {
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

func (t *Tree[m, v]) expand(parent *node[m, v]) {
	if parent.move.IsDecisive() {
		parent.nSims += int32(cap(t.topMoves))
		if len(parent.children) > 0 {
			t.updateStats(parent)
		}
		return
	}

	if parent.children == nil {
		t.game.TopMoves(&t.topMoves)
		parent.children = make([]node[m, v], len(t.topMoves))
		for i, childMove := range t.topMoves {
			parent.children[i] = node[m, v]{
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

func (node *node[move, value]) selectChild(turn Turn, explorationFactor float64) *node[move, value] {
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

func (t *Tree[m, v]) updateStats(node *node[m, v]) {
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

func (tree *Tree[move, value]) String() string {
	return tree.root.String()
}

func (tree *Tree[move, value]) GoString() string {
	return tree.root.GoString()
}

func (node *node[move, value]) String() string {
	buf := &bytes.Buffer{}
	node.string(buf, "%v", 0)
	return buf.String()
}

func (node *node[move, value]) GoString() string {
	buf := &bytes.Buffer{}
	node.string(buf, "%#v", 0)
	return buf.String()
}

func (node *node[move, value]) string(buf *bytes.Buffer, format string, level int) {
	buf.WriteByte('\n')
	for range level {
		buf.WriteString("|   ")
	}
	fmt.Fprintf(buf, "%#v s: %d", node.move, node.nSims)
	for _, child := range node.children {
		child.string(buf, format, level+1)
	}
}

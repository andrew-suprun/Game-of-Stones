package tree

import (
	"bytes"
	"fmt"
	"math"
)

type ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 |
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 |
		~float32 | ~float64
}

type node[Move move[Value], Value ordered] struct {
	move     Move
	nSims    int32
	children []node[Move, Value]
}

type Turn int

const (
	First Turn = iota
	Second
)

func (turn Turn) String() string {
	switch turn {
	case First:
		return "First"
	case Second:
		return "Second"
	}
	panic("Turn.String()")
}

type game[Move move[Value], Value ordered] interface {
	Turn() Turn
	TopMoves(result *[]Move)
	PlayMove(move Move)
	UndoMove(move Move)
	ParseMove(move string) (Move, error)
	SameMove(a, b Move) bool
	SetValue(move *Move, value Value)
}

type move[Value ordered] interface {
	fmt.GoStringer
	fmt.Stringer
	Value() Value
	IsDecisive() bool
	IsTerminal() bool
}

type Tree[Game game[Move, Value], Move move[Value], Value ordered] struct {
	root              *node[Move, Value]
	game              game[Move, Value]
	topMoves          []Move
	maxChildren       int32
	explorationFactor float64
}

func NewTree[Game game[Move, Value], Move move[Value], Value ordered](
	game Game,
	maxChildren int,
	explorationFactor float64,
) *Tree[Game, Move, Value] {
	return &Tree[Game, Move, Value]{
		root:              &node[Move, Value]{},
		game:              game,
		topMoves:          make([]Move, 0, maxChildren),
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

func (t *Tree[g, m, v]) expand(parent *node[m, v]) {
	if parent.move.IsDecisive() {
		parent.nSims += t.maxChildren
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

func (t *Tree[g, m, v]) updateStats(node *node[m, v]) {
	node.nSims = 0
	t.game.SetValue(&node.move, node.children[0].move.Value())
	if t.game.Turn() == First {
		for _, child := range node.children {
			node.nSims += child.nSims
			childValue := child.move.Value()
			if node.move.Value() < childValue {
				t.game.SetValue(&node.move, childValue)
			}
		}
	} else {
		for _, child := range node.children {
			node.nSims += child.nSims
			childValue := child.move.Value()
			if node.move.Value() > childValue {
				t.game.SetValue(&node.move, childValue)
			}
		}
	}
}

func (tree *Tree[game, move, value]) String() string {
	return tree.root.String()
}

func (tree *Tree[game, move, value]) GoString() string {
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

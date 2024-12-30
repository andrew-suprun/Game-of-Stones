package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[Move move] struct {
	move     Move
	value    float32
	nSims    int32
	children []node[Move]
}

type Turn int

const (
	First Turn = iota
	Second
)

type game[Move move] interface {
	Turn() Turn
	TopMoves(result *[]MoveValue[Move])
	PlayMove(move Move)
	UndoMove(move Move)
	ParseMove(move string) (Move, error)
	SameMove(a, b Move) bool
}

type move interface {
	fmt.Stringer
	State() State
}

type State int8

const (
	Nonterminal State = iota
	BlackWin
	WhiteWin
	Draw
)

type MoveValue[Move move] struct {
	Move  Move
	Value float32
}

type Tree[Game game[Move], Move move] struct {
	root              *node[Move]
	game              game[Move]
	topMoves          []MoveValue[Move]
	maxChildren       int32
	explorationFactor float64
}

func NewTree[Game game[Move], Move move](game Game, maxChildren int32, explorationFactor float64) *Tree[Game, Move] {
	return &Tree[Game, Move]{
		root:              &node[Move]{},
		game:              game,
		topMoves:          make([]MoveValue[Move], 0, maxChildren),
		maxChildren:       maxChildren,
		explorationFactor: explorationFactor,
	}
}

func (t *Tree[g, m]) Expand() {
	t.expand(t.root)
}

func (tree *Tree[game, move]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)
	oldRoot := tree.root
	tree.root = &node[move]{
		move: toPlay,
	}
	for _, child := range oldRoot.children {
		if tree.game.SameMove(toPlay, child.move) {
			tree.root.nSims = child.nSims
			tree.root.value = child.value
			tree.root.children = child.children
			return
		}
	}
}

func (tree *Tree[game, move]) BestMove() move {
	var bestNode node[move]
	for _, node := range tree.root.children {
		if bestNode.nSims < node.nSims {
			bestNode = node
		}
	}
	return bestNode.move
}

func (t *Tree[g, m]) expand(parent *node[m]) {
	if parent.move.State() != Nonterminal {
		parent.nSims += t.maxChildren
		return
	}

	if parent.children == nil {
		t.game.TopMoves(&t.topMoves)
		parent.children = make([]node[m], len(t.topMoves))
		if t.game.Turn() == First {
			parent.value = float32(math.Inf(-1))
			for i, childMove := range t.topMoves {
				parent.children[i] = node[m]{
					move:  childMove.Move,
					value: childMove.Value,
					nSims: 1,
				}
				if parent.value < childMove.Value {
					parent.value = childMove.Value
				}
			}
		} else {
			parent.value = float32(math.Inf(1))
			for i, childMove := range t.topMoves {
				parent.children[i] = node[m]{
					move:  childMove.Move,
					value: childMove.Value,
					nSims: 1,
				}
				if parent.value > childMove.Value {
					parent.value = childMove.Value
				}
			}
		}

		parent.nSims += int32(len(t.topMoves))
		return
	}

	selectedChild := &parent.children[0]
	logParentSims := math.Log(float64(parent.nSims))
	if t.game.Turn() == First {
		maxV := math.Inf(-1)
		for i, child := range parent.children {
			v := float64(child.value) + t.explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
			if v > maxV {
				maxV = v
				selectedChild = &parent.children[i]
			}
		}
		t.game.PlayMove(selectedChild.move)
		t.expand(selectedChild)
		t.game.UndoMove(selectedChild.move)

		parent.nSims = 0
		parent.value = float32(math.Inf(-1))
		for _, child := range parent.children {
			parent.nSims += child.nSims
			if child.value > parent.value {
				parent.value = child.value
			}
		}
	} else {
		maxV := math.Inf(-1)
		for i, child := range parent.children {
			v := float64(-child.value) + t.explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
			if v > maxV {
				maxV = v
				selectedChild = &parent.children[i]
			}
		}
		t.game.PlayMove(selectedChild.move)
		t.expand(selectedChild)
		t.game.UndoMove(selectedChild.move)

		parent.nSims = 0
		parent.value = float32(math.Inf(1))
		for _, child := range parent.children {
			parent.nSims += child.nSims
			if child.value < parent.value {
				parent.value = child.value
			}
		}
	}
}

func (tree *Tree[game, move]) String() string {
	return tree.root.String()
}

func (tree *Tree[game, move]) GoString() string {
	return tree.root.GoString()
}

func (node *node[move]) String() string {
	buf := &bytes.Buffer{}
	node.string(buf, "%v", 0)
	return buf.String()
}

func (node *node[move]) GoString() string {
	buf := &bytes.Buffer{}
	node.string(buf, "%#v", 0)
	return buf.String()
}

func (node *node[move]) string(buf *bytes.Buffer, format string, level int) {
	for range level {
		buf.WriteString("|   ")
	}
	fmt.Fprintf(buf, format, node.move)
	if node.move.State() == Nonterminal {
		fmt.Fprintf(buf, " v: %.0f s: %d\n", node.value, node.nSims)
	} else {
		fmt.Fprintf(buf, "\n")
	}
	for _, child := range node.children {
		child.string(buf, format, level+1)
	}
}

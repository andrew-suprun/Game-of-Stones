package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	move     move
	value    float32
	nSims    int32
	children []node[move]
}

type Turn int

const (
	First Turn = iota
	Second
)

type iGame[move iMove] interface {
	Turn() Turn
	TopMoves(result *[]MoveValue[move])
	PlayMove(move move)
	UndoMove(move move)
	ParseMove(moveStr string) (move, error)
}

type iMove interface {
	fmt.Stringer
	State() State
}

type State byte

const (
	Nonterminal State = iota
	BlackWin
	WhiteWin
	Draw
)

type MoveValue[Move iMove] struct {
	Move  Move
	Value float32
}

type Tree[Game iGame[Move], Move iMove] struct {
	root        *node[Move]
	game        iGame[Move]
	topMoves    []MoveValue[Move]
	maxChildren int32
	c           float64
}

func NewTree[Game iGame[Move], Move iMove](game Game, maxChildren int32, explorationFactor float64) *Tree[Game, Move] {
	return &Tree[Game, Move]{
		root:        &node[Move]{},
		game:        game,
		topMoves:    make([]MoveValue[Move], 0, maxChildren),
		maxChildren: maxChildren,
		c:           explorationFactor,
	}
}

func (t *Tree[g, m]) Expand() {
	t.expand(t.root)
}

func (tree *Tree[game, move]) CommitMove(toPlay string) error {
	for i := range tree.root.children {
		child := &tree.root.children[i]
		if child.move.String() == toPlay {
			tree.root.children[i] = node[move]{}
			tree.root = child
			tree.game.PlayMove(child.move)
			return nil
		}
	}
	tree.root = &node[move]{}
	m, _ := tree.game.ParseMove(toPlay)
	tree.game.PlayMove(m)
	return nil
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
			v := float64(child.value) + t.c*math.Sqrt(logParentSims/float64(child.nSims))
			// fmt.Printf("child %v value %.3f S %.3f\n", child.move, child.value, v)
			if v > maxV {
				maxV = v
				selectedChild = &parent.children[i]
				// fmt.Println("  selected")
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
		maxV := math.Inf(1)
		for i, child := range parent.children {
			v := float64(-child.value) + t.c*math.Sqrt(logParentSims/float64(child.nSims))
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

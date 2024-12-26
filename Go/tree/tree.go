package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	move     move
	nSims    int32
	value    float32
	children []node[move]
}

type Turn int

const (
	First Turn = iota
	Second
)

type iGame[move iMove] interface {
	Turn() Turn
	TopMoves(result *[]move)
	PlayMove(move move)
	UndoMove(move move)
	ParseMove(string) (move, error)
	SameMove(a, b move) bool
}

type iMove interface {
	Value() float32
	IsWinning() bool
	IsDrawing() bool
}

type Tree[game iGame[move], move iMove] struct {
	root        *node[move]
	game        iGame[move]
	topMoves    []move
	maxChildren int32
}

func NewTree[g iGame[m], m iMove](game g, maxChildren int32) *Tree[g, m] {
	return &Tree[g, m]{
		root:        &node[m]{},
		game:        game,
		topMoves:    make([]m, 0, maxChildren),
		maxChildren: maxChildren,
	}
}

func (t *Tree[g, m]) Expand() {
	t.expand(t.root)
}

func (tree *Tree[game, move]) CommitMove(moveStr string) error {
	toPlay, err := tree.game.ParseMove(moveStr)
	if err != nil {
		return err
	}
	for i, child := range tree.root.children {
		if tree.game.SameMove(child.move, toPlay) {
			newRoot := &tree.root.children[i]
			tree.root.children[i] = node[move]{}
			tree.root = newRoot
			tree.game.PlayMove(newRoot.move)
			return nil
		}
	}
	tree.root = &node[move]{
		value: toPlay.Value(),
	}
	tree.game.PlayMove(toPlay)
	return nil
}

func (t *Tree[g, m]) expand(parent *node[m]) {
	if parent.move.IsWinning() || parent.move.IsDrawing() {
		parent.nSims += t.maxChildren
		return
	}

	if parent.children == nil {
		t.game.TopMoves(&t.topMoves)
		parent.children = make([]node[m], len(t.topMoves))
		for i, childMove := range t.topMoves {
			parent.children[i] = node[m]{
				move:  childMove,
				nSims: 1,
				value: childMove.Value(),
			}
		}
		parent.nSims += int32(len(t.topMoves))
		return
	}

	selectedChild := &parent.children[0]
	lnParentSims := math.Log(float64(parent.nSims))
	if t.game.Turn() == First {
		maxV := math.Inf(-1)
		for i, child := range parent.children {
			v := float64(child.value) + math.Sqrt(lnParentSims/float64(child.nSims))
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
		maxV := math.Inf(1)
		for i, child := range parent.children {
			v := float64(-child.value) + math.Sqrt(lnParentSims/float64(child.nSims))
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
	for _, child := range node.children {
		child.string(buf, level+1, format)
	}
}

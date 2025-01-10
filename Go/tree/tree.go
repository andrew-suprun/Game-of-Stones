package tree

import (
	"bytes"
	"fmt"
	"game_of_stones/board"
	"game_of_stones/turn"
	"math"
)

type Game[move Move] interface {
	Turn() turn.Turn
	TopMoves(*[]move)
	PlayMove(move)
	UndoMove(move)
	SameMove(move, move) bool
	SetValue(*move, int16)
}

type Move interface {
	fmt.GoStringer
	fmt.Stringer
	Value() int16
	IsDecisive() bool
	IsTerminal() bool
}

type Tree[move Move] struct {
	root              *node[move]
	game              Game[move]
	topMoves          []move
	maxChildren       int32
	explorationFactor float64
}

type node[move Move] struct {
	move     move
	nSims    int32
	children []node[move]
}

func NewTree[move Move](
	game Game[move],
	maxChildren int,
	explorationFactor float64,
) *Tree[move] {
	return &Tree[move]{
		root:              &node[move]{},
		game:              game,
		topMoves:          make([]move, 0, maxChildren),
		maxChildren:       int32(maxChildren),
		explorationFactor: explorationFactor,
	}
}

func (t *Tree[m]) Expand() (m, int) {
	t.expand(t.root)
	t.validate()
	return t.root.move, int(t.root.nSims)
}

func (tree *Tree[move]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)
	tree.game.SetValue(&toPlay, 0)
	oldRoot := tree.root
	tree.root = &node[move]{
		move: toPlay,
	}

	for _, child := range oldRoot.children {
		if tree.game.SameMove(toPlay, child.move) {
			fmt.Println("found", toPlay)
			tree.root.nSims = child.nSims
			tree.root.children = child.children
			fmt.Printf("<< root.1 %v sims %d\n", tree.root.move, tree.root.nSims)
			return
		}
	}
	tree.root = &node[move]{move: toPlay}
}

func (tree *Tree[move]) BestMove() (move, int) {
	bestNode := tree.root.children[0]

	if tree.game.Turn() == turn.First {
		for _, node := range tree.root.children {
			if bestNode.move.Value() < node.move.Value() {
				bestNode = node
			}
		}
		if float64(bestNode.move.Value()) <= -board.WinValue {
			return tree.mostExplored()
		}
	} else {
		for _, node := range tree.root.children {
			if bestNode.move.Value() > node.move.Value() {
				bestNode = node
			}
		}
		if float64(bestNode.move.Value()) >= board.WinValue {
			return tree.mostExplored()
		}
	}

	return bestNode.move, int(bestNode.nSims)
}

func (tree *Tree[move]) mostExplored() (move, int) {
	bestNode := tree.root.children[0]
	for _, node := range tree.root.children {
		if bestNode.nSims < node.nSims {
			bestNode = node
		}
	}
	return bestNode.move, int(bestNode.nSims)
}

func (t *Tree[m]) expand(parent *node[m]) {
	if parent.move.IsDecisive() {
		parent.nSims += int32(cap(t.topMoves))
		if len(parent.children) > 0 {
			t.updateStats(parent)
		}
		return
	}

	if parent.children == nil {
		t.game.TopMoves(&t.topMoves)
		parent.children = make([]node[m], len(t.topMoves))
		for i, childMove := range t.topMoves {
			parent.children[i] = node[m]{
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

func (node *node[move]) selectChild(currentTurn turn.Turn, explorationFactor float64) *node[move] {
	var coeff float64 = 1
	if currentTurn == turn.Second {
		coeff = -1
	}
	selectedChild := &node.children[0]
	logParentSims := math.Log(float64(node.nSims))
	maxV := math.Inf(-1)
	for i, child := range node.children {
		v := coeff*float64(child.move.Value()) + explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
		if v > maxV {
			maxV = v
			selectedChild = &node.children[i]
		}
	}

	return selectedChild
}

func (t *Tree[m]) updateStats(node *node[m]) {
	node.nSims = 0
	value := node.children[0].move.Value()
	if t.game.Turn() == turn.First {
		for _, child := range node.children {
			node.nSims += child.nSims
			value = max(value, child.move.Value())
		}
	} else {
		for _, child := range node.children {
			node.nSims += child.nSims
			value = min(value, child.move.Value())
		}
	}
	t.game.SetValue(&node.move, value)
}

func (tree *Tree[move]) String() string {
	return tree.root.String()
}

func (tree *Tree[move]) GoString() string {
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
	buf.WriteByte('\n')
	for range level {
		buf.WriteString("|   ")
	}
	fmt.Fprintf(buf, "%#v s: %d", node.move, node.nSims)
	for _, child := range node.children {
		child.string(buf, format, level+1)
	}
}

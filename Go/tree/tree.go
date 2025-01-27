package tree

import (
	"bytes"
	"fmt"
	. "game_of_stones/common"
	"game_of_stones/game"
	"math"
)

type Game[move Equatable[move]] interface {
	Turn() Turn
	TopMoves(*[]MoveValue[move])
	PlayMove(move)
	UndoMove(move)
	Decision() (Decision, int8, int8, int8, int8)
}

type Tree[move Equatable[move]] struct {
	root              *node[move]
	game              Game[move]
	topMoves          []MoveValue[move]
	maxChildren       int32
	explorationFactor float64
}

type node[move Equatable[move]] struct {
	move     move
	value    int16
	decision Decision
	nSims    int32
	children []node[move]
}

func NewTree[move Equatable[move]](
	game Game[move],
	maxChildren int,
	explorationFactor float64,
) *Tree[move] {
	return &Tree[move]{
		root:              &node[move]{},
		game:              game,
		topMoves:          make([]MoveValue[move], 0, maxChildren),
		maxChildren:       int32(maxChildren),
		explorationFactor: explorationFactor,
	}
}

func (t *Tree[m]) Expand() bool {
	t.expand(t.root)
	t.validate()
	if t.root.decision != NoDecision {
		return false
	}
	undecided := 0
	for _, child := range t.root.children {
		if child.decision == NoDecision {
			undecided += 1
		}
	}
	return undecided > 1
}

func (tree *Tree[move]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)
	oldRoot := tree.root
	tree.root = &node[move]{
		move: toPlay,
	}

	for _, child := range oldRoot.children {
		if toPlay.Equal(child.move) {
			tree.root.nSims = child.nSims
			tree.root.children = child.children
			return
		}
	}
	tree.root = &node[move]{move: toPlay}
}

func (tree *Tree[move]) BestMove() move {
	if len(tree.root.children) == 0 {
		tree.Expand()
	}
	bestNode := tree.root.children[0]

	if tree.game.Turn() == First {
		for _, node := range tree.root.children {
			if bestNode.value < node.value {
				bestNode = node
			}
		}
		if float64(bestNode.value) <= -game.WinValue {
			return tree.mostExplored()
		}
	} else {
		for _, node := range tree.root.children {
			if bestNode.value > node.value {
				bestNode = node
			}
		}
		if float64(bestNode.value) >= game.WinValue {
			return tree.mostExplored()
		}
	}

	return bestNode.move
}

func (tree *Tree[move]) mostExplored() move {
	bestNode := tree.root.children[0]
	for _, node := range tree.root.children {
		if bestNode.nSims < node.nSims {
			bestNode = node
		}
	}
	return bestNode.move
}

func (t *Tree[m]) expand(parent *node[m]) {
	if parent.decision != NoDecision {
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
				move:     childMove.Move,
				value:    childMove.Value,
				decision: childMove.Decision,
				nSims:    1,
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

func (node *node[move]) selectChild(currentTurn Turn, explorationFactor float64) *node[move] {
	var coeff float64 = 1
	if currentTurn == Second {
		coeff = -1
	}
	selectedChild := &node.children[0]
	logParentSims := math.Log(float64(node.nSims))
	maxV := math.Inf(-1)
	for i, child := range node.children {
		v := coeff*float64(child.value) + explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
		if v > maxV {
			maxV = v
			selectedChild = &node.children[i]
		}
	}

	return selectedChild
}

func (t *Tree[m]) updateStats(node *node[m]) {
	node.nSims = 0
	value := node.children[0].value
	if t.game.Turn() == First {
		for _, child := range node.children {
			node.nSims += child.nSims
			value = max(value, child.value)
		}
	} else {
		for _, child := range node.children {
			node.nSims += child.nSims
			value = min(value, child.value)
		}
	}
	node.value = value
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

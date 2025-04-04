package tree

import (
	"bytes"
	"fmt"
	"math"

	. "game_of_stones/common"
)

type Game[move Equatable[move]] interface {
	Turn() Turn
	TopMoves(*[]MoveValue[move])
	PlayMove(move)
	UndoMove(move)
	Decision() Decision
	BoardValue() int16
}

type Tree[move Equatable[move]] struct {
	game     Game[move]
	nodes    []node
	moves    []move
	topMoves []MoveValue[move]
	history  []move
}

type node struct {
	firstChild int32
	lastChild  int32
	nSims      int32
	value      int16
	decision   Decision
}

const explorationFactor = 20

func NewTree[move Equatable[move]](
	game Game[move],
) *Tree[move] {
	var m move
	return &Tree[move]{
		game:  game,
		nodes: []node{{}},
		moves: []move{m},
	}
}

func (tree *Tree[m]) Expand() (decision Decision, forcedMove bool) {
	root := &tree.nodes[0]
	if root.decision == NoDecision {
		tree.expand(0)
		tree.validate()
	}

	undecided := 0
	for i := root.firstChild; i < root.lastChild; i++ {
		child := tree.nodes[i]
		if child.decision == NoDecision {
			if child.nSims > 1 {
				undecided++
			} else {
				return root.decision, false
			}
		}
	}
	return root.decision, undecided == 1
}

func (tree *Tree[move]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)
	tree.history = append(tree.history, toPlay)

	tree.nodes = tree.nodes[:0]
	tree.nodes = append(tree.nodes, node{
		value:    tree.game.BoardValue(),
		decision: tree.game.Decision(),
	})
	tree.moves = tree.moves[:0]
	tree.moves = append(tree.moves, toPlay)
}

func (tree *Tree[move]) Reset() {
	lastMove := tree.history[len(tree.history)-1]
	tree.history = tree.history[:len(tree.history)-1]
	tree.game.UndoMove(lastMove)

	tree.nodes = tree.nodes[:0]
	tree.nodes = append(tree.nodes, node{
		value:    tree.game.BoardValue(),
		decision: tree.game.Decision(),
	})
	var m move
	tree.moves = tree.moves[:0]
	tree.moves = append(tree.moves, m)
}

func (tree *Tree[move]) BestMove() move {
	root := tree.nodes[0]

	if tree.game.Turn() == First && root.decision == SecondWin ||
		tree.game.Turn() == Second && root.decision == FirstWin {

		for idx := root.firstChild; idx < root.lastChild; idx++ {
			node := tree.nodes[idx]
			if node.lastChild-node.firstChild == 1 {
				return tree.moves[node.firstChild]
			}
		}
	}

	bestChildIdx := root.firstChild

	if tree.game.Turn() == First {
		for idx := root.firstChild; idx < root.lastChild; idx++ {
			node := tree.nodes[idx]
			best := tree.nodes[bestChildIdx]
			if best.decision == FirstWin {
				if node.decision == FirstWin && best.nSims < node.nSims {
					bestChildIdx = idx
				}
			} else if best.decision == SecondWin {
				if node.decision != SecondWin || best.nSims < node.nSims {
					bestChildIdx = idx
				}
			} else if node.decision == FirstWin || best.value < node.value {
				bestChildIdx = idx
			}
		}
	} else {
		for idx := root.firstChild; idx < root.lastChild; idx++ {
			node := tree.nodes[idx]
			best := tree.nodes[bestChildIdx]
			if best.decision == SecondWin {
				if node.decision == SecondWin && best.nSims < node.nSims {
					bestChildIdx = idx
				}
			} else if best.decision == FirstWin {
				if node.decision != FirstWin || best.nSims < node.nSims {
					bestChildIdx = idx
				}
			} else if node.decision == SecondWin || best.value > node.value {
				bestChildIdx = idx
			}
		}
	}

	return tree.moves[bestChildIdx]
}

func (tree *Tree[m]) AvailableMoves() string {
	buf := &bytes.Buffer{}
	root := tree.nodes[0]
	fmt.Fprintf(buf, "%s: d: %v v: %v n: %d\n", tree.moves[0].String(), root.decision, root.value, root.nSims)
	for i := root.firstChild; i < root.lastChild; i++ {
		child := tree.nodes[i]
		fmt.Fprintf(buf, "  [%2d] %s: d: %v v: %v n: %d\n", i, tree.moves[i].String(), child.decision, child.value, child.nSims)
	}
	return buf.String()
}

func (tree *Tree[m]) Value() int16 {
	return tree.nodes[0].value
}

func (tree *Tree[m]) expand(parentIdx int32) {
	parent := &tree.nodes[parentIdx]

	if parent.firstChild == 0 {
		tree.game.TopMoves(&tree.topMoves)
		if len(tree.topMoves) == 0 {
			panic("Function top_moves(game, ...) returns empty result.")
		}

		parent.firstChild = int32(len(tree.nodes))
		parent.lastChild = int32(len(tree.nodes) + len(tree.topMoves))
		for _, childMoveValue := range tree.topMoves {
			tree.nodes = append(tree.nodes, node{
				nSims:    1,
				value:    childMoveValue.Value,
				decision: childMoveValue.Decision,
			})
			tree.moves = append(tree.moves, childMoveValue.Move)
		}
	} else {
		var coeff float64 = 1
		if tree.game.Turn() == Second {
			coeff = -1
		}
		selectedChildIdx := int32(-1)
		logParentSims := math.Log2(float64(parent.nSims))
		maxV := math.Inf(-1)
		for idx := parent.firstChild; idx < parent.lastChild; idx++ {
			child := tree.nodes[idx]
			if child.decision != NoDecision {
				continue
			}
			v := coeff*float64(child.value) + explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
			if v > maxV {
				maxV = v
				selectedChildIdx = idx
			}
		}

		tree.game.PlayMove(tree.moves[selectedChildIdx])
		tree.expand(selectedChildIdx)
		tree.game.UndoMove(tree.moves[selectedChildIdx])
	}

	parent = &tree.nodes[parentIdx]
	parent.nSims = int32(0)
	parent.value = tree.nodes[parent.firstChild].value
	decision := NoDecision
	if tree.game.Turn() == First {
		b_win := false
		w_win := true
		all_draws := true
		for i := parent.firstChild; i < parent.lastChild; i++ {
			child := tree.nodes[i]
			parent.nSims += child.nSims
			parent.value = max(parent.value, child.value)
			b_win = b_win || child.decision == FirstWin
			w_win = w_win && child.decision == SecondWin
			all_draws = all_draws && (child.decision == Draw || child.decision == SecondWin)
		}
		if b_win {
			decision = FirstWin
		} else if w_win {
			decision = SecondWin
		} else if all_draws {
			decision = Draw
		}
	} else {
		w_win := false
		b_win := true
		all_draws := true
		for i := parent.firstChild; i < parent.lastChild; i++ {
			child := tree.nodes[i]
			parent.nSims += child.nSims
			parent.value = min(parent.value, child.value)
			w_win = w_win || child.decision == SecondWin
			b_win = b_win && child.decision == FirstWin
			all_draws = all_draws && (child.decision == Draw || child.decision == FirstWin)
		}
		if w_win {
			decision = SecondWin
		} else if b_win {
			decision = FirstWin
		} else if all_draws {
			decision = Draw
		}
	}

	parent.decision = decision
}

func (tree *Tree[move]) String() string {
	buf := &bytes.Buffer{}
	tree.string(buf, 0, 0)
	return buf.String()
}

func (tree *Tree[move]) string(buf *bytes.Buffer, idx int32, depth int) {
	buf.WriteRune('\n')
	for range depth {
		buf.WriteString("|   ")
	}

	fmt.Fprint(buf, tree.moves[idx])
	fmt.Fprintf(buf, " [%d] ", idx)
	node := tree.nodes[idx]
	node.string(buf)
	for childIdx := node.firstChild; childIdx < node.lastChild; childIdx++ {
		tree.string(buf, childIdx, depth+1)
	}
}

func (node *node) String() string {
	buf := &bytes.Buffer{}
	node.string(buf)
	return buf.String()
}

func (node *node) string(buf *bytes.Buffer) {
	fmt.Fprintf(buf, "v: %d s: %d d: %v", node.value, node.nSims, node.decision)
}

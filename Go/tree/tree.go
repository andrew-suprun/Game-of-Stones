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
	nodes             []node
	moves             []move
	game              Game[move]
	topMoves          []MoveValue[move]
	maxChildren       int32
	explorationFactor float64
}

type node struct {
	firstChild int32
	lastChild  int32
	nSims      int32
	value      int16
	decision   Decision
}

func NewTree[move Equatable[move]](
	game Game[move],
	maxChildren int,
	explorationFactor float64,
) *Tree[move] {
	return &Tree[move]{
		game:              game,
		topMoves:          make([]MoveValue[move], 0, maxChildren),
		maxChildren:       int32(maxChildren),
		explorationFactor: explorationFactor,
	}
}

func (tree *Tree[m]) Expand() Decision {
	root := &tree.nodes[0]
	if root.decision == NoDecision {
		tree.expand(0)
		tree.validate()
	}
	return root.decision
}

func (tree *Tree[move]) CommitMove(toPlay move) {
	tree.game.PlayMove(toPlay)

	idx := int32(-1)
	if len(tree.nodes) > 0 {
		root := tree.nodes[0]
		for childIdx := root.firstChild; childIdx < root.lastChild; childIdx++ {
			if tree.moves[childIdx].Equal(toPlay) {
				idx = childIdx
				break
			}
		}
	}

	if idx != -1 {
		newNodes := []node{}
		newMoves := []move{}
		newNodes = append(newNodes, tree.nodes[idx])
		newMoves = append(newMoves, tree.moves[idx])
		newIdx := 0
		for newIdx < len(newNodes) {
			oldFirstChild := newNodes[newIdx].firstChild
			oldLastChild := newNodes[newIdx].lastChild
			if oldFirstChild == 0 && oldLastChild == 0 {
				newIdx++
				continue
			}
			newNodes[newIdx].firstChild = int32(len(newNodes))
			newNodes = append(newNodes, tree.nodes[oldFirstChild:oldLastChild]...)
			newMoves = append(newMoves, tree.moves[oldFirstChild:oldLastChild]...)
			newNodes[newIdx].lastChild = int32(len(newNodes))
			newIdx++
		}
		tree.nodes = newNodes
		tree.moves = newMoves

		return
	}

	tree.nodes = tree.nodes[:0]
	tree.nodes = append(tree.nodes, node{
		value:    tree.game.BoardValue(),
		decision: tree.game.Decision(),
	})
	tree.moves = tree.moves[:0]
	tree.moves = append(tree.moves, toPlay)
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
		logParentSims := math.Log(float64(parent.nSims))
		maxV := math.Inf(-1)
		for idx := parent.firstChild; idx < parent.lastChild; idx++ {
			child := tree.nodes[idx]
			if child.decision != NoDecision {
				continue
			}
			v := coeff*float64(child.value) + tree.explorationFactor*math.Sqrt(logParentSims/float64(child.nSims))
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

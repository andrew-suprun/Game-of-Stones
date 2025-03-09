//go:build gomoku

package tree

import (
	"testing"

	"game_of_stones/common"
	"game_of_stones/game"
)

func TestExpandGomoku(t *testing.T) {
	gomoku := game.NewGame()
	searchTree := NewTree(gomoku)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i11")
	searchTree.CommitMove(move)
	// fmt.Println(gomoku)

	for {
		for range 100 {
			dec, done := searchTree.Expand()
			if done || dec != common.NoDecision {
				break
			}
		}
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		dec := gomoku.Decision()
		if dec != common.NoDecision {
			break
		}
	}
}

package tree

import (
	"testing"

	. "game_of_stones/common"
	"game_of_stones/game"
)

func TestExpandGomoku(t *testing.T) {
	gomoku := game.NewGame(game.Gomoku, 8)
	searchTree := NewTree(gomoku, 8, 20)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i11")
	searchTree.CommitMove(move)
	// fmt.Println(gomoku)

	for {
		for range 100 {
			if !searchTree.Expand() {
				break
			}
		}
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		dec, _, _, _, _ := gomoku.Decision()
		if dec != NoDecision {
			break
		}
	}
}

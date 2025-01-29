package tree

import (
	"testing"

	"game_of_stones/common"
	"game_of_stones/game"
)

func TestExpandConnect6(t *testing.T) {
	connect6 := game.NewGame(game.Connect6, 28)
	searchTree := NewTree(connect6, 64, 50)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)

	for {
		for range 100 {
			dec, undec := searchTree.Expand()
			if dec != common.NoDecision || undec < 2 {
				break
			}
		}
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		dec, _, _, _, _ := connect6.Decision()
		if dec != common.NoDecision {
			break
		}
	}
}

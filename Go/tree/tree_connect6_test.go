//go:build connect6

package tree

import (
	"fmt"
	"testing"
	"time"

	"game_of_stones/common"
	"game_of_stones/game"
)

func TestExpandConnect6(t *testing.T) {
	connect6 := game.NewGame(28)
	searchTree := NewTree(connect6, 64, 50)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("k9-i9")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i8-l7")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("k8-m7")
	searchTree.CommitMove(move)

	timestamp := time.Now()
	dur := time.Second
	for range 100_000 {
		dec, undec := searchTree.Expand()
		if dec != common.NoDecision || undec < 2 || time.Since(timestamp) > dur {
			break
		}
	}
	move = searchTree.BestMove()
	searchTree.CommitMove(move)
	fmt.Printf("move %s\n", move)
}

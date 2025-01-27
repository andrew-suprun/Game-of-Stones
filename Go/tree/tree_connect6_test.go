package tree

import (
	"fmt"
	"game_of_stones/common"
	"game_of_stones/game"
	"testing"
)

func TestExpandConnect6(t *testing.T) {
	game := game.NewGame(game.Connect6, 28)
	searchTree := NewTree(game, 64, 50)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	fmt.Println("Move", move)
	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)
	fmt.Println("Move", move)
	for {
		for range 10 {
			move, _ = searchTree.Expand()
			dec, _, _, _, _ := game.Decision()
			if dec != common.NoDecision {
				fmt.Printf("\n---\n%v\n", searchTree)
				fmt.Println(game)
				return
			}
		}
		// fmt.Printf("\n---\n%v\n", searchTree)
		// fmt.Println(game)
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Println("Move", move)
	}
}

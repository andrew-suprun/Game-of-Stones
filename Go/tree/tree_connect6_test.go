package tree

import (
	"fmt"
	"game_of_stones/common"
	"game_of_stones/game"
	"testing"
)

func TestExpandConnect6(t *testing.T) {
	connect6 := game.NewGame(game.Connect6, 28)
	searchTree := NewTree(connect6, 64, 50)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	fmt.Println("Move", move)
	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)
	fmt.Println("Move", move)
	for {
		for range 10 {
			if !searchTree.Expand() {
				break
			}
		}
		dec, _, _, _, _ := searchTree.game.Decision()
		if dec != common.NoDecision {
			fmt.Printf("\n---\n%v\n", searchTree)
			fmt.Println(connect6)
			return
		}
		// fmt.Printf("\n---\n%v\n", searchTree)
		// fmt.Println(game)
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Println("Move", move)
	}
}

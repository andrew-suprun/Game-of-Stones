package tree

import (
	"fmt"
	"game_of_stones/game"
	"testing"
)

func TestExpandConnect6(t *testing.T) {
	game := game.NewGame(game.Connect6, 28)
	searchTree := NewTree(game, 64, 50)

	move, _ := game.ParseMove("j10-j10")
	searchTree.CommitMove(move)
	fmt.Println("Move", move)
	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)
	fmt.Println("Move", move)
	for {
		for range 10 {
			move, _ = searchTree.Expand()
			if move.IsTerminal() {
				fmt.Printf("\n---\n%v\n", searchTree)
				fmt.Println(game)
				return
			}
		}
		// fmt.Printf("\n---\n%v\n", searchTree)
		// fmt.Println(game)
		move, _ = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Println("Move", move)
	}
}

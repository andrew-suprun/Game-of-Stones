package tree

import (
	"fmt"
	"game_of_stones/game"
	"testing"
)

func TestExpandGomoku(t *testing.T) {
	game := game.NewGame(game.Gomoku, 8)
	searchTree := NewTree(game, 8, 20)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i11")
	searchTree.CommitMove(move)
	fmt.Printf("%#v\n", game)

	for {
		for range 10 {
			searchTree.Expand()

			fmt.Println(game)
			fmt.Printf("\n---\n%v\n", searchTree)
		}
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Println("Commit", move)
		if move.IsTerminal() {
			break
		}
	}
}

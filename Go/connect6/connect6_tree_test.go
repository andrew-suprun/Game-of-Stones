package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestExpand(t *testing.T) {
	game := NewGame(28)
	searchTree := tree.NewTree(game, 8, 50)

	move, _ := game.ParseMove("j10-j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)

	for {
		for range 10 {
			searchTree.Expand()

			fmt.Println(game)
			fmt.Printf("\n---\n%v\n", searchTree)
		}
		move, _ = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Println("Commit", move)
		if move.IsTerminal() {
			break
		}
	}
}

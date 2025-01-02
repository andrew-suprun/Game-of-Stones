package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestExpand(t *testing.T) {
	game := NewGame(28)
	searchTree := tree.NewTree(game, 64, 50)

	move, _ := game.ParseMove("j10-j10")
	searchTree.CommitMove(move)

	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)

	for {
		for range 10 {
			searchTree.Expand()
		}
		move, _ = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Printf("%#v\n%v\n", move, &game.board)
		if move.IsTerminal() {
			break
		}
	}
}

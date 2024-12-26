package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestExpand(t *testing.T) {
	game := NewGame(30)
	tree := tree.NewTree(game, 8)

	tree.CommitMove("j10-j10")
	tree.CommitMove("i9-i11")

	for range 20 {
		tree.Expand()
		fmt.Printf("\n---\n\n%#v\n%v\n", tree, &game.board)
	}
}

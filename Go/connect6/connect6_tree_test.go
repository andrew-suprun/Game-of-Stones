package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestExpand(t *testing.T) {
	game := NewGame(30)
	tree := tree.NewTree(game, 8, 100)

	tree.CommitMove("j10-j10")
	tree.CommitMove("i11-k9")
	fmt.Printf("%v\n", &game.board)

	for range 200 {
		tree.Expand()
	}
	fmt.Printf("%#v\n", tree)
}

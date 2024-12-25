package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestConnect6Grow(t *testing.T) {
	game := NewGame(30)
	tree := tree.NewTree(game, 8)

	// playMove(tree, game, "j10-j10")
	// playMove(tree, game, "i9-i11")
	// playMove(tree, game, "i10-k10")

	for range 20 {
		tree.Expand()
		fmt.Printf("\n---\n\n%#v", tree)
	}
}

package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestConnect6Grow(t *testing.T) {
	game := NewGame(30)
	tree := tree.NewTree(game, 20)

	playMove(tree, game, "j10-j10")
	playMove(tree, game, "i9-i11")
	// playMove(tree, game, "i10-k10")

	for range 10 {
		tree.Grow()
		fmt.Printf("\n---\n\n%#v", tree)
	}
}

func playMove(tree *tree.Tree[*Connect6, Move], game *Connect6, move string) {
	err := tree.CommitMove(move)
	if err != nil {
		panic("ParseMove")
	}
	fmt.Printf("%v\n", &game.board)
	tree.Grow()
	fmt.Printf("%#v", tree)
}

package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestConnect6Grow(t *testing.T) {
	game := NewGame()
	tree := tree.NewTree(game, 8)
	for range 8 {
		tree.Grow()
		fmt.Printf("%#v\n", &game.board)
		fmt.Printf("%#v\n", tree)
	}
}

package connect6

import (
	"fmt"
	"game_of_stones/tree"
	"testing"
)

func TestConnect6Grow(t *testing.T) {
	game := NewGame()
	tree := tree.NewTree(game, 8)
	err := tree.CommitMove("j10-j10")
	if err != nil {
		t.Fail()
	}
	fmt.Printf("%#v\n", &game.board)
	tree.Grow()
	fmt.Printf("%#v", tree)

	err = tree.CommitMove("i9-i11")
	if err != nil {
		t.Fail()
	}
	fmt.Printf("%#v\n", &game.board)
	tree.Grow()
	fmt.Printf("%#v", tree)

	err = tree.CommitMove("h10-i10")
	if err != nil {
		t.Fail()
	}
	fmt.Printf("%#v\n", &game.board)
	tree.Grow()
	fmt.Printf("%#v", tree)

	// for range 5 {
	// 	tree.Grow()
	// 	fmt.Printf("%v", tree)
	// }
}

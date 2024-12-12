package connect6

import (
	"game_of_stones/tree"
	"testing"
)

func TestConnect6Grow(t *testing.T) {
	tree := tree.NewTree(NewGame(), MakeRoot(), 8)
	for range 20 {
		tree.Grow()
	}
}

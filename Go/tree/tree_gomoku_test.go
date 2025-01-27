package tree

import (
	"fmt"
	"testing"

	. "game_of_stones/common"
	"game_of_stones/game"
)

func TestExpandGomoku(t *testing.T) {
	gomoku := game.NewGame(game.Gomoku, 8)
	searchTree := NewTree(gomoku, 8, 20)

	move, _ := game.ParseMove("j10")
	searchTree.CommitMove(move)
	move, _ = game.ParseMove("i11")
	searchTree.CommitMove(move)
	fmt.Printf("%#v\n", gomoku)

	for {
		for range 10 {
			searchTree.Expand()

			fmt.Println(gomoku)
			fmt.Printf("\n---\n%v\n", searchTree)
		}
		move = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Println("Commit", move)
		dec, _, _, _, _ := gomoku.Decision()
		if dec != NoDecision {
			break
		}
	}
}

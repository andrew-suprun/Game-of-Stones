package main

import (
	"fmt"
	"game_of_stones/connect6"
	"game_of_stones/tree"
)

func main() {
	game := connect6.NewGame(30)
	searchTree := tree.NewTree(game, 8, 50)

	move, _ := game.ParseMove("j10-j10")
	searchTree.CommitMove(move)

	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)

	move, _ = game.ParseMove("a1-a1")
	searchTree.CommitMove(move)

	move, _ = game.ParseMove("i10-i8")
	searchTree.CommitMove(move)

	// move, _ = game.ParseMove("a2-a2")
	// searchTree.CommitMove(move)
	fmt.Printf("---\n%v\n", game)
	fmt.Printf("%v\n", searchTree)

	for range 1 {
		for range 30 {
			move, _ := searchTree.Expand()
			if move.IsDecisive() {
				break
			}
		}
		fmt.Printf("\n%v\n", searchTree)
		move, _ = searchTree.BestMove()
		searchTree.CommitMove(move)
		if move.IsTerminal() {
			break
		}
	}
}

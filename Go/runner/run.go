package main

import (
	"fmt"
	"game_of_stones/connect6"
	"game_of_stones/tree"
)

func main() {
	game := connect6.NewGame(30)
	searchTree := tree.NewTree(game, 60, 100)

	move, _ := game.ParseMove("j10-j10")
	searchTree.CommitMove(move)

	move, _ = game.ParseMove("i11-i9")
	searchTree.CommitMove(move)

	for {
		for range 100 {
			searchTree.Expand()
		}
		move, _, _ = searchTree.BestMove()
		searchTree.CommitMove(move)
		fmt.Printf("%#v\n", move)
		if move.State() != tree.Nonterminal {
			break
		}
	}
}

package tree

import (
	"fmt"
	"g_of_stones/heap"
)

type iGame[move iMove] interface {
	MakeMove(move)
	UnmakeMove(move)
	PossibleMoves() []move
}

type iMove interface {
	comparable
	Wins() bool
	Draws() bool
	Score() int
	String() string
}

type tree[pGame iGame[pMove], pMove iMove] struct {
	gameInit  func() pGame
	capacity  int
	root      *node[pMove]
	leaves    heap.Heap[*node[pMove]]
	rootMaxer bool
	less      func(a, b *node[pMove]) bool
	depth     int
}

func newTree[pGame iGame[pMove], pMove iMove](gameInit func() pGame, capacity int, less func(a, b *node[pMove]) bool) *tree[pGame, pMove] {
	return &tree[pGame, pMove]{
		gameInit:  gameInit,
		capacity:  capacity,
		less:      less,
		root:      &node[pMove]{},
		rootMaxer: true,
		depth:     0,
	}
}

type expandResult int

const (
	winning expandResult = iota
	losing
	drawing
	inconclusive
)

func (tree *tree[pGame, pMove]) expand(node *node[pMove], game pGame) expandResult {
	if len(node.children) == 0 {
		fmt.Println("expanding leaf move", node.move)
		moves := game.PossibleMoves()
		result := drawing
		for _, move := range moves {
			if move.Wins() {
				fmt.Println("expand of leaf ", node.move, "is losing")
				return losing
			}

			node.addMove(move)

			if !move.Draws() {
				// TODO add to leaves
				result = inconclusive
			}
		}
		fmt.Println("expand of leaf ", node.move, "is", result)
		return result
	}

	fmt.Println("expanding inner move", node.move)
	result := drawing
	i := 0
	for i < len(node.children) {
		child := &node.children[i]
		if !child.draw {
			game.MakeMove(child.move)
			expandResult := tree.expand(child, game)
			game.UnmakeMove(child.move)
			switch expandResult {
			case winning:
				// TODO remove from leaves
				fmt.Println("expand of inner ", node.move, "is losing")
				return losing
			case losing:
				// TODO remove from leaves
				fmt.Println("removing", child.move)
				node.children[child.selfIdx] = node.children[len(node.children)-1]
				node.children = node.children[:len(node.children)-1]
				continue
			case inconclusive:
				result = inconclusive
			}
		}
		i++
	}
	if len(node.children) == 0 {
		fmt.Println("expand of inner ", node.move, "is winning")
		return winning
	}
	fmt.Println("expand of inner ", node.move, "is", result)
	return result
}

func (tree *tree[_, move]) RemoveChild(node *node[move]) {
	parent := node.parent
	if len(parent.children) == 1 {
		tree.Remove(parent)
	} else {
		tree.removeLeaves(node)
	}
}

func (tree *tree[_, move]) Remove(node *node[move]) {
	parent := node.parent
	if parent != nil && len(parent.children) == 1 {
		tree.RemoveChild(node)
	} else {
		tree.removeLeaves(node)
	}
}

func (tree *tree[_, move]) removeLeaves(node *node[move]) {
	if len(node.children) == 0 {
		tree.leaves.Remove(node)
	} else {
		for i := range node.children {
			tree.removeLeaves(&node.children[i])
		}
	}
}

//go:build !debug

package tree

func (tree *Tree[game, move, score]) validate() {}

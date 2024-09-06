package tree

import "core:testing"

Tree :: struct($Move: typeid) {
	root: Node,
}

expand :: proc(n: ^Node($Move), g: $Game) -> Move {
	if n.n_children == 0 {
		possible_moves := g.possible_moves()
		_ = possible_moves
	}
	return Move{}
}

TestMove :: struct {}

TestGame :: struct {
	possible_moves: proc() -> []TestMove,
}

test_g_init :: proc(g: ^TestGame) {
	g.possible_moves = proc() -> []TestMove {
		return []TestMove{}
	}
}


@(test)
test_expand :: proc(t: ^testing.T) {
	g := TestGame{}
	test_g_init(&g)
	root := Node(TestMove){}
	expand(&root, g)
}

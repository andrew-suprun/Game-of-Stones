package tree

Node :: struct($Move: typeid) {
	parent:     ^Node(Move),
	self_idx:   i32,
	children:   []Node(Move),
	n_children: i32,
	move:       Move,
}

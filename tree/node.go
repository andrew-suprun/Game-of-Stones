package tree

import "bytes"

type Node[move Move] struct {
	parent   *Node[move]
	children map[move]*Node[move]
	move     move
}

func NewNode[move Move](m move) *Node[move] {
	return &Node[move]{move: m}
}

func (node *Node[Move]) AddChild(child *Node[Move]) {
	if node.children == nil {
		node.children = map[Move]*Node[Move]{child.move: child}
	} else {
		node.children[child.move] = child
	}
	child.parent = node
}

func (node *Node[Move]) RemoveChild(move Move) {
	delete(node.children, move)
	if len(node.children) == 0 && node.parent != nil {
		node.Remove()
	}
}

func (node *Node[Move]) Remove() {
	delete(node.parent.children, node.move)
	if len(node.parent.children) == 0 && node.parent.parent != nil {
		node.parent.parent.RemoveChild(node.parent.move)
	}
}

func (node *Node[Move]) String() string {
	return string(node.Bytes())
}

func (node *Node[Move]) Bytes() []byte {
	buf := &bytes.Buffer{}
	node.bytes(buf, 0)
	return buf.Bytes()
}

func (node *Node[Move]) bytes(buf *bytes.Buffer, level int) {
	for range level {
		buf.Write([]byte("| "))
	}
	buf.WriteString(node.move.String())
	buf.WriteByte('\n')
	for _, child := range node.children {
		child.bytes(buf, level+1)
	}
}

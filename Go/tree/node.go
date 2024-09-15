package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	parent   *node[move]
	children []*node[move]
	selfIdx  uint16
	move     move
	draw     bool
}

func (self *node[pMove]) addMove(move pMove) *node[pMove] {
	child := &node[pMove]{parent: self, selfIdx: uint16(len(self.children)), move: move, draw: move.IsDraw()}
	self.children = append(self.children, child)
	return child
}

func maxLess[move iMove](a, b *node[move]) bool {
	return a.move.Score() < b.move.Score()
}

func minLess[move iMove](a, b *node[move]) bool {
	return a.move.Score() > b.move.Score()
}

func (self *node[move]) bestMove(maxer bool) (move, int16) {
	var bestMove move
	if maxer {
		var bestScore int16 = math.MinInt16
		for _, child := range self.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	} else {
		var bestScore int16 = math.MaxInt16
		for _, child := range self.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	}
}

func (self *node[_]) bestScore(maxer bool) int16 {
	if len(self.children) == 0 {
		return self.move.Score()
	}

	if maxer {
		var bestScore int16 = math.MinInt16
		for _, child := range self.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestScore = childScore
			}
		}
		return bestScore
	} else {
		var bestScore int16 = math.MaxInt16
		for _, child := range self.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestScore = childScore
			}
		}
		return bestScore
	}
}

func (self *node[_]) Print() {
	self.print(0)
}

func (self *node[_]) print(level int) {
	for range level {
		fmt.Print(" |")
	}

	fmt.Printf("%s\n", self.move.String())
	for _, child := range self.children {
		child.print(level + 1)
	}
}

func (self *node[_]) String() string {
	return self.move.String()
}

func (self *node[_]) Bytes() []byte {
	buf := &bytes.Buffer{}
	self.bytes(buf, 0)
	return buf.Bytes()
}

func (self *node[_]) bytes(buf *bytes.Buffer, level int) {
	for range level {
		buf.Write([]byte("| "))
	}
	buf.WriteString(fmt.Sprintf("%s\n", self.move.String()))
	for _, child := range self.children {
		child.bytes(buf, level+1)
	}
}

package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	parent  *node[move]
	child   *node[move]
	sibling *node[move]
	move    move
	draw    bool
	alive   bool
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
		for child := self.child; child != nil; child = child.sibling {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	} else {
		var bestScore int16 = math.MaxInt16
		for child := self.child; child != nil; child = child.sibling {
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
	if self.child == nil {
		return self.move.Score()
	}

	if maxer {
		var bestScore int16 = math.MinInt16
		for child := self.child; child != nil; child = child.sibling {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestScore = childScore
			}
		}
		return bestScore
	} else {
		var bestScore int16 = math.MaxInt16
		for child := self.child; child != nil; child = child.sibling {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestScore = childScore
			}
		}
		return bestScore
	}
}

func (self *node[_]) GoString() string {
	return string(self.Bytes())
}

func (self *node[_]) Bytes() []byte {
	buf := &bytes.Buffer{}
	self.bytes(buf, 0)
	return buf.Bytes()
}

func (self *node[_]) bytes(buf *bytes.Buffer, level int) {
	for range level {
		buf.WriteString("| ")
	}
	buf.WriteString(fmt.Sprintf("%#v\n", self.move))
	for child := self.child; child != nil; child = child.sibling {
		child.bytes(buf, level+1)
	}
}

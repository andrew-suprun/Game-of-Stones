package game

import "fmt"

type move struct {
	x1, y1, x2, y2 byte
	score          int32
}

func (m move) IsDraw() bool { return m.score == -1 }
func (m move) IsWin() bool  { return m.score == 1 }
func (m move) Score() int32 { return m.score }
func (m move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.x1+'a', boardSize-m.y1, m.x2+'a', boardSize-m.y2)
}
func (m move) GoString() string {
	return fmt.Sprintf("move{x1: %d, y1: %d, x2: %d, y2: %d, score: %d}", m.x1, m.y1, m.x2, m.y2, m.score)
}

type Connect6 struct {
	turn stone
	board
}

func (c *Connect6) MakeMove(m move) {
	if debug {
		if c.board[m.y1][m.x1] != none || c.board[m.y2][m.x2] != none {
			panic("PANIC: Invalid MakeMove")
		}
	}
	c.board[m.y1][m.x1] = c.turn
	c.board[m.y2][m.x2] = c.turn
	if c.turn == black {
		c.turn = white
	} else {
		c.turn = black
	}
}

func (c *Connect6) UnmakeMove(m move) {
	if debug {
		if c.board[m.y1][m.x1] == none || c.board[m.y2][m.x2] == none {
			panic("PANIC: Invalid UnmakeMove")
		}
	}
	c.board[m.y1][m.x1] = none
	c.board[m.y2][m.x2] = none
	if c.turn == black {
		c.turn = white
	} else {
		c.turn = black
	}
}

func (c *Connect6) PossibleMoves(limit int32) []move {
	return []move{}
}

package connect6

import (
	"fmt"
	"game_of_stones/board"
)

type move struct {
	x1, y1, x2, y2 byte
	score          int32
}

func (m move) IsDraw() bool { return m.score == -1 }
func (m move) IsWin() bool  { return m.score == 1 }
func (m move) Score() int32 { return m.score }
func (m move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.x1+'a', board.Size-m.y1, m.x2+'a', board.Size-m.y2)
}
func (m move) GoString() string {
	return fmt.Sprintf("move{x1: %d, y1: %d, x2: %d, y2: %d, score: %d}", m.x1, m.y1, m.x2, m.y2, m.score)
}

type Connect6 struct {
	turn  board.Stone
	board board.Board
}

func (c *Connect6) MakeMove(m move) {
	if debug {
		if c.board[m.y1][m.x1] != board.None || c.board[m.y2][m.x2] != board.None {
			panic("PANIC: Invalid MakeMove")
		}
	}
	c.board[m.y1][m.x1] = c.turn
	c.board[m.y2][m.x2] = c.turn
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) UnmakeMove(m move) {
	if debug {
		if c.board[m.y1][m.x1] == board.None || c.board[m.y2][m.x2] == board.None {
			panic("PANIC: Invalid UnmakeMove")
		}
	}
	c.board[m.y1][m.x1] = board.None
	c.board[m.y2][m.x2] = board.None
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) PossibleMoves(limit int32) []move {
	return []move{}
}

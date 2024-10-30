package connect6

import (
	"errors"
	"fmt"
	"game_of_stones/board"
	"math"
	"strings"
)

type Move struct {
	X1, Y1, X2, Y2 byte
	score          board.Score
}

const (
	draw board.Score = math.MinInt16
	win  board.Score = math.MaxInt16
)

func (m Move) IsDrawing() bool    { return m.score == draw }
func (m Move) IsWinning() bool    { return m.score == win }
func (m Move) Score() board.Score { return m.score }
func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.X1+'a', board.Size-m.Y1, m.X2+'a', board.Size-m.Y2)
}
func (m Move) GoString() string {
	return fmt.Sprintf("move(%d, %d, %d, %d, %d)", m.X1, m.Y1, m.X2, m.Y2, m.score)
}

type Connect6 struct {
	turn  board.Stone
	board board.Board
}

func NewGame() *Connect6 {
	return &Connect6{
		turn: board.Black,
	}
}

func (c *Connect6) ParseMove(moveStr string) ([4]byte, error) {
	tokens := strings.Split(moveStr, "-")
	tokenId := 1
	if len(tokens) == 1 {
		tokenId = 0
	}
	x1, y1, err1 := board.ParsePlace(tokens[0])
	x2, y2, err2 := board.ParsePlace(tokens[tokenId])
	if err1 != nil || err2 != nil {
		return [4]byte{}, errors.New("failed to parse move")
	}
	return [4]byte{x1, y1, x2, y2}, nil
}

func (c *Connect6) MakeMove(x1, y1, x2, y2 int) Move {
	score := c.board.Score(c.turn, x1, y1)
	c.board.PlaceStone(c.turn, x1, y1)
	score += c.board.Score(c.turn, x2, y2)
	c.board.PlaceStone(c.turn, x2, y2)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
	return move(x1, y1, x2, y2, score)
}

func move(x1, y1, x2, y2 int, score board.Score) Move {
	if x1 > x2 || x1 == x2 && y1 > y2 {
		return Move{byte(x2), byte(y2), byte(x1), byte(y1), score}
	}
	return Move{byte(x1), byte(y1), byte(x2), byte(y2), score}
}

func (c *Connect6) UndoMove(m Move) {
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
	c.board.RemoveStone(c.turn, int(m.X1), int(m.Y1))
	c.board.RemoveStone(c.turn, int(m.X2), int(m.Y2))
}

func (c *Connect6) PossibleMoves() func(limit board.Score) (Move, bool) {
	var x1, y1, x2, y2 int
	var ok bool
	score1 := c.board.Score(c.turn, 0, 0)
	c.board.PlaceStone(c.turn, x1, x2)
	return func(limit board.Score) (Move, bool) {
		for {
			x2, y2, ok = c.incPosition(x2, y2)
			if !ok {
				x1, y1, _ = c.incPosition(x1, y1)
				score1 = c.board.Score(c.turn, x1, y1)
				c.board.PlaceStone(c.turn, x1, x2)
				x2, y2, ok = c.incPosition(x1, y1)
				if !ok {
					break
				}
			}
			score := score1 + c.board.Score(c.turn, x2, y2)
			if c.turn == board.Black && score > limit || c.turn == board.White && score < limit {
				return move(x1, y1, x2, y2, score), true
			}
		}
		c.board.RemoveStone(c.turn, x1, x2)
		return Move{}, false
	}
}

func (c *Connect6) incPosition(x, y int) (int, int, bool) {
	for {
		x++
		if x >= board.Size {
			y++
			x = 0
		}
		if y >= board.Size {
			return 0, 0, false
		}
		if c.board.Stone(x, y) == board.None {
			return x, y, true
		}
	}
}

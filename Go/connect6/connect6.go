package connect6

import (
	"errors"
	"fmt"
	"game_of_stones/board"
	"math"
	"strings"
)

type move struct {
	x1, y1, x2, y2 byte
	score          int16
}

const (
	draw int16 = math.MinInt16
	win  int16 = math.MaxInt16
)

func (m move) IsDraw() bool { return m.score == draw }
func (m move) IsWin() bool  { return m.score == win }
func (m move) Score() int16 { return m.score }
func (m move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.x1+'a', board.Size-m.y1, m.x2+'a', board.Size-m.y2)
}
func (m move) GoString() string {
	return fmt.Sprintf("makeMove(%d, %d, %d, %d, %d)", m.x1, m.y1, m.x2, m.y2, m.score)
}

type Connect6 struct {
	turn  board.Stone
	board board.Board
}

func NewGame(maxPlaces int) Connect6 {
	return Connect6{
		turn: board.Black,
	}
}

func (c *Connect6) MakeMove(moveStr string) (move, error) {
	tokens := strings.Split(moveStr, "-")
	if len(tokens) != 2 {
		return move{}, errors.New("failed to parse move")
	}
	x1, y1, err1 := board.ParsePlace(tokens[0])
	x2, y2, err2 := board.ParsePlace(tokens[1])
	if err1 != nil || err2 != nil {
		return move{}, errors.New("failed to parse move")
	}

	score1 := c.board.RatePlace(x1, y1, c.turn)
	c.board.PlaceStone(x1, y1, c.turn)
	score2 := c.board.RatePlace(x2, y2, c.turn)
	c.board.RemoveStone(x1, y1)

	return makeMove(x1, y1, x2, y2, score1+score2), nil
}

func makeMove(x1, y1, x2, y2 byte, score int16) move {
	if x1 > x2 || x1 == x2 && y1 > y2 {
		return move{byte(x2), byte(y2), byte(x1), byte(y1), score}
	}
	return move{byte(x1), byte(y1), byte(x2), byte(y2), score}
}

func (c *Connect6) PlayMove(m move) {
	c.board.PlaceStone(m.x1, m.y1, c.turn)
	c.board.PlaceStone(m.x2, m.y2, c.turn)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) UndoMove(m move) {
	c.board.RemoveStone(m.x1, m.y1)
	c.board.RemoveStone(m.x2, m.y2)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) PossibleMoves() func(limit int16) (move, bool) {
	scores := c.board.CalcScores(c.turn)
	var x1, y1, x2, y2 byte
	var ok bool
	return func(limit int16) (move, bool) {
		for {
			x2, y2, ok = c.incPosition(x2, y2)
			if !ok {
				x1, y1, _ = c.incPosition(x1, y1)
				x2, y2, ok = c.incPosition(x1, y1)
				if !ok {
					break
				}
			}
			score := c.scoreMove(x1, y1, x2, y2, &scores)
			if c.turn == board.Black && score > limit || c.turn == board.White && score < limit {
				return move{x1, y1, x2, y2, score}, true
			}
		}
		return move{}, false
	}
}

func (c *Connect6) incPosition(x, y byte) (byte, byte, bool) {
	for {
		x++
		if x >= board.Size {
			y++
			x = 0
		}
		if y >= board.Size {
			return 0, 0, false
		}
		if c.board.Stone(int(x), int(y)) == board.None {
			return x, y, true
		}
	}
}

func (c *Connect6) scoreMove(x1, y1, x2, y2 byte, scores *board.Scores) int16 {
	p1Score := scores.Value(int(x1), int(y1))
	p2Score := scores.Value(int(x2), int(y2))

	if x1 == x2 || y1 == y2 || x1+y1 == x2+y2 || x1+y2 == x2+y1 {
		c.board.PlaceStone(x1, y1, c.turn)
		p2Score = c.board.RatePlace(x2, y2, c.turn)
		c.board.RemoveStone(x1, y1)
	}
	return p1Score + p2Score
}

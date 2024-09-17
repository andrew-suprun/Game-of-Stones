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
	score          int16
}

const (
	draw int16 = math.MinInt16
	win  int16 = math.MaxInt16
)

func (m Move) IsDraw() bool { return m.score == draw }
func (m Move) IsWin() bool  { return m.score == win }
func (m Move) Score() int16 { return m.score }
func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.X1+'a', board.Size-m.Y1, m.X2+'a', board.Size-m.Y2)
}
func (m Move) GoString() string {
	return fmt.Sprintf("makeMove(%d, %d, %d, %d, %d)", m.X1, m.Y1, m.X2, m.Y2, m.score)
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

func (c *Connect6) MakeMove(x1, y1, x2, y2 byte) Move {
	score1 := c.board.RatePlace(x1, y1, c.turn)
	c.board.PlaceStone(x1, y1, c.turn)
	score2 := c.board.RatePlace(x2, y2, c.turn)
	c.board.RemoveStone(x1, y1)
	return makeMove(x1, y1, x2, y2, score1+score2)
}

func makeMove(x1, y1, x2, y2 byte, score int16) Move {
	if x1 > x2 || x1 == x2 && y1 > y2 {
		return Move{byte(x2), byte(y2), byte(x1), byte(y1), score}
	}
	return Move{byte(x1), byte(y1), byte(x2), byte(y2), score}
}

func (c *Connect6) PlayMove(m Move) {
	c.board.PlaceStone(m.X1, m.Y1, c.turn)
	c.board.PlaceStone(m.X2, m.Y2, c.turn)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) UndoMove(m Move) {
	c.board.RemoveStone(m.X1, m.Y1)
	c.board.RemoveStone(m.X2, m.Y2)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) PossibleMoves() func(limit int16) (Move, bool) {
	scores := c.board.CalcScores(c.turn)
	var x1, y1, x2, y2 byte
	var ok bool
	return func(limit int16) (Move, bool) {
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
				return Move{x1, y1, x2, y2, score}, true
			}
		}
		return Move{}, false
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

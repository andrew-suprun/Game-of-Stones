package connect6

import (
	"errors"
	"fmt"
	"game_of_stones/board"
	"game_of_stones/heap"
	"strings"
)

type Move struct {
	X1, Y1, X2, Y2 byte
	score          board.Score
}

const (
	maxMoves int = 120
)

func (m Move) IsDrawing() bool    { return m.score.IsDrawing() }
func (m Move) IsWinning() bool    { return m.score.IsWinning() }
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
	score board.Score
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

func blackLess(a, b Move) bool {
	return a.score < b.score
}

func whiteLess(a, b Move) bool {
	return b.score < a.score
}

func (c *Connect6) PossibleMoves(result *[]Move) {
	less := blackLess
	if c.turn == board.White {
		less = whiteLess
	}
	heap := heap.MakeHeap[Move](result, less)
	for y1 := 0; y1 < board.Size; y1++ {
		for x1 := 0; x1 < board.Size; x1++ {
			if c.board.Stone(x1, y1) != board.None {
				continue
			}
			score1 := c.board.PlaceStone(c.turn, x1, y1)
			if score1.IsWinning() {
				c.board.RemoveStone(c.turn, x1, y1)
				(*result)[0] = move(x1, y1, x1, y1, score1)
				(*result) = (*result)[:1]
				return
			}

			for y2 := y1; y2 < board.Size; y2++ {
				x2 := 0
				if y1 == y2 {
					x2 = x1 + 1
				}
				for ; x2 < board.Size; x2++ {
					if c.board.Stone(x2, y2) != board.None {
						continue
					}
					score2 := c.board.Score(c.turn, x2, y2)
					fmt.Println("add", x1, y1, x2, y2, c.score+score1+score2, len(*result))
					heap.Add(move(x1, y1, x2, y2, c.score+score1+score2))
				}
			}
			c.board.RemoveStone(c.turn, x1, y1)
		}
	}
	heap.Sort()
}

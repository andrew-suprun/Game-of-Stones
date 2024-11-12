package connect6

import (
	"errors"
	"fmt"
	"game_of_stones/board"
	"strings"
)

type Move struct {
	x1, y1, x2, y2 byte
	score          board.Score
}

func (move *Move) IsWinning() bool {
	return move.score.IsWinning()
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.x1+'a', board.Size-m.y1, m.x2+'a', board.Size-m.y2)
}
func (m Move) GoString() string {
	return fmt.Sprintf("move(%d, %d, %d, %d)", m.x1, m.y1, m.x2, m.y2)
}

type Connect6 struct {
	turn  board.Stone
	board board.Board
	score board.Score
}

func NewGame() *Connect6 {
	game := &Connect6{
		turn:  board.White,
		board: board.MakeBoard(),
	}
	return game
}

// func (c *Connect6) Turn() tree.Player {
// 	switch c.turn {
// 	case board.Black:
// 		return tree.Second
// 	case board.White:
// 		return tree.First
// 	}
// 	panic("Illegal Turn()")
// }

func (c *Connect6) ParseMove(moveStr string) (Move, error) {
	tokens := strings.Split(moveStr, "-")
	x1, y1, err := board.ParsePlace(tokens[0])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	x2, y2 := x1, y1
	if len(tokens) > 1 {
		x2, y2, err = board.ParsePlace(tokens[1])
	}
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	return MakeMove(x1, y1, x2, y2), nil
}

func MakeMove(x1, y1, x2, y2 int) Move {
	if x1 > x2 || x1 == x2 && y1 < y2 {
		return Move{byte(x2), byte(y2), byte(x1), byte(y1), 0}
	}
	return Move{byte(x1), byte(y1), byte(x2), byte(y2), 0}
}

func makeMove(x1, y1, x2, y2 int, score board.Score) Move {
	if x1 > x2 || x1 == x2 && y1 < y2 {
		return Move{byte(x2), byte(y2), byte(x1), byte(y1), score}
	}
	return Move{byte(x1), byte(y1), byte(x2), byte(y2), score}
}

func (c *Connect6) PlayMove(move Move) {
	c.score += c.board.Score(c.turn, int(move.x1), int(move.y1))
	c.board.PlaceStone(c.turn, int(move.x1), int(move.y1))
	c.score += c.board.Score(c.turn, int(move.x2), int(move.y2))
	c.board.PlaceStone(c.turn, int(move.x2), int(move.y2))
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) UndoMove(move Move) {
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
	c.board.RemoveStone(c.turn, int(move.x2), int(move.y2))
	c.score -= c.board.Score(c.turn, int(move.x2), int(move.y2))
	c.board.RemoveStone(c.turn, int(move.x1), int(move.y1))
	c.score -= c.board.Score(c.turn, int(move.x1), int(move.y1))
}

func MaxerLess(a, b Move) bool {
	return a.score < b.score
}

func MinnerLess(a, b Move) bool {
	return b.score < a.score
}

func (c *Connect6) PossibleMoves(result *[]Move) {
	*result = (*result)[:0]
	for y1 := 0; y1 < board.Size; y1++ {
		for x1 := 0; x1 < board.Size; x1++ {
			if c.board.Stone(x1, y1) != board.None {
				continue
			}

			score1 := c.board.Score(c.turn, x1, y1)

			if score1.IsWinning() {
				(*result)[0] = makeMove(x1, y1, x1, y1, c.score+score1)
				(*result) = (*result)[:1]
				return
			}

			c.board.PlaceStone(c.turn, x1, y1)

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
					(*result) = append(*result, makeMove(x1, y1, x2, y2, c.score+score1+score2))
				}
			}

			c.board.RemoveStone(c.turn, x1, y1)
		}
	}
}

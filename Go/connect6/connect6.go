package connect6

import (
	"errors"
	"fmt"
	"strings"

	"game_of_stones/board"
	"game_of_stones/score"
)

type Move struct {
	x1, y1, x2, y2 byte
	score          score.Score
}

func (move Move) Score() score.Score {
	return move.score
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.x1+'a', board.Size-m.y1, m.x2+'a', board.Size-m.y2)
}
func (m Move) GoString() string {
	return fmt.Sprintf("Move{%d, %d, %d, %d, %#v}", m.x1, m.y1, m.x2, m.y2, m.score)
}

type Connect6 struct {
	turn  board.Stone
	board board.Board
	score score.Score
}

func NewGame() *Connect6 {
	game := &Connect6{
		turn:  board.Black,
		board: board.MakeBoard(),
	}
	return game
}

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
	return c.MakeMove(x1, y1, x2, y2), nil
}

func (c *Connect6) MakeMove(x1, y1, x2, y2 int) Move {
	if y1 > y2 || y1 == y2 && x1 > x2 {
		x1, y1, x2, y2 = x2, y2, x1, y1
	}
	score := c.board.Score(c.turn, x1, y1)
	c.board.PlaceStone(c.turn, x1, y1)
	score += c.board.Score(c.turn, x2, y2)
	c.board.RemoveStone(c.turn, x1, y1)
	return makeMove(x1, y1, x2, y2, score)
}

func makeMove(x1, y1, x2, y2 int, score score.Score) Move {
	return Move{byte(x1), byte(y1), byte(x2), byte(y2), score}
}

func (c *Connect6) PlayMove(move Move) {
	c.score += c.board.Score(c.turn, int(move.x1), int(move.y1))
	c.board.PlaceStone(c.turn, int(move.x1), int(move.y1))
	if move.x1 != move.x2 || move.y1 != move.y2 {
		c.score += c.board.Score(c.turn, int(move.x2), int(move.y2))
		c.board.PlaceStone(c.turn, int(move.x2), int(move.y2))
	}
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
	if move.x1 != move.x2 || move.y1 != move.y2 {
		c.board.RemoveStone(c.turn, int(move.x1), int(move.y1))
		c.score -= c.board.Score(c.turn, int(move.x1), int(move.y1))
	}
}

func MaxerLess(a, b Move) bool {
	return a.score < b.score
}

func MinnerLess(a, b Move) bool {
	return b.score < a.score
}

func (c *Connect6) Less(a, b Move) bool {
	return a.score < b.score
}

func (c *Connect6) PossibleMoves(moves *[]Move) {
	drawMove := Move{score: 1}
	nZeros := 0
	*moves = (*moves)[:0]

	for y1 := 0; y1 < board.Size; y1++ {
		for x1 := 0; x1 < board.Size; x1++ {
			if c.board.Stone(x1, y1) != board.None {
				continue
			}

			score1 := c.board.Score(c.turn, x1, y1)
			if score1 == 0 {
				switch nZeros {
				case 0:
					drawMove.x1 = byte(x1)
					drawMove.y1 = byte(y1)
				case 1:
					drawMove.x2 = byte(x1)
					drawMove.y2 = byte(y1)
				}
				nZeros++
				continue
			}

			if score1.State() == score.Win {
				(*moves)[0] = makeMove(x1, y1, x1, y1, c.score+score1)
				*moves = (*moves)[:1]
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
					if score2 == 0 {
						continue
					}
					if score2.State() == score.Win {
						(*moves)[0] = makeMove(x1, y1, x2, y2, c.score+score1+score2)
						*moves = (*moves)[:1]
						c.board.RemoveStone(c.turn, x1, y1)
						return
					}
					*moves = append(*moves, makeMove(x1, y1, x2, y2, c.score+score1+score2))
				}
			}
			c.board.RemoveStone(c.turn, x1, y1)
		}
	}

	if len(*moves) == 0 {
		*moves = append(*moves, drawMove)
	}
}

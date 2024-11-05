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
}

type ScoredMove struct {
	Move
	board.Score
}

const (
	maxMoves int = 120
)

func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.X1+'a', board.Size-m.Y1, m.X2+'a', board.Size-m.Y2)
}
func (m Move) GoString() string {
	return fmt.Sprintf("move(%d, %d, %d, %d)", m.X1, m.Y1, m.X2, m.Y2)
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
	game.score = game.board.Score(board.Black, board.Size/2, board.Size/2)
	game.board.PlaceStone(board.Black, board.Size/2, board.Size/2)
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

func (c *Connect6) ParseMove(moveStr string) ([4]byte, error) {
	tokens := strings.Split(moveStr, "-")
	if len(tokens) != 2 {
		return [4]byte{}, errors.New("failed to parse move")
	}
	x1, y1, err1 := board.ParsePlace(tokens[0])
	x2, y2, err2 := board.ParsePlace(tokens[1])
	if err1 != nil || err2 != nil {
		return [4]byte{}, errors.New("failed to parse move")
	}
	return [4]byte{x1, y1, x2, y2}, nil
}

func MakeMove(x1, y1, x2, y2 int) Move {
	if x1 > x2 || x1 == x2 && y1 < y2 {
		return Move{byte(x2), byte(y2), byte(x1), byte(y1)}
	}
	return Move{byte(x1), byte(y1), byte(x2), byte(y2)}
}

func (c *Connect6) PlayMove(move Move) {
	c.score += c.board.Score(c.turn, int(move.X1), int(move.Y1))
	c.board.PlaceStone(c.turn, int(move.X1), int(move.Y1))
	c.score += c.board.Score(c.turn, int(move.X2), int(move.Y2))
	c.board.PlaceStone(c.turn, int(move.X2), int(move.Y2))
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
	c.board.RemoveStone(c.turn, int(move.X2), int(move.Y2))
	c.score -= c.board.Score(c.turn, int(move.X2), int(move.Y2))
	c.board.RemoveStone(c.turn, int(move.X1), int(move.Y1))
	c.score -= c.board.Score(c.turn, int(move.X1), int(move.Y1))
}

func blackLess(a, b ScoredMove) bool {
	return a.Score < b.Score
}

func whiteLess(a, b ScoredMove) bool {
	return b.Score < a.Score
}

func (c *Connect6) PossibleMoves(result *[]ScoredMove) {
	*result = (*result)[:0]
	less := blackLess
	if c.turn == board.White {
		less = whiteLess
	}
	heap := heap.MakeHeap(result, less)
	for y1 := 0; y1 < board.Size; y1++ {
		for x1 := 0; x1 < board.Size; x1++ {
			if c.board.Stone(x1, y1) != board.None {
				continue
			}

			score1 := c.board.Score(c.turn, x1, y1)

			if score1.IsWinning() {
				(*result)[0] = ScoredMove{Move: MakeMove(x1, y1, x1, y1), Score: c.score + score1}
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
					heap.Add(ScoredMove{Move: MakeMove(x1, y1, x2, y2), Score: c.score + score1 + score2})
				}
			}

			c.board.RemoveStone(c.turn, x1, y1)
		}
	}
	// heap.Sort()
}

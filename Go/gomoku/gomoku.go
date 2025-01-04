package gomoku

import (
	"errors"
	"game_of_stones/board"
	"game_of_stones/heap"
)

type Gomoku struct {
	turn      board.Stone
	board     board.Board
	value     float32
	topPlaces []board.Place
}

func NewGame(maxPlaces int) *Gomoku {
	game := &Gomoku{
		turn:      board.Black,
		board:     board.MakeBoard(),
		topPlaces: make([]board.Place, 0, maxPlaces),
	}
	return game
}

func (c *Gomoku) ParseMove(moveStr string) (Move, error) {
	x, y, err := board.ParsePlace(moveStr)
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	value := c.board.Value(c.turn, x, y)
	return Move{x, y, value, false, value <= -board.WinValue || value >= board.WinValue}, nil
}

func (c *Gomoku) PlayMove(move Move) {
	c.value += c.board.Value(c.turn, move.X, move.Y)
	c.board.PlaceStone(c.turn, move.X, move.Y)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Gomoku) SameMove(a, b Move) bool {
	return a.X == b.X && a.Y == b.Y
}

func (c *Gomoku) SetValue(move *Move, value float32) {
	move.value = value
}

func (c *Gomoku) SetDraw(move *Move, draw bool) {
	move.draw = draw
}

func (c *Gomoku) TopMoves(moves *[]Move) {
	c.board.TopPlaces(c.turn, &c.topPlaces)
	if len(c.topPlaces) == 0 {
		*moves = (*moves)[:1]
		(*moves)[0] = Move{draw: true, terminal: true}
		return
	}
	*moves = (*moves)[:0]
	less := func(a, b Move) bool {
		return a.value < b.value
	}
	if c.turn == board.White {
		less = func(a, b Move) bool {
			return a.value > b.value
		}
	}

	c.board.TopPlaces(c.turn, &c.topPlaces)
	for i, place := range c.topPlaces {
		value := c.board.Value(c.turn, place.X, place.Y)

		if value <= -board.WinValue || value >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = Move{place.X, place.Y, c.value + value, false, true}
			return
		}

		c.board.PlaceStone(c.turn, place.X, place.Y)

		for _, place2 := range c.topPlaces[i+1:] {
			value2 := c.board.Value(c.turn, place2.X, place2.Y)
			if value2 == 0 {
				continue
			}

			if value2 <= -board.WinValue || value2 >= board.WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = Move{place.X, place.Y, c.value + value + value2, false, true}
				c.board.RemoveStone(c.turn, place.X, place.Y)
				return
			}

			c.board.PlaceStone(c.turn, place2.X, place2.Y)
			oppVal := c.oppValue()
			c.board.RemoveStone(c.turn, place2.X, place2.Y)

			move := Move{place.X, place.Y, place2.X, place2.Y, c.value + value + value2 + oppVal, false, false}
			heap.Add(move, moves, less)
		}

		c.board.RemoveStone(c.turn, place.X, place.Y)
	}
	if len(*moves) == 0 {
		*moves = append(*moves, drawMove)
	}
}

func (c *Gomoku) String() string {
	return c.board.String()
}

func (c *Gomoku) GoString() string {
	return c.board.GoString()
}

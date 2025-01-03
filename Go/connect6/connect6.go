package connect6

import (
	"errors"
	"strings"

	"game_of_stones/board"
	"game_of_stones/heap"
	"game_of_stones/turn"
)

type Connect6 struct {
	turn      board.Stone
	board     board.Board
	value     float32
	topPlaces []board.Place
}

func NewGame(maxPlaces int) *Connect6 {
	game := &Connect6{
		turn:      board.Black,
		board:     board.MakeBoard(),
		topPlaces: make([]board.Place, 0, maxPlaces),
	}
	return game
}

func (c *Connect6) Turn() turn.Turn {
	if c.turn == board.Black {
		return turn.First
	}
	return turn.Second
}

func (c *Connect6) SameMove(a, b Move) bool {
	return a.X1 == b.X1 && a.Y1 == b.Y1 && a.X2 == b.X2 && a.Y2 == b.Y2 ||
		a.X1 == b.X2 && a.Y1 == b.Y2 && a.X2 == b.X1 && a.Y2 == b.Y1
}

func (c *Connect6) SetValue(move *Move, value float32) {
	move.value = value
}

func (c *Connect6) SetDecisive(move *Move, decisive bool) {
	move.decisive = decisive
}

func (c *Connect6) ParseMove(moveStr string) (Move, error) {
	tokens := strings.Split(moveStr, "-")
	x1, y1, err := board.ParsePlace(tokens[0])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	value := c.board.Value(c.turn, x1, y1)
	if len(tokens) == 1 {
		terminal := value <= -board.WinValue || value >= board.WinValue
		return Move{x1, y1, x1, y1, value, terminal, terminal}, nil
	}
	x2, y2 := x1, y1
	x2, y2, err = board.ParsePlace(tokens[1])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	c.board.PlaceStone(c.turn, x1, y1)
	value += c.board.Value(c.turn, x2, y2)
	c.board.RemoveStone(c.turn, x1, y1)
	terminal := value <= -board.WinValue || value >= board.WinValue
	return Move{x1, y1, x2, y2, value, terminal, terminal}, nil
}

func (c *Connect6) oppValue() float32 {
	oppTurn := board.Black
	if c.turn == board.Black {
		oppTurn = board.White
	}
	if oppTurn == board.White {
		var oppVal float32 = board.WinValue
		for y := int8(0); y < board.Size; y++ {
			for x := int8(0); x < board.Size; x++ {
				if c.board.Stone(x, y) != board.None {
					continue
				}
				v := c.board.Value(oppTurn, x, y)
				if oppVal > v {
					oppVal = v
				}
			}
		}
		return oppVal
	} else {
		var oppVal float32 = -board.WinValue
		for y := int8(0); y < board.Size; y++ {
			for x := int8(0); x < board.Size; x++ {
				if c.board.Stone(x, y) != board.None {
					continue
				}
				v := c.board.Value(oppTurn, x, y)
				if oppVal < v {
					oppVal = v
				}
			}
		}
		return oppVal
	}
}

func (c *Connect6) PlayMove(move Move) {
	c.value += c.board.Value(c.turn, move.X1, move.Y1)
	c.board.PlaceStone(c.turn, move.X1, move.Y1)
	if move.X1 != move.X2 || move.Y1 != move.Y2 {
		c.value += c.board.Value(c.turn, move.X2, move.Y2)
		c.board.PlaceStone(c.turn, move.X2, move.Y2)
	}
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
	c.Validate()
}

func (c *Connect6) UndoMove(move Move) {
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
	c.board.RemoveStone(c.turn, move.X2, move.Y2)
	c.value -= c.board.Value(c.turn, move.X2, move.Y2)
	if move.X1 != move.X2 || move.Y1 != move.Y2 {
		c.board.RemoveStone(c.turn, move.X1, move.Y1)
		c.value -= c.board.Value(c.turn, move.X1, move.Y1)
	}
	c.Validate()
}

func (c *Connect6) TopMoves(moves *[]Move) {
	*moves = (*moves)[:0]
	less := func(a, b Move) bool {
		return a.value < b.value
	}
	if c.turn == board.White {
		less = func(a, b Move) bool {
			return a.value > b.value
		}
	}

	addedDraw := false
	c.board.TopPlaces(c.turn, &c.topPlaces)
	for i, place1 := range c.topPlaces {
		value1 := c.board.Value(c.turn, place1.X, place1.Y)

		if value1 <= -board.WinValue || value1 >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = Move{place1.X, place1.Y, place1.X, place1.Y, c.value + value1, true, true}
			return
		}

		c.board.PlaceStone(c.turn, place1.X, place1.Y)

		for _, place2 := range c.topPlaces[i+1:] {
			value2 := c.board.Value(c.turn, place2.X, place2.Y)

			if value2 <= -board.WinValue || value2 >= board.WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = Move{place1.X, place1.Y, place2.X, place2.Y, c.value + value1 + value2, true, true}
				c.board.RemoveStone(c.turn, place1.X, place1.Y)
				return
			}

			value := value1 + value2
			isDraw := value1+value2 == 0
			terminal := isDraw || value <= -board.WinValue || value >= board.WinValue
			if !isDraw || !addedDraw {
				c.board.PlaceStone(c.turn, place2.X, place2.Y)
				oppVal := c.oppValue()
				c.board.RemoveStone(c.turn, place2.X, place2.Y)

				move := Move{place1.X, place1.Y, place2.X, place2.Y, c.value + value + oppVal, terminal, terminal}
				heap.Add(move, moves, less)
			}
			if isDraw {
				addedDraw = true
			}
		}

		c.board.RemoveStone(c.turn, place1.X, place1.Y)
	}
}

func (c *Connect6) String() string {
	return c.board.String()
}

func (c *Connect6) GoString() string {
	return c.board.GoString()
}

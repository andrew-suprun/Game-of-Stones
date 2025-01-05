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
	value     int16
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
	return a.P1 == b.P1 && a.P2 == b.P2 || a.P1 == b.P2 && a.P2 == b.P1
}

func (c *Connect6) SetValue(move *Move, value int16) {
	move.SetValue(value)
}

func (c *Connect6) ParseMove(moveStr string) (Move, error) {
	tokens := strings.Split(moveStr, "-")
	p1, err := board.ParsePlace(tokens[0])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	value := c.board.Value(c.turn, p1)
	if len(tokens) == 1 {
		terminal := value <= -board.WinValue || value >= board.WinValue
		return MakeMove(p1.X, p1.Y, p1.X, p1.Y, value, terminal), nil
	}
	p2, err := board.ParsePlace(tokens[1])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	c.board.PlaceStone(c.turn, p1)
	value += c.board.Value(c.turn, p2)
	c.board.RemoveStone(c.turn, p1)
	terminal := value <= -board.WinValue || value >= board.WinValue
	return MakeMove(p1.X, p1.Y, p2.X, p2.Y, value, terminal), nil
}

func (c *Connect6) oppValue() int16 {
	oppTurn := board.Black
	if c.turn == board.Black {
		oppTurn = board.White
	}
	if oppTurn == board.White {
		var oppVal int16 = board.WinValue
		for y := int8(0); y < board.Size; y++ {
			for x := int8(0); x < board.Size; x++ {
				if c.board.Stone(x, y) != board.None {
					continue
				}
				v := c.board.Value(oppTurn, board.Place{X: x, Y: y})
				if oppVal > v {
					oppVal = v
				}
			}
		}
		return oppVal
	} else {
		var oppVal int16 = -board.WinValue
		for y := int8(0); y < board.Size; y++ {
			for x := int8(0); x < board.Size; x++ {
				if c.board.Stone(x, y) != board.None {
					continue
				}
				v := c.board.Value(oppTurn, board.Place{X: x, Y: y})
				if oppVal < v {
					oppVal = v
				}
			}
		}
		return oppVal
	}
}

func (c *Connect6) PlayMove(move Move) {
	c.value += c.board.Value(c.turn, move.P1)
	c.board.PlaceStone(c.turn, move.P1)
	if move.P1 != move.P2 {
		c.value += c.board.Value(c.turn, move.P2)
		c.board.PlaceStone(c.turn, move.P2)
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
	if move.P1 != move.P2 {
		c.board.RemoveStone(c.turn, move.P2)
		c.value -= c.board.Value(c.turn, move.P2)
	}
	c.board.RemoveStone(c.turn, move.P1)
	c.value -= c.board.Value(c.turn, move.P1)
	c.Validate()
}

func (c *Connect6) TopMoves(moves *[]Move) {
	*moves = (*moves)[:0]
	less := func(a, b Move) bool {
		return a.Value() < b.Value()
	}
	if c.turn == board.White {
		less = func(a, b Move) bool {
			return a.Value() > b.Value()
		}
	}

	addedDraw := false
	c.board.TopPlaces(c.turn, &c.topPlaces)
	for i, place1 := range c.topPlaces {
		value1 := c.board.Value(c.turn, place1)

		if value1 <= -board.WinValue || value1 >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MakeMove(place1.X, place1.Y, place1.X, place1.Y, c.value+value1, true)
			return
		}

		c.board.PlaceStone(c.turn, place1)

		for _, place2 := range c.topPlaces[i+1:] {
			value2 := c.board.Value(c.turn, place2)

			if value2 <= -board.WinValue || value2 >= board.WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = MakeMove(place1.X, place1.Y, place2.X, place2.Y, c.value+value1+value2, true)
				c.board.RemoveStone(c.turn, place1)
				return
			}

			value := value1 + value2
			isDraw := value1+value2 == 0
			if !isDraw || !addedDraw {
				c.board.PlaceStone(c.turn, place2)
				oppVal := c.oppValue()
				c.board.RemoveStone(c.turn, place2)

				move := MakeMove(place1.X, place1.Y, place2.X, place2.Y, c.value+value+oppVal, isDraw)
				heap.Add(move, moves, less)
			}
			if isDraw {
				addedDraw = true
			}
		}

		c.board.RemoveStone(c.turn, place1)
	}
}

func (c *Connect6) String() string {
	return c.board.String()
}

func (c *Connect6) GoString() string {
	return c.board.GoString()
}

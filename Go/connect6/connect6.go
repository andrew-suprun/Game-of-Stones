package connect6

import (
	"errors"
	"fmt"
	"strings"

	"game_of_stones/board"
	"game_of_stones/heap"
	"game_of_stones/value"
)

type Move struct {
	x1, y1, x2, y2  byte
	value, oppValue value.Value
}

func (move Move) Value() value.Value {
	return move.value
}

func (m Move) String() string {
	x1, y1, x2, y2 := m.x1, m.y1, m.x2, m.y2
	if x1 > x2 || x1 == x2 && y1 < y2 {
		x1, y1, x2, y2 = x2, y2, x1, y1
	}
	return fmt.Sprintf("%c%d-%c%d", x1+'a', board.Size-y1, x2+'a', board.Size-y2)
}
func (m Move) GoString() string {
	return fmt.Sprintf("%s %v", m, m.value)
}

type Connect6 struct {
	turn      board.Stone
	board     board.Board
	value     value.Value
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

func (c *Connect6) SameMove(a, b Move) bool {
	return a.x1 == b.x1 && a.y1 == b.y1 && a.x2 == b.x2 && a.y2 == b.y2 ||
		a.x1 == b.x2 && a.y1 == b.y2 && a.x2 == b.x1 && a.y2 == b.y1
}

func (c *Connect6) MakeMove(x1, y1, x2, y2 int) Move {
	return makeMove(x1, y1, x2, y2, 0, 0)
}

func (c *Connect6) oppValue() value.Value {
	oppTurn := board.Black
	if c.turn == board.Black {
		oppTurn = board.White
	}
	if oppTurn == board.White {
		oppVal := value.WinValue
		for y := 0; y < board.Size; y++ {
			for x := 0; x < board.Size; x++ {
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
		oppVal := -value.WinValue
		for y := 0; y < board.Size; y++ {
			for x := 0; x < board.Size; x++ {
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

func makeMove(x1, y1, x2, y2 int, value, oppValue value.Value) Move {
	return Move{byte(x1), byte(y1), byte(x2), byte(y2), value, oppValue}
}

func (c *Connect6) PlayMove(move Move) {
	c.value += c.board.Value(c.turn, int(move.x1), int(move.y1))
	c.board.PlaceStone(c.turn, int(move.x1), int(move.y1))
	if move.x1 != move.x2 || move.y1 != move.y2 {
		c.value += c.board.Value(c.turn, int(move.x2), int(move.y2))
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
	c.value -= c.board.Value(c.turn, int(move.x2), int(move.y2))
	if move.x1 != move.x2 || move.y1 != move.y2 {
		c.board.RemoveStone(c.turn, int(move.x1), int(move.y1))
		c.value -= c.board.Value(c.turn, int(move.x1), int(move.y1))
	}
}

func (c *Connect6) TopMoves(moves *[]Move) {
	*moves = (*moves)[:0]
	drawMove := Move{value: 1}
	nZeros := 0
	less := func(a, b Move) bool {
		return a.value < b.value
	}
	if c.turn == board.White {
		less = func(a, b Move) bool {
			return a.value > b.value
		}
	}

	c.board.TopPlaces(c.turn, &c.topPlaces)
	for i, place1 := range c.topPlaces {
		value1 := c.board.Value(c.turn, place1.X, place1.Y)
		if value1 == 0 {
			switch nZeros {
			case 0:
				drawMove.x1 = byte(place1.X)
				drawMove.y1 = byte(place1.Y)
			case 1:
				drawMove.x2 = byte(place1.X)
				drawMove.y2 = byte(place1.Y)
			}
			nZeros++
			continue
		}

		if value1.State() == value.Win {
			*moves = (*moves)[:1]
			(*moves)[0] = makeMove(place1.X, place1.Y, place1.X, place1.Y, c.value+value1, 0)
			return
		}

		c.board.PlaceStone(c.turn, place1.X, place1.Y)

		for _, place2 := range c.topPlaces[i+1:] {
			value2 := c.board.Value(c.turn, place2.X, place2.Y)
			if value2 == 0 {
				continue
			}
			if value2.State() == value.Win {
				(*moves)[0] = makeMove(place1.X, place1.Y, place2.X, place2.Y, c.value+value1+value2, 0)
				*moves = (*moves)[:1]
				c.board.RemoveStone(c.turn, place1.X, place1.Y)
				return
			}
			c.board.PlaceStone(c.turn, place2.X, place2.Y)
			oppVal := c.oppValue()
			c.board.RemoveStone(c.turn, place2.X, place2.Y)

			move := makeMove(place1.X, place1.Y, place2.X, place2.Y, c.value+value1+value2+oppVal, oppVal)
			heap.Add(move, moves, less)
		}

		c.board.RemoveStone(c.turn, place1.X, place1.Y)
	}
	if len(*moves) == 0 {
		*moves = append(*moves, drawMove)
	}
}

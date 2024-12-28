package connect6

import (
	"errors"
	"fmt"
	"strings"

	"game_of_stones/board"
	"game_of_stones/heap"
	"game_of_stones/tree"
)

type Move struct {
	x1, y1, x2, y2 byte
	state          tree.State
}

func (move Move) State() tree.State {
	return move.state
}

func (m Move) String() string {
	x1, y1, x2, y2 := m.x1, m.y1, m.x2, m.y2
	if x1 > x2 || x1 == x2 && y1 < y2 {
		x1, y1, x2, y2 = x2, y2, x1, y1
	}
	str := fmt.Sprintf("%c%d-%c%d", x1+'a', board.Size-y1, x2+'a', board.Size-y2)
	return fmt.Sprintf("%-7s", str)
}
func (m Move) GoString() string {
	switch m.State() {
	case tree.BlackWin:
		return m.String() + " Black Win"
	case tree.WhiteWin:
		return m.String() + " White Win"
	case tree.Draw:
		return m.String() + " Draw"
	}
	return m.String()
}

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

func (c *Connect6) Turn() tree.Turn {
	if c.turn == board.Black {
		return tree.First
	}
	return tree.Second
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
	return Move{x1, y1, x2, y2, tree.Nonterminal}, nil
}

func (c *Connect6) oppValue() float32 {
	oppTurn := board.Black
	if c.turn == board.Black {
		oppTurn = board.White
	}
	if oppTurn == board.White {
		oppVal := board.WinValue
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
		oppVal := -board.WinValue
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
	c.Validate()
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
	c.Validate()
}

func (c *Connect6) TopMoves(moves *[]tree.MoveValue[Move]) {
	*moves = (*moves)[:0]
	drawMove := tree.MoveValue[Move]{Move: Move{state: tree.Draw}}
	nZeros := 0
	less := func(a, b tree.MoveValue[Move]) bool {
		return a.Value < b.Value
	}
	if c.turn == board.White {
		less = func(a, b tree.MoveValue[Move]) bool {
			return a.Value > b.Value
		}
	}

	c.board.TopPlaces(c.turn, &c.topPlaces)
	for i, place1 := range c.topPlaces {
		value1 := c.board.Value(c.turn, place1.X, place1.Y)
		if value1 == 0 {
			switch nZeros {
			case 0:
				drawMove.Move.x1 = byte(place1.X)
				drawMove.Move.y1 = byte(place1.Y)
			case 1:
				drawMove.Move.x2 = byte(place1.X)
				drawMove.Move.y2 = byte(place1.Y)
			}
			nZeros++
			continue
		}

		if value1 >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = tree.MoveValue[Move]{
				Move:  Move{byte(place1.X), byte(place1.Y), byte(place1.X), byte(place1.Y), tree.BlackWin},
				Value: c.value + value1,
			}
			return
		} else if value1 <= -board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = tree.MoveValue[Move]{
				Move:  Move{byte(place1.X), byte(place1.Y), byte(place1.X), byte(place1.Y), tree.WhiteWin},
				Value: c.value + value1,
			}
			return
		}

		c.board.PlaceStone(c.turn, place1.X, place1.Y)

		for _, place2 := range c.topPlaces[i+1:] {
			value2 := c.board.Value(c.turn, place2.X, place2.Y)
			if value2 == 0 {
				continue
			}

			if value2 >= board.WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = tree.MoveValue[Move]{
					Move:  Move{byte(place1.X), byte(place1.Y), byte(place2.X), byte(place2.Y), tree.BlackWin},
					Value: c.value + value1 + value2,
				}
				c.board.RemoveStone(c.turn, place1.X, place1.Y)
				return
			} else if value2 <= -board.WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = tree.MoveValue[Move]{
					Move:  Move{byte(place1.X), byte(place1.Y), byte(place2.X), byte(place2.Y), tree.WhiteWin},
					Value: c.value + value1 + value2,
				}
				c.board.RemoveStone(c.turn, place1.X, place1.Y)
				return
			}

			c.board.PlaceStone(c.turn, place2.X, place2.Y)
			oppVal := c.oppValue()
			c.board.RemoveStone(c.turn, place2.X, place2.Y)

			move := tree.MoveValue[Move]{
				Move:  Move{byte(place1.X), byte(place1.Y), byte(place2.X), byte(place2.Y), tree.Nonterminal},
				Value: c.value + value1 + value2 + oppVal,
			}
			heap.Add(move, moves, less)
		}

		c.board.RemoveStone(c.turn, place1.X, place1.Y)
	}
	if len(*moves) == 0 {
		*moves = append(*moves, drawMove)
	}
}

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
	X1, Y1, X2, Y2 int8
	state          tree.State
}

func (move Move) State() tree.State {
	return move.state
}

func (m Move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.X1+'a', board.Size-m.Y1, m.X2+'a', board.Size-m.Y2)
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

func (c *Connect6) SameMove(a, b Move) bool {
	return a.X1 == b.X1 && a.Y1 == b.Y1 && a.X2 == b.X2 && a.Y2 == b.Y2 ||
		a.X1 == b.X2 && a.Y1 == b.Y2 && a.X2 == b.X1 && a.Y2 == b.Y1
}

func (c *Connect6) ParseMove(moveStr string) (Move, error) {
	tokens := strings.Split(moveStr, "-")
	x1, y1, err := board.ParsePlace(tokens[0])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	value := c.board.Value(c.turn, x1, y1)
	if value > board.WinValue {
		return Move{x1, y1, x1, y1, tree.BlackWin}, nil
	}
	if value < -board.WinValue {
		return Move{x1, y1, x1, y1, tree.WhiteWin}, nil
	}
	x2, y2 := x1, y1
	if len(tokens) > 1 {
		x2, y2, err = board.ParsePlace(tokens[1])
		if err != nil {
			return Move{}, errors.New("failed to parse move")
		}
		c.board.PlaceStone(c.turn, x1, y1)
		value = c.board.Value(c.turn, x2, y2)
		c.board.RemoveStone(c.turn, x1, y1)
	}
	if value > board.WinValue {
		return Move{x1, y1, x2, y2, tree.BlackWin}, nil
	}
	if value < -board.WinValue {
		return Move{x1, y1, x2, y2, tree.WhiteWin}, nil
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
		oppVal := -board.WinValue
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
				drawMove.Move.X1 = place1.X
				drawMove.Move.Y1 = place1.Y
			case 1:
				drawMove.Move.X2 = place1.X
				drawMove.Move.Y2 = place1.Y
			}
			nZeros++
			continue
		}

		if value1 >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = tree.MoveValue[Move]{
				Move:  Move{place1.X, place1.Y, place1.X, place1.Y, tree.BlackWin},
				Value: c.value + value1,
			}
			return
		} else if value1 <= -board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = tree.MoveValue[Move]{
				Move:  Move{place1.X, place1.Y, place1.X, place1.Y, tree.WhiteWin},
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
					Move:  Move{place1.X, place1.Y, place2.X, place2.Y, tree.BlackWin},
					Value: c.value + value1 + value2,
				}
				c.board.RemoveStone(c.turn, place1.X, place1.Y)
				return
			} else if value2 <= -board.WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = tree.MoveValue[Move]{
					Move:  Move{place1.X, place1.Y, place2.X, place2.Y, tree.WhiteWin},
					Value: c.value + value1 + value2,
				}
				c.board.RemoveStone(c.turn, place1.X, place1.Y)
				return
			}

			c.board.PlaceStone(c.turn, place2.X, place2.Y)
			oppVal := c.oppValue()
			c.board.RemoveStone(c.turn, place2.X, place2.Y)

			move := tree.MoveValue[Move]{
				Move:  Move{place1.X, place1.Y, place2.X, place2.Y, tree.Nonterminal},
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

func (c *Connect6) String() string {
	return c.board.String()
}

func (c *Connect6) GoString() string {
	return c.board.GoString()
}

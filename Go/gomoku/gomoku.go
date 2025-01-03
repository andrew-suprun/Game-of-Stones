package gomoku

import (
	"errors"
	"game_of_stones/board"
	"game_of_stones/turn"
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
	c.Validate()
}

func (c *Gomoku) UndoMove(move Move) {
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
	c.board.RemoveStone(c.turn, move.X, move.Y)
	c.value -= c.board.Value(c.turn, move.X, move.Y)
	c.Validate()
}

func (c *Gomoku) SameMove(a, b Move) bool {
	return a.X == b.X && a.Y == b.Y
}

func (c *Gomoku) SetValue(move *Move, value float32) {
	move.value = value
}

func (c *Gomoku) SetDecisive(move *Move, decisive bool) {
	move.decisive = decisive
}

func (c *Gomoku) TopMoves(moves *[]Move) {
	*moves = (*moves)[:0]
	addedDraw := false
	c.board.TopPlaces(c.turn, &c.topPlaces)
	for _, place := range c.topPlaces {
		value := c.board.Value(c.turn, place.X, place.Y)

		if value <= -board.WinValue || value >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = Move{place.X, place.Y, c.value + value, true, true}
			return
		}

		terminal := false
		if value == 0 {
			terminal = true
		}
		if !terminal || !addedDraw {
			move := Move{place.X, place.Y, c.value + value/2, terminal, terminal}
			*moves = append(*moves, move)
		}
		if value == 0 {
			addedDraw = true
		}
	}
}

func (c *Gomoku) Turn() turn.Turn {
	if c.turn == board.Black {
		return turn.First
	}
	return turn.Second
}

func (c *Gomoku) String() string {
	return c.board.String()
}

func (c *Gomoku) GoString() string {
	return c.board.GoString()
}

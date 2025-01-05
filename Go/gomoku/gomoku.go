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
	place, err := board.ParsePlace(moveStr)
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}
	value := c.board.Value(c.turn, place)
	terminal := value <= -board.WinValue || value >= board.WinValue
	return MakeMove(place.X, place.Y, value, terminal), nil
}

func (c *Gomoku) PlayMove(move Move) {
	c.value += c.board.Value(c.turn, move.Place)
	c.board.PlaceStone(c.turn, move.Place)
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
	c.board.RemoveStone(c.turn, move.Place)
	c.value -= c.board.Value(c.turn, move.Place)
	c.Validate()
}

func (c *Gomoku) SameMove(a, b Move) bool {
	return a == b
}

func (c *Gomoku) SetValue(move *Move, value float32) {
	move.SetValue(value)
}

func (c *Gomoku) TopMoves(moves *[]Move) {
	*moves = (*moves)[:0]
	addedDraw := false
	c.board.TopPlaces(c.turn, &c.topPlaces)
	for _, place := range c.topPlaces {
		value := c.board.Value(c.turn, place)

		if value <= -board.WinValue || value >= board.WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MakeMove(place.X, place.Y, c.value+value, true)
			return
		}

		terminal := false
		if value == 0 {
			terminal = true
		}
		if !terminal || !addedDraw {
			move := MakeMove(place.X, place.Y, c.value+value/2, terminal)
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

package game

import (
	"errors"
	"strings"

	. "game_of_stones/common"
	"game_of_stones/heap"
)

const Size = 19

type Place struct {
	X, Y int8
}

type Move struct {
	P1, P2 Place
}

func (m Move) Equal(other Move) bool {
	return m == other || m.P1 == other.P2 && m.P2 == other.P1
}

type Stone int8

const (
	None  Stone = 0
	Black Stone = 1
	White Stone = 8
)

type Game struct {
	stone  Stone
	turn   Turn
	stones [Size][Size]Stone
	values [Size][Size][2]int16
	value  int16
	places []Place
}

func NewGame(maxPlaces int) *Game {
	game := &Game{
		stone:  Black,
		places: make([]Place, 0, maxPlaces),
	}
	game.initValues()
	return game
}

func (game *Game) Turn() Turn {
	return game.turn
}

func (game *Game) PlayMove(move Move) {
	game.placeStone(move.P1, 1)

	if move.P1 != move.P2 {
		game.placeStone(move.P2, 1)
	}

	if game.stone == Black {
		game.stone = White
		game.turn = Second
	} else {
		game.stone = Black
		game.turn = First
	}
}

func (game *Game) UndoMove(move Move) {
	if game.stone == Black {
		game.stone = White
		game.turn = Second
	} else {
		game.stone = Black
		game.turn = First
	}

	if move.P1 != move.P2 {
		game.placeStone(move.P2, -1)
	}

	game.placeStone(move.P1, -1)
}

func ParseMove(moveStr string) (Move, error) {
	tokens := strings.Split(moveStr, "-")
	p1, err := ParsePlace(tokens[0])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}

	if len(tokens) == 1 {
		return Move{P1: p1, P2: p1}, nil
	}
	p2, err := ParsePlace(tokens[1])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}

	return Move{P1: p1, P2: p2}, nil
}

func ParsePlace(place string) (Place, error) {
	if len(place) < 2 || len(place) > 3 {
		return Place{}, errors.New("failed to parse place")
	}
	if place[0] < 'a' || place[0] > 's' {
		return Place{}, errors.New("failed to parse place")
	}
	if place[1] < '0' || place[1] > '9' {
		return Place{}, errors.New("failed to parse place")
	}
	x := int8(place[0] - 'a')
	y := int8(place[1] - '0')
	if len(place) == 3 {
		if place[2] < '0' || place[2] > '9' {
			return Place{}, errors.New("failed to parse place")
		}
		y = 10*y + int8(place[2]-'0')
	}
	y -= 1
	if x > Size || y > Size {
		return Place{}, errors.New("failed to parse place")
	}
	return Place{X: x, Y: y}, nil
}

func (game *Game) initValues() {
	for y := 0; y < Size; y++ {
		v := 1 + min(maxStones1, y, Size-1-y)
		for x := 0; x < Size; x++ {
			h := 1 + min(maxStones1, x, Size-1-x)
			m := 1 + min(x, y, Size-1-x, Size-1-y)
			t1 := max(0, min(maxStones, m, Size-maxStones1-y+x, Size-maxStones1-x+y))
			t2 := max(0, min(maxStones, m, 2*Size-1-maxStones1-y-x, x+y-maxStones1+1))
			total := int16(v + h + t1 + t2)
			game.values[y][x] = [2]int16{total, -total}
		}
	}
}

func (game *Game) placeStone(place Place, coeff int16) {
	x, y := place.X, place.Y
	if coeff == 1 {
		game.value += game.values[y][x][game.turn]
	} else {
		game.stones[y][x] = None
	}

	{
		start := max(0, x-maxStones1)
		end := min(x+maxStones, Size) - maxStones1
		n := end - start
		game.updateRow(start, y, 1, 0, n, coeff)
	}

	{
		start := max(0, y-maxStones1)
		end := min(y+maxStones, Size) - maxStones1
		n := end - start
		game.updateRow(x, start, 0, 1, n, coeff)
	}

	m := 1 + min(x, y, Size-1-x, Size-1-y)

	{
		n := min(maxStones, m, Size-maxStones1-y+x, Size-maxStones1-x+y)
		if n > 0 {
			mn := min(x, y, maxStones1)
			xStart := x - mn
			yStart := y - mn
			game.updateRow(xStart, yStart, 1, 1, n, coeff)
		}
	}

	{
		n := min(maxStones, m, 2*Size-1-maxStones1-y-x, x+y-maxStones1+1)
		if n > 0 {
			mn := min(Size-1-x, y, maxStones1)
			xStart := x + mn
			yStart := y - mn
			game.updateRow(xStart, yStart, -1, 1, n, coeff)
		}
	}

	if coeff == 1 {
		game.stones[y][x] = game.stone
	} else {
		game.value -= game.values[y][x][game.turn]
	}
	game.validate()
}

func (game *Game) updateRow(x, y, dx, dy, n int8, coeff int16) {
	stones := Stone(0)
	for i := int8(0); i < maxStones1; i++ {
		stones += game.stones[y+i*dy][x+i*dx]
	}
	for range n {
		stones += game.stones[y+maxStones1*dy][x+maxStones1*dx]
		values := gameValues[game.turn][stones]
		blackValue, whiteValue := values[0]*coeff, values[1]*coeff
		if blackValue != 0 || whiteValue != 0 {
			for j := int8(0); j < maxStones; j++ {
				s := &game.values[y+j*dy][x+j*dx]
				s[0] += blackValue
				s[1] += whiteValue
			}
		}
		stones -= game.stones[y][x]
		x += dx
		y += dy
	}
}

func (game *Game) topPlaces() {
	less := func(a, b Place) bool {
		return game.values[a.Y][a.X][0] < game.values[b.Y][b.X][0]
	}
	if game.stone == White {
		less = func(a, b Place) bool {
			return game.values[a.Y][a.X][1] > game.values[b.Y][b.X][1]
		}
	}
	game.places = game.places[:0]
	for y := int8(0); y < Size; y++ {
		for x := int8(0); x < Size; x++ {
			if game.stones[y][x] == None {
				heap.Add(Place{X: x, Y: y}, &game.places, less)
			}
		}
	}
}

func (game *Game) Decision() Decision {
	blackStones := Stone(maxStones)
	whiteStones := Stone(maxStones * White)

	for y := int8(0); y < Size; y++ {
		stones := Stone(0)
		for x := int8(0); x < maxStones1; x++ {
			stones += game.stones[y][x]
		}
		for x := int8(0); x < Size-maxStones1; x++ {
			stones += game.stones[y][x+maxStones1]
			if stones == blackStones {
				return FirstWin
			} else if stones == whiteStones {
				return SecondWin
			}
			stones -= game.stones[y][x]
		}
	}

	for x := int8(0); x < Size; x++ {
		stones := Stone(0)
		for y := int8(0); y < maxStones1; y++ {
			stones += game.stones[y][x]
		}
		for y := int8(0); y < Size-maxStones1; y++ {
			stones += game.stones[y+maxStones1][x]
			if stones == blackStones {
				return FirstWin
			} else if stones == whiteStones {
				return SecondWin
			}
			stones -= game.stones[y][x]
		}
	}

	for y := int8(0); y < Size-maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < maxStones1; x++ {
			stones += game.stones[y+x][x]
		}
		for x := int8(0); x < Size-maxStones1-y; x++ {
			stones += game.stones[x+y+maxStones1][x+maxStones1]
			if stones == blackStones {
				return FirstWin
			} else if stones == whiteStones {
				return SecondWin
			}
			stones -= game.stones[x+y][x]
		}
	}

	for x := int8(1); x < Size-maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < maxStones1; y++ {
			stones += game.stones[y][x+y]
		}
		for y := int8(0); y < Size-maxStones1-x; y++ {
			stones += game.stones[y+maxStones1][x+y+maxStones1]
			if stones == blackStones {
				return FirstWin
			} else if stones == whiteStones {
				return SecondWin
			}
			stones -= game.stones[y][x+y]
		}
	}

	for y := int8(0); y < Size-maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < maxStones1; x++ {
			stones += game.stones[x+y][Size-1-x]
		}
		for x := int8(0); x < Size-maxStones1-y; x++ {
			stones += game.stones[x+y+maxStones1][Size-1-x-maxStones1]
			if stones == blackStones {
				return FirstWin
			} else if stones == whiteStones {
				return SecondWin
			}
			stones -= game.stones[x+y][Size-1-x]
		}
	}

	for x := int8(1); x < Size-maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < maxStones1; y++ {
			stones += game.stones[y][Size-1-x-y]
		}
		for y := int8(0); y < Size-maxStones1-x; y++ {
			stones += game.stones[y+maxStones1][Size-1-maxStones1-x-y]
			if stones == blackStones {
				return FirstWin
			} else if stones == whiteStones {
				return SecondWin
			}
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	for y := range Size {
		for x := range Size {
			if game.values[y][x][0] != 0 {
				return NoDecision
			}
		}
	}

	return Draw
}

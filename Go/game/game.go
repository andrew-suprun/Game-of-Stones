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

type GameName int

const (
	Gomoku GameName = iota
	Connect6
)

type Game struct {
	name       GameName
	stone      Stone
	turn       Turn
	stones     [Size][Size]Stone
	values     [Size][Size][2]int16
	value      int16
	places     []Place
	maxStones  int8
	maxStones1 int8
}

func NewGame(name GameName, maxPlaces int) *Game {
	game := &Game{
		name:   name,
		stone:  Black,
		places: make([]Place, 0, maxPlaces),
	}
	game.initValues()
	return game
}

func (game *Game) Turn() Turn {
	return game.turn
}

func (game *Game) TopMoves(moves *[]MoveValue[Move]) {
	*moves = (*moves)[:0]
	if game.name == Gomoku {
		game.topGomokuMoves(moves)
	} else {
		game.topConnect6Moves(moves)
	}
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
	game.validate()
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

	game.validate()
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
	game.maxStones = 5
	if game.name == Connect6 {
		game.maxStones = 6
	}
	game.maxStones1 = game.maxStones - 1
	maxStones, maxStones1 := int(game.maxStones), int(game.maxStones1)
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
	maxStones := int8(5)
	if game.name == Connect6 {
		maxStones = 6
	}
	maxStones1 := maxStones - 1
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
	for i := int8(0); i < game.maxStones1; i++ {
		stones += game.stones[y+i*dy][x+i*dx]
	}
	for range n {
		stones += game.stones[y+game.maxStones1*dy][x+game.maxStones1*dx]
		// values := game.valueStones(stones)
		values := gameValues[game.turn][stones]
		blackValue, whiteValue := values[0]*coeff, values[1]*coeff
		if blackValue != 0 || whiteValue != 0 {
			for j := int8(0); j < game.maxStones; j++ {
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

func (game *Game) topGomokuMoves(moves *[]MoveValue[Move]) {
	game.topPlaces()
	hasDraw := false
	for _, place := range game.places {
		value := game.values[place.Y][place.X][game.turn]
		if value >= WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{P1: place, P2: place},
				Value:    WinValue,
				Decision: BlackWin}
			return
		} else if value <= -WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{place, place},
				Value:    -WinValue,
				Decision: WhiteWin}
			return
		}

		if value != 0 {
			*moves = append(*moves, MoveValue[Move]{
				Move:     Move{place, place},
				Value:    value,
				Decision: NoDecision,
			})
		} else if !hasDraw {
			*moves = append(*moves, MoveValue[Move]{
				Move:     Move{place, place},
				Value:    0,
				Decision: Draw,
			})
			hasDraw = true
		}
	}
}

func (game *Game) topConnect6Moves(moves *[]MoveValue[Move]) {
	less := func(a, b MoveValue[Move]) bool {
		return a.Value < b.Value
	}
	if game.stone == White {
		less = func(a, b MoveValue[Move]) bool {
			return a.Value > b.Value
		}
	}

	game.topPlaces()

	if len(game.places) < 2 {
		*moves = append(*moves, MoveValue[Move]{
			Move:     Move{Place{0, 0}, Place{0, 0}},
			Value:    0,
			Decision: Draw,
		})
		return
	}
	gameValue := game.value
	hasDraw := false

	for i, place1 := range game.places {
		value1 := game.values[place1.Y][place1.X][game.turn]

		if value1 >= WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{P1: place1, P2: place1},
				Value:    WinValue,
				Decision: BlackWin}
			return
		} else if value1 < -WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = MoveValue[Move]{
				Move:     Move{P1: place1, P2: place1},
				Value:    -WinValue,
				Decision: WhiteWin}
			return
		}

		game.placeStone(place1, 1)

		for _, place2 := range game.places[i+1:] {
			value2 := game.values[place2.Y][place2.X][game.turn]

			if value2 >= WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = MoveValue[Move]{
					Move:     Move{P1: place1, P2: place2},
					Value:    WinValue,
					Decision: BlackWin}
				game.placeStone(place1, -1)
				return
			} else if value2 < -WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = MoveValue[Move]{
					Move:     Move{P1: place1, P2: place2},
					Value:    -WinValue,
					Decision: WhiteWin}
				game.placeStone(place1, -1)
				return
			}

			value := value1 + value2

			if value == 0 {
				if !hasDraw {
					*moves = append(*moves, MoveValue[Move]{
						Move:     Move{place1, place2},
						Value:    0,
						Decision: Draw,
					})
					hasDraw = true
				}
			} else {
				value = gameValue + value/2 //TODO: Check alternative scoring below:

				// game.placeStone(place2, 1)
				// oppVal := game.oppValue()
				// game.placeStone(place2, -1)
				// value = gameValue + value + oppVal

				move := MoveValue[Move]{
					Move:     Move{place1, place2},
					Value:    value,
					Decision: NoDecision,
				}
				heap.Add(move, moves, less)
			}
		}

		game.placeStone(place1, -1)
	}
}

func (game *Game) oppValue() int16 {
	oppTurn := First
	if game.stone == Black {
		oppTurn = Second
	}
	if oppTurn == Second {
		var oppVal int16 = WinValue
		for y := int8(0); y < Size; y++ {
			for x := int8(0); x < Size; x++ {
				if game.stones[y][x] != None {
					continue
				}
				v := game.values[y][x][1]
				oppVal = min(oppVal, v)
			}
		}
		return oppVal
	} else {
		var oppVal int16 = -WinValue
		for y := int8(0); y < Size; y++ {
			for x := int8(0); x < Size; x++ {
				if game.stones[y][x] != None {
					continue
				}
				v := game.values[y][x][0]
				oppVal = max(oppVal, v)
			}
		}
		return oppVal
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
			if game.stones[y][x] != None {
				continue
			}
			heap.Add(Place{X: x, Y: y}, &game.places, less)
		}
	}
}

func (game *Game) Decision() (Decision, int8, int8, int8, int8) {
	blackStones := Stone(5)
	whiteStones := Stone(5 * White)
	if game.name == Connect6 {
		blackStones = Stone(6)
		whiteStones = Stone(6 * White)
	}

	for y := int8(0); y < Size; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y][x]
		}
		for x := int8(0); x < Size-game.maxStones1; x++ {
			stones += game.stones[y][x+game.maxStones1]
			if stones == blackStones {
				return BlackWin, x, y, 1, 0
			} else if stones == whiteStones {
				return WhiteWin, x, y, 1, 0
			}
			stones -= game.stones[y][x]
		}
	}

	for x := int8(0); x < Size; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x]
		}
		for y := int8(0); y < Size-game.maxStones1; y++ {
			stones += game.stones[y+game.maxStones1][x]
			if stones == blackStones {
				return BlackWin, x, y, 1, 0
			} else if stones == whiteStones {
				return WhiteWin, x, y, 1, 0
			}
			stones -= game.stones[y][x]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[y+x][x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][x+game.maxStones1]
			if stones == blackStones {
				return BlackWin, x, x + y, 1, 0
			} else if stones == whiteStones {
				return WhiteWin, x, x + y, 1, 0
			}
			stones -= game.stones[x+y][x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][x+y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][x+y+game.maxStones1]
			if stones == blackStones {
				return BlackWin, x, x + y, 1, 0
			} else if stones == whiteStones {
				return WhiteWin, x, x + y, 1, 0
			}
			stones -= game.stones[y][x+y]
		}
	}

	for y := int8(0); y < Size-game.maxStones1; y++ {
		stones := Stone(0)
		for x := int8(0); x < game.maxStones1; x++ {
			stones += game.stones[x+y][Size-1-x]
		}
		for x := int8(0); x < Size-game.maxStones1-y; x++ {
			stones += game.stones[x+y+game.maxStones1][Size-1-x-game.maxStones1]
			if stones == blackStones {
				return BlackWin, Size - 1 - x, x + y, 1, 0
			} else if stones == whiteStones {
				return WhiteWin, Size - 1 - x, x + y, 1, 0
			}
			stones -= game.stones[x+y][Size-1-x]
		}
	}

	for x := int8(1); x < Size-game.maxStones1; x++ {
		stones := Stone(0)
		for y := int8(0); y < game.maxStones1; y++ {
			stones += game.stones[y][Size-1-x-y]
		}
		for y := int8(0); y < Size-game.maxStones1-x; y++ {
			stones += game.stones[y+game.maxStones1][Size-1-game.maxStones1-x-y]
			if stones == blackStones {
				return BlackWin, Size - 1 - x - y, y, 1, 0
			} else if stones == whiteStones {
				return WhiteWin, Size - 1 - x - y, y, 1, 0
			}
			stones -= game.stones[y][Size-1-x-y]
		}
	}

	return NoDecision, 0, 0, 0, 0
}

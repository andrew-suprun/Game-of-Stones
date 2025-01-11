package game

import (
	"errors"
	"strings"

	"game_of_stones/heap"
	"game_of_stones/turn"
)

const Size = 19

type Place struct {
	X, Y int8
}

type Move struct {
	P1, P2   Place
	value    int16
	terminal bool
}

type Stone int8

const (
	None  Stone = 0x00
	Black Stone = 0x01
	White Stone = 0x10
)

type GameName int

const (
	Gomoku GameName = iota
	Connect6
)

type Game struct {
	name       GameName
	stone      Stone
	turn       turn.Turn
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

func (game *Game) Turn() turn.Turn {
	return game.turn
}

func (game *Game) TopMoves(moves *[]Move) {
	*moves = (*moves)[:0]
	if game.name == Gomoku {
		game.topGomokuMoves(moves)
	} else {
		game.topConnect6Moves(moves)
	}
}

func (game *Game) PlayMove(move Move) {
	game.value += game.values[move.P1.Y][move.P1.X][game.turn]
	game.placeStone(move.P1, 1)

	if move.P1 != move.P2 {
		game.value += game.values[move.P2.Y][move.P2.X][game.turn]
		game.placeStone(move.P2, 1)
	}

	if game.stone == Black {
		game.stone = White
		game.turn = turn.Second
	} else {
		game.stone = Black
		game.turn = turn.First
	}
	game.validate()
}

func (game *Game) UndoMove(move Move) {
	if game.stone == Black {
		game.stone = White
		game.turn = turn.Second
	} else {
		game.stone = Black
		game.turn = turn.First
	}

	game.placeStone(move.P1, -1)
	game.value -= game.values[move.P1.Y][move.P1.X][game.turn]

	if move.P1 != move.P2 {
		game.placeStone(move.P2, -1)
		game.value -= game.values[move.P2.Y][move.P2.X][game.turn]
	}
	game.validate()
}

func (game *Game) SameMove(a, b Move) bool {
	return a.P1 == b.P1 && a.P2 == b.P2 || a.P1 == b.P2 && a.P2 == b.P1
}

func (c *Game) SetValue(move *Move, value int16) {
	move.value = value
}

func (game *Game) ParseMove(moveStr string) (Move, error) {
	tokens := strings.Split(moveStr, "-")
	p1, err := ParsePlace(tokens[0])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}

	value := game.values[p1.Y][p1.X][game.turn]

	if len(tokens) == 1 {
		game.value += value
		terminal := value <= -WinValue || value >= WinValue
		return Move{P1: p1, P2: p1, value: value, terminal: terminal}, nil
	}
	p2, err := ParsePlace(tokens[1])
	if err != nil {
		return Move{}, errors.New("failed to parse move")
	}

	game.placeStone(p1, 1)

	value += game.values[p2.Y][p2.X][game.turn]

	game.placeStone(p1, -1)

	game.value += value
	terminal := value <= -WinValue || value >= WinValue
	return Move{P1: p1, P2: p2, value: value, terminal: terminal}, nil
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
	y = Size - y
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
	if coeff == -1 {
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
		values := game.valueStones(stones)
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

func (game *Game) topGomokuMoves(moves *[]Move) {
	addedDraw := false
	game.topPlaces()
	for _, place := range game.places {
		value := game.values[place.Y][place.X][game.turn]

		if value <= -WinValue || value >= WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = Move{P1: place, P2: place, value: game.value + value, terminal: true}
			return
		}

		terminal := false
		if value == 0 {
			terminal = true
		} else {
			value = game.value + value/2
		}
		if !terminal || !addedDraw {
			move := Move{P1: place, P2: place, value: value, terminal: terminal}
			*moves = append(*moves, move)
		}
		if value == 0 {
			addedDraw = true
		}
	}
}

func (game *Game) topConnect6Moves(moves *[]Move) {
	less := func(a, b Move) bool {
		return a.value < b.value
	}
	if game.stone == White {
		less = func(a, b Move) bool {
			return a.value > b.value
		}
	}

	addedDraw := false
	game.topPlaces()
	for i, place1 := range game.places {
		value1 := game.values[place1.Y][place1.X][game.turn]

		if value1 <= -WinValue || value1 >= WinValue {
			*moves = (*moves)[:1]
			(*moves)[0] = Move{P1: place1, P2: place1, value: game.value + value1, terminal: true}
			return
		}

		game.placeStone(place1, 1)

		for _, place2 := range game.places[i+1:] {
			value2 := game.values[place2.Y][place2.X][game.turn]

			if value2 <= -WinValue || value2 >= WinValue {
				*moves = (*moves)[:1]
				(*moves)[0] = Move{P1: place1, P2: place2, value: game.value + value1 + value2, terminal: true}
				game.placeStone(place1, -1)
				return
			}

			value := value1 + value2
			isDraw := value1+value2 == 0
			if !isDraw || !addedDraw {
				game.placeStone(place2, 1)
				oppVal := game.oppValue()
				game.placeStone(place2, -1)

				move := Move{P1: place1, P2: place2, value: game.value + value + oppVal, terminal: isDraw}
				heap.Add(move, moves, less)
			}
			if isDraw {
				addedDraw = true
			}
		}

		game.placeStone(place1, -1)
	}
}

func (game *Game) oppValue() int16 {
	oppTurn := turn.First
	if game.stone == Black {
		oppTurn = turn.Second
	}
	if oppTurn == turn.Second {
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

func (m Move) Value() int16 {
	return m.value
}

func (m Move) IsDecisive() bool {
	return m.terminal || m.value <= -WinValue || m.value >= WinValue
}

func (m Move) IsTerminal() bool {
	return m.terminal
}

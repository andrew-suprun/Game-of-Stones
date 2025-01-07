package board

import (
	"bytes"
	"errors"
	"fmt"

	"game_of_stones/heap"
)

const Size = 19

type Stone int8

const (
	None  Stone = 0
	Black Stone = 1
	White Stone = 0x10
)

func (stone Stone) String() string {
	switch stone {
	case Black:
		return "Black"
	case White:
		return "White"
	}
	return "None"
}

type Place struct {
	X, Y int8
}

const maxStones1 = maxStones - 1

type Board struct {
	stones [Size][Size]Stone
	values [Size][Size][2]int16
}

func MakeBoard() Board {
	board := Board{}
	for y := 0; y < Size; y++ {
		v := 1 + min(maxStones1, y, Size-1-y)
		for x := 0; x < Size; x++ {
			h := 1 + min(maxStones1, x, Size-1-x)
			m := 1 + min(x, y, Size-1-x, Size-1-y)
			t1 := max(0, min(maxStones, m, Size-maxStones1-y+x, Size-maxStones1-x+y))
			t2 := max(0, min(maxStones, m, 2*Size-1-maxStones1-y-x, x+y-maxStones1+1))
			total := int16(v + h + t1 + t2)
			board.values[y][x] = [2]int16{total, -total}
		}
	}
	return board
}

func (board *Board) TopPlaces(stone Stone, places *[]Place) {
	player := 0
	less := func(a, b Place) bool {
		return board.values[a.Y][a.X][player] < board.values[b.Y][b.X][player]
	}
	if stone == White {
		player = 1
		less = func(a, b Place) bool {
			return board.values[a.Y][a.X][player] > board.values[b.Y][b.X][player]
		}
	}
	*places = (*places)[:0]
	for y := int8(0); y < Size; y++ {
		for x := int8(0); x < Size; x++ {
			if board.stones[y][x] != None {
				continue
			}
			heap.Add(Place{x, y}, places, less)
		}
	}
}

func (b *Board) PlaceStone(stone Stone, place Place) {
	b.placeStone(stone, place, 1)
}

func (b *Board) RemoveStone(stone Stone, place Place) {
	b.placeStone(stone, place, -1)
}

func (b *Board) Stone(x, y int8) Stone {
	return b.stones[y][x]
}

func (b *Board) Value(stone Stone, place Place) int16 {
	switch stone {
	case Black:
		return b.values[place.Y][place.X][0]
	case White:
		return b.values[place.Y][place.X][1]
	}
	panic("Value")
}

func (b *Board) placeStone(stone Stone, place Place, coeff int16) {
	x, y := place.X, place.Y
	if coeff == -1 {
		b.stones[y][x] = None
	}

	{
		start := max(0, x-maxStones1)
		end := min(x+maxStones, Size) - maxStones1
		n := end - start
		b.updateRow(stone, start, y, 1, 0, n, coeff)
	}

	{
		start := max(0, y-maxStones1)
		end := min(y+maxStones, Size) - maxStones1
		n := end - start
		b.updateRow(stone, x, start, 0, 1, n, coeff)
	}

	m := 1 + min(x, y, Size-1-x, Size-1-y)

	{
		n := min(maxStones, m, Size-maxStones1-y+x, Size-maxStones1-x+y)
		if n > 0 {
			mn := min(x, y, maxStones1)
			xStart := x - mn
			yStart := y - mn
			b.updateRow(stone, xStart, yStart, 1, 1, n, coeff)
		}
	}

	{
		n := min(maxStones, m, 2*Size-1-maxStones1-y-x, x+y-maxStones1+1)
		if n > 0 {
			mn := min(Size-1-x, y, maxStones1)
			xStart := x + mn
			yStart := y - mn
			b.updateRow(stone, xStart, yStart, -1, 1, n, coeff)
		}
	}

	if coeff == 1 {
		b.stones[y][x] = stone
	}
	b.Validate()
}

func (b *Board) updateRow(stone Stone, x, y, dx, dy, n int8, coeff int16) {
	stones := Stone(0)
	for i := int8(0); i < maxStones1; i++ {
		stones += b.stones[y+i*dy][x+i*dx]
	}
	for range n {
		stones += b.stones[y+maxStones1*dy][x+maxStones1*dx]
		blackValue, whiteValue := valueStones(stone, stones)
		if blackValue != 0 || whiteValue != 0 {
			blackValue, whiteValue = blackValue*coeff, whiteValue*coeff
			for j := int8(0); j < maxStones; j++ {
				s := &b.values[y+j*dy][x+j*dx]
				s[0] += blackValue
				s[1] += whiteValue
			}
		}
		stones -= b.stones[y][x]
		x += dx
		y += dy
	}
}

func (b *Board) String() string {
	buf := &bytes.Buffer{}
	b.BoardString(buf)
	return buf.String()
}

func (b *Board) GoString() string {
	buf := &bytes.Buffer{}
	b.BoardString(buf)
	b.ValuesString(buf, 0)
	b.ValuesString(buf, 1)
	return buf.String()
}

func (b *Board) BoardString(buf *bytes.Buffer) {
	buf.WriteString("\n  ")

	for i := range Size {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')

	for y := range Size {
		fmt.Fprintf(buf, "%2d", Size-y)
		for x := range Size {
			switch b.stones[y][x] {
			case Black:
				if x == 0 {
					buf.WriteString(" X")
				} else {
					buf.WriteString("─X")
				}
			case White:
				if x == 0 {
					buf.WriteString(" O")
				} else {
					buf.WriteString("─O")
				}
			default:
				switch y {
				case 0:
					switch x {
					case 0:
						buf.WriteString(" ┌")
					case Size - 1:
						buf.WriteString("─┐")
					default:
						buf.WriteString("─┬")
					}
				case Size - 1:
					switch x {
					case 0:
						buf.WriteString(" └")
					case Size - 1:
						buf.WriteString("─┘")
					default:
						buf.WriteString("─┴")
					}
				default:
					switch x {
					case 0:
						buf.WriteString(" ├")
					case Size - 1:
						buf.WriteString("─┤")
					default:
						buf.WriteString("─┼")
					}
				}
			}
		}
		fmt.Fprintf(buf, "%2d\n", Size-y)
	}

	buf.WriteString("  ")

	for i := range Size {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')
}

func (b *Board) ValuesString(buf *bytes.Buffer, valuesIdx int) {
	buf.WriteString("\n      │")

	for i := range Size {
		fmt.Fprintf(buf, " %c %2d │", i+'a', i)
	}
	buf.WriteString("\n")

	for range Size {
		fmt.Fprintf(buf, "──────┼")
	}
	fmt.Fprintln(buf, "──────┤")
	for y := 0; y < Size; y++ {
		fmt.Fprintf(buf, "%2d %2d │", Size-y, y)

		for x := 0; x < Size; x++ {
			switch b.stones[y][x] {
			case None:
				value := b.values[y][x][valuesIdx]
				if value == 0 {
					fmt.Fprintf(buf, " Draw │")
				} else if value >= WinValue {
					fmt.Fprintf(buf, " WinX │")
				} else if value <= -WinValue {
					fmt.Fprintf(buf, " WinO │")
				} else {
					fmt.Fprintf(buf, "%5.0f │", b.values[y][x][valuesIdx])
				}
			case Black:
				buf.WriteString("    X │")
			case White:
				buf.WriteString("    O │")
			}
		}

		buf.WriteByte('\n')
	}
	for range Size {
		fmt.Fprintf(buf, "──────┼")
	}
	fmt.Fprintln(buf, "──────┤")
	buf.WriteString("      │")

	for i := range Size {
		fmt.Fprintf(buf, " %c %2d │", i+'a', i)
	}
	buf.WriteString("\n")
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
	return Place{x, y}, nil
}

func (place Place) String() string {
	return fmt.Sprintf("%c%d", place.X+'a', Size-place.Y)
}

package board

import (
	"bytes"
	"errors"
	"fmt"
)

type Stone byte
type Score int16

const (
	None  Stone = 0
	Black Stone = 1
	White Stone = 0x10
)

const maxStones1 = maxStones - 1

type Board struct {
	stones [Size][Size]Stone
	scores [Size][Size][2]Score
}

func NewBoard() *Board {
	board := &Board{}
	for y := 0; y < Size; y++ {
		v := Score(1 + min(maxStones1, y, Size-1-y))
		for x := 0; x < Size; x++ {
			h := Score(1 + min(maxStones1, x, Size-1-x))
			m := 1 + min(x, y, Size-1-x, Size-1-y)
			t1 := Score(min(maxStones, m, max(0, min(Size-maxStones1-y+x, Size-maxStones1-x+y))))
			t2 := Score(min(maxStones, m, max(0, min(2*Size-1-maxStones1-y-x, x+y-maxStones1+1))))
			total := v + h + t1 + t2
			board.scores[y][x] = [2]Score{total, -total}
		}
	}
	return board
}

func (b *Board) PlaceStone(stone Stone, x, y int) {
	b.stones[y][x] = stone
	xStart := max(0, x-maxStones1)
	xEnd := min(x+maxStones, Size) - maxStones1
	stones := Stone(0)
	for xx := xStart; xx < xEnd-1; xx++ {
		stones += b.stones[y][xx]
	}
	fmt.Println("init stones", stones)

	// for xx := xStart; xx < xEnd; xx++ {
	// 	stones += b.stones[y][xx+maxStones1]
	// 	inc := scoreTable[stones]
	// 	fmt.Println("stones", stones, "inc", inc)
	// 	for xxx := xx; xxx < xx+maxStones; xxx++ {
	// 		b.scores[y][xxx][0] += inc[0]
	// 		b.scores[y][xxx][1] += inc[1]
	// 	}
	// }

}

func (b *Board) String() string {
	buf := &bytes.Buffer{}
	b.BoardString(buf)
	return buf.String()
}

func (b *Board) GoString() string {
	buf := &bytes.Buffer{}
	b.BoardString(buf)
	b.ScoresString(buf, 0)
	b.ScoresString(buf, 1)
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
				buf.WriteString("─X")
			case White:
				buf.WriteString("─O")
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

func (b *Board) ScoresString(buf *bytes.Buffer, scoresIdx int) {
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
				fmt.Fprintf(buf, "%5d │", b.scores[y][x][scoresIdx])
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

func ParsePlace(place string) (byte, byte, error) {
	if len(place) < 2 || len(place) > 3 {
		return 0, 0, errors.New("failed to parse place")
	}
	if place[0] < 'a' || place[0] > 's' {
		return 0, 0, errors.New("failed to parse place")
	}
	if place[1] < '0' || place[1] > '9' {
		return 0, 0, errors.New("failed to parse place")
	}
	x := place[0] - 'a'
	y := place[1] - '0'
	if len(place) == 3 {
		if place[2] < '0' || place[2] > '9' {
			return 0, 0, errors.New("failed to parse place")
		}
		y = 10*y + place[2] - '0'
	}
	y = Size - y
	if x > Size || y > Size {
		return 0, 0, errors.New("failed to parse place")
	}
	return x, y, nil
}

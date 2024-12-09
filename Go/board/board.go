package board

import (
	"bytes"
	"errors"
	"fmt"
)

type Stone byte

const (
	None  Stone = 0
	Black Stone = 1
	White Stone = 0x10
)

type Score int32

func (score Score) IsWinning() bool {
	return score < -winning || score > winning
}

const DrawingScore Score = 1
const winning Score = 50_000

func (stone Stone) String() string {
	switch stone {
	case Black:
		return "Black"
	case White:
		return "White"
	}
	return "None"
}

const maxStones1 = maxStones - 1

type Board struct {
	stones [Size][Size]Stone
	scores [Size][Size][2]Score
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
			total := Score(v + h + t1 + t2)
			board.scores[y][x] = [2]Score{total, -total}
		}
	}
	return board
}

func (b *Board) PlaceStone(stone Stone, x, y int) {
	b.placeStone(stone, x, y, 1)
}

func (b *Board) RemoveStone(stone Stone, x, y int) {
	b.placeStone(stone, x, y, -1)
}

func (b *Board) Stone(x, y int) Stone {
	return b.stones[y][x]
}

func (b *Board) Score(stone Stone, x, y int) Score {
	switch stone {
	case Black:
		return b.scores[y][x][0]
	case White:
		return b.scores[y][x][1]
	}
	panic("Score")
}

// func (b *Board) IsWinning(stone Stone, x, y int) bool {
// 	return b.scores[y][x][0] > win || b.scores[y][x][1] < -win
// }

// func (b *Board) IsDrawing(x, y int) bool {
// 	return b.scores[y][x][0] == 0
// }

func (b *Board) placeStone(stone Stone, x, y int, coeff Score) {
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
}

func (b *Board) updateRow(stone Stone, x, y, dx, dy, n int, coeff Score) {
	stones := Stone(0)
	for i := 0; i < maxStones1; i++ {
		stones += b.stones[y+i*dy][x+i*dx]
	}
	for range n {
		stones += b.stones[y+maxStones1*dy][x+maxStones1*dx]
		blackScore, whiteScore := scoreStones(stone, stones)
		if blackScore != 0 || whiteScore != 0 {
			blackScore, whiteScore = blackScore*coeff, whiteScore*coeff
			for j := 0; j < maxStones; j++ {
				s := &b.scores[y+j*dy][x+j*dx]
				s[0] += blackScore
				s[1] += whiteScore
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
				score := b.Score(Black, x, y)
				if score.IsWinning() {
					buf.WriteString("  WIN │")
				} else {
					fmt.Fprintf(buf, "%5d │", b.scores[y][x][scoresIdx])
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

func ParsePlace(place string) (int, int, error) {
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
	return int(x), int(y), nil
}

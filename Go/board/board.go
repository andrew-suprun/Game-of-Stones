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
	Stones [Size][Size]Stone
	Scores [Size][Size][2]Score
}

func NewBoard() *Board {
	board := &Board{}
	for y := 0; y < Size; y++ {
		v := Score(1 + min(maxStones1, y, Size-1-y))
		for x := 0; x < Size; x++ {
			h := Score(1 + min(maxStones1, x, Size-1-x))
			m := 1 + min(x, y, Size-1-x, Size-1-y)
			t1 := Score(max(0, min(maxStones, m, Size-maxStones1-y+x, Size-maxStones1-x+y)))
			t2 := Score(max(0, min(maxStones, m, 2*Size-1-maxStones1-y-x, x+y-maxStones1+1)))
			total := v + h + t1 + t2
			board.Scores[y][x] = [2]Score{total, -total}
		}
	}
	return board
}

func (b *Board) PlaceStone(stone Stone, x, y int) (winner Stone) {
	return b.placeStone(stone, x, y, 1)
}

func (b *Board) RemoveStone(stone Stone, x, y int) {
	b.placeStone(stone, x, y, -1)
}

func (b *Board) placeStone(stone Stone, x, y int, coeff Score) Stone {
	if coeff == -1 {
		b.Stones[y][x] = None
	}
	defer func() {
		if coeff == 1 {
			b.Stones[y][x] = stone
		}
	}()

	{
		start := max(0, x-maxStones1)
		end := min(x+maxStones, Size) - maxStones1
		stones := Stone(0)
		for i := start; i < start+maxStones1; i++ {
			stones += b.Stones[y][i]
		}

		for i := start; i < end; i++ {
			stones += b.Stones[y][i+maxStones1]
			blackScore, whiteScore, winner := scoreStones(stone, stones, coeff)
			if winner != None {
				return winner
			}
			if blackScore != 0 || whiteScore != 0 {
				for j := i; j < i+maxStones; j++ {
					b.Scores[y][j][0] += blackScore
					b.Scores[y][j][1] += whiteScore
				}
			}
			stones -= b.Stones[y][i]
		}
	}

	{
		start := max(0, y-maxStones1)
		end := min(y+maxStones, Size) - maxStones1
		stones := Stone(0)
		for i := start; i < start+maxStones1; i++ {
			stones += b.Stones[i][x]
		}

		for i := start; i < end; i++ {
			stones += b.Stones[i+maxStones1][x]
			blackScore, whiteScore, winner := scoreStones(stone, stones, coeff)
			if winner != None {
				return winner
			}
			if blackScore != 0 || whiteScore != 0 {
				for j := i; j < i+maxStones; j++ {
					b.Scores[j][x][0] += blackScore
					b.Scores[j][x][1] += whiteScore
				}
			}
			stones -= b.Stones[i][x]
		}
	}

	m := 1 + min(x, y, Size-1-x, Size-1-y)

	{
		rows := min(maxStones, m, Size-maxStones1-y+x, Size-maxStones1-x+y)
		if rows > 0 {
			mn := min(x, y, maxStones1)
			xStart := x - mn
			yStart := y - mn

			stones := Stone(0)
			for i := 0; i < maxStones1; i++ {
				stones += b.Stones[yStart+i][xStart+i]
			}
			for i := 0; i < rows; i++ {
				stones += b.Stones[yStart+i+maxStones1][xStart+i+maxStones1]
				blackScore, whiteScore, winner := scoreStones(stone, stones, coeff)
				if winner != None {
					return winner
				}
				if blackScore != 0 || whiteScore != 0 {
					for j := i; j < i+maxStones; j++ {
						b.Scores[yStart+j][xStart+j][0] += blackScore
						b.Scores[yStart+j][xStart+j][1] += whiteScore
					}
				}
				stones -= b.Stones[yStart+i][xStart+i]
			}
		}
	}

	{
		rows := min(maxStones, m, 2*Size-1-maxStones1-y-x, x+y-maxStones1+1)
		if rows > 0 {
			mn := min(Size-1-x, y, maxStones1)
			xStart := x + mn
			yStart := y - mn

			stones := Stone(0)
			for i := 0; i < maxStones1; i++ {
				stones += b.Stones[yStart+i][xStart-i]
			}
			for i := 0; i < rows; i++ {
				stones += b.Stones[yStart+i+maxStones1][xStart-i-maxStones1]
				blackScore, whiteScore, winner := scoreStones(stone, stones, coeff)
				if winner != None {
					return winner
				}
				if blackScore != 0 || whiteScore != 0 {
					for j := i; j < i+maxStones; j++ {
						b.Scores[yStart+j][xStart-j][0] += blackScore
						b.Scores[yStart+j][xStart-j][1] += whiteScore
					}
				}
				stones -= b.Stones[yStart+i][xStart-i]
			}
		}
	}
	return None
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
			switch b.Stones[y][x] {
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
			switch b.Stones[y][x] {
			case None:
				fmt.Fprintf(buf, "%5d │", b.Scores[y][x][scoresIdx])
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

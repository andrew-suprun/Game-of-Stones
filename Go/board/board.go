package board

import (
	"bytes"
	"errors"
	"fmt"
)

const Size = 19

type Stone byte

const (
	Black Stone = 0x01
	White Stone = 0x10
	None  Stone = 0x00
)

type Scores struct {
	values [Size][Size]int16
}

func (s *Scores) Value(x, y int) int16 {
	return s.values[y][x]
}

func (s *Scores) String() string {
	buf := &bytes.Buffer{}
	for y := range Size {
		for x := range Size {
			fmt.Fprintf(buf, "%4d", s.Value(x, y))
		}
		buf.WriteByte('\n')
	}
	return buf.String()
}

type Board struct {
	stones [Size][Size]Stone
}

func (b *Board) Stone(x, y int) Stone {
	return b.stones[y][x]
}

func (b *Board) PlaceStone(x, y byte, stone Stone) {
	if debug {
		if b.stones[y][x] != None {
			panic("PANIC: Invalid PlaceStone")
		}
	}
	b.stones[y][x] = stone
}

func (b *Board) RemoveStone(x, y byte) {
	if debug {
		if b.stones[y][x] == None {
			panic("PANIC: Invalid RemoveStone")
		}
	}
	b.stones[y][x] = None
}

func (b *Board) RatePlace(x, y byte, stone Stone) int16 {
	var score int16 = 0

	{
		startX := max(x, 5) - 5
		endX := min(x+1, Size-5)
		stones := b.stones[y][startX]
		for i := byte(1); i < 5; i++ {
			stones += b.stones[y][startX+i]
		}
		for dx := startX; dx < endX; dx++ {
			stones += b.stones[y][dx+5]
			score += CalcScore(stone, stones)
			stones -= b.stones[y][dx]
		}
	}

	{
		startY := max(y, 5) - 5
		endY := min(y+1, Size-5)
		stones := b.stones[startY][x]
		for i := byte(1); i < 5; i++ {
			stones += b.stones[startY+i][x]
		}
		for dy := startY; dy < endY; dy++ {
			stones += b.stones[dy+5][x]
			score += CalcScore(stone, stones)
			stones -= b.stones[dy][x]
		}
	}

	{
		mindiff := min(x, y, 5)
		maxdiff := max(x, y)

		if maxdiff-mindiff < Size-5 {
			startX := x - mindiff
			startY := y - mindiff
			count := min(mindiff+1, Size-maxdiff, Size-5+mindiff-maxdiff)

			stones := b.stones[startY][startX]
			for i := byte(1); i < 5; i++ {
				stones += b.stones[startY+i][startX+i]
			}

			for c := byte(0); c < count; c++ {
				stones += b.stones[startY+c+5][startX+c+5]
				score += CalcScore(stone, stones)
				stones -= b.stones[startY+c][startX+c]
			}
		}
	}

	{
		revX := Size - 1 - x
		mindiff := min(revX, y, 5)
		maxdiff := max(revX, y)

		if maxdiff-mindiff < Size-5 {
			startX := x + mindiff
			startY := y - mindiff
			count := min(mindiff+1, Size-maxdiff, Size-5+mindiff-maxdiff)

			stones := b.stones[startY][startX]
			for i := byte(1); i < 5; i++ {
				stones += b.stones[startY+i][startX-i]
			}
			for c := range count {
				stones += b.stones[startY+5+c][startX-5-c]
				score += CalcScore(stone, stones)
				stones -= b.stones[startY+c][startX-c]
			}
		}
	}

	return score
}

func (board *Board) CalcScores(stone Stone) (scores Scores) {
	for a := range Size {
		hStones := board.stones[a][0]
		vStones := board.stones[0][a]
		for b := 1; b < 5; b++ {
			hStones += board.stones[a][b]
			vStones += board.stones[b][a]
		}
		for b := 0; b < Size-5; b++ {
			hStones += board.stones[a][b+5]
			vStones += board.stones[b+5][a]
			eScore := CalcScore(stone, hStones)
			sScore := CalcScore(stone, vStones)
			for c := 0; c < 6; c++ {
				scores.values[a][b+c] += eScore
				scores.values[b+c][a] += sScore
			}
			hStones -= board.stones[a][b]
			vStones -= board.stones[b][a]
		}
	}

	for a := 1; a < Size-5; a++ {
		swStones := board.stones[a][0]
		neStones := board.stones[0][a]
		nwStones := board.stones[Size-1-a][0]
		seStones := board.stones[a][Size-1]
		for b := 1; b < 5; b++ {
			swStones += board.stones[a+b][b]
			neStones += board.stones[b][a+b]
			nwStones += board.stones[Size-1-a-b][b]
			seStones += board.stones[a+b][Size-1-b]
		}

		for b := range Size - 5 - a {
			swStones += board.stones[a+b+5][b+5]
			neStones += board.stones[b+5][a+b+5]
			nwStones += board.stones[Size-6-a-b][b+5]
			seStones += board.stones[a+b+5][Size-6-b]
			swScore := CalcScore(stone, swStones)
			neScore := CalcScore(stone, neStones)
			nwScore := CalcScore(stone, nwStones)
			seScore := CalcScore(stone, seStones)
			for c := range 6 {
				scores.values[a+b+c][b+c] += swScore
				scores.values[b+c][a+b+c] += neScore
				scores.values[Size-1-a-b-c][b+c] += nwScore
				scores.values[a+b+c][Size-1-b-c] += seScore
			}
			swStones -= board.stones[a+b][b]
			neStones -= board.stones[b][a+b]
			nwStones -= board.stones[Size-1-a-b][b]
			seStones -= board.stones[a+b][Size-1-b]
		}
	}

	nwseStones := board.stones[0][0]
	neswStones := board.stones[0][Size-1]
	for a := 1; a < 5; a++ {
		nwseStones += board.stones[a][a]
		neswStones += board.stones[a][Size-1-a]
	}
	for b := range Size - 5 {
		nwseStones += board.stones[b+5][b+5]
		neswStones += board.stones[b+5][Size-6-b]
		nwseScore := CalcScore(stone, nwseStones)
		neswScore := CalcScore(stone, neswStones)
		for c := range 6 {
			scores.values[b+c][b+c] += nwseScore
			scores.values[b+c][Size-1-b-c] += neswScore
		}
		nwseStones -= board.stones[b][b]
		neswStones -= board.stones[b][Size-1-b]
	}

	return scores
}

const (
	oneStone    = 1
	twoStones   = 2
	threeStones = 4
	fourStones  = 8
	fiveStones  = 16
	SixStones   = 256
)

func CalcScore(stone Stone, stones Stone) int16 {
	if stone == Black {
		switch stones {
		case 0x00:
			return oneStone
		case 0x01:
			return twoStones - oneStone
		case 0x02:
			return threeStones - twoStones
		case 0x03:
			return fourStones - threeStones
		case 0x04:
			return fiveStones - fourStones
		case 0x05:
			return SixStones
		case 0x10:
			return oneStone
		case 0x20:
			return twoStones
		case 0x30:
			return threeStones
		case 0x40:
			return fourStones
		case 0x50:
			return fiveStones
		default:
			return 0
		}
	} else {
		switch stones {
		case 0x00:
			return -oneStone
		case 0x01:
			return -oneStone
		case 0x02:
			return -twoStones
		case 0x03:
			return -threeStones
		case 0x04:
			return -fourStones
		case 0x05:
			return -fiveStones
		case 0x10:
			return oneStone - twoStones
		case 0x20:
			return twoStones - threeStones
		case 0x30:
			return threeStones - fourStones
		case 0x40:
			return fourStones - fiveStones
		case 0x50:
			return -SixStones
		default:
			return 0
		}
	}
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

func (b *Board) String() string {
	buf := &bytes.Buffer{}
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

	return buf.String()
}

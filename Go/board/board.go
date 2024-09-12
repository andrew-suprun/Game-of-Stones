package board

import (
	"bytes"
	"fmt"
)

const Size = 19

type Stone byte

const (
	Black Stone = 0x01
	White Stone = 0x10
	None  Stone = 0x00
)

type Board [Size][Size]Stone
type Scores [Size][Size]int32

func (b *Board) RatePlace(x, y byte, stone Stone) int32 {
	var score int32 = 0

	{
		startX := max(x, 5) - 5
		endX := min(x+1, Size-5)
		stones := b[y][startX]
		for i := byte(1); i < 5; i++ {
			stones += b[y][startX+i]
		}
		for dx := startX; dx < endX; dx++ {
			stones += b[y][dx+5]
			score += CalcScore(stone, stones)
			stones -= b[y][dx]
		}
	}

	{
		startY := max(y, 5) - 5
		endY := min(y+1, Size-5)
		stones := b[startY][x]
		for i := byte(1); i < 5; i++ {
			stones += b[startY+i][x]
		}
		for dy := startY; dy < endY; dy++ {
			stones += b[dy+5][x]
			score += CalcScore(stone, stones)
			stones -= b[dy][x]
		}
	}

	{
		mindiff := min(x, y, 5)
		maxdiff := max(x, y)

		if maxdiff-mindiff < Size-5 {
			startX := x - mindiff
			startY := y - mindiff
			count := min(mindiff+1, Size-maxdiff, Size-5+mindiff-maxdiff)

			stones := b[startY][startX]
			for i := byte(1); i < 5; i++ {
				stones += b[startY+i][startX+i]
			}

			for c := byte(0); c < count; c++ {
				stones += b[startY+c+5][startX+c+5]
				score += CalcScore(stone, stones)
				stones -= b[startY+c][startX+c]
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

			stones := b[startY][startX]
			for i := byte(1); i < 5; i++ {
				stones += b[startY+i][startX-i]
			}
			for c := range count {
				stones += b[startY+5+c][startX-5-c]
				score += CalcScore(stone, stones)
				stones -= b[startY+c][startX-c]
			}
		}
	}

	return score
}

func (board *Board) CalcScores(stone Stone) (scores Scores) {
	for a := range Size {
		hStones := board[a][0]
		vStones := board[0][a]
		for b := 1; b < 5; b++ {
			hStones += board[a][b]
			vStones += board[b][a]
		}
		for b := 0; b < Size-5; b++ {
			hStones += board[a][b+5]
			vStones += board[b+5][a]
			eScore := CalcScore(stone, hStones)
			sScore := CalcScore(stone, vStones)
			for c := 0; c < 6; c++ {
				scores[a][b+c] += eScore
				scores[b+c][a] += sScore
			}
			hStones -= board[a][b]
			vStones -= board[b][a]
		}
	}

	for a := 1; a < Size-5; a++ {
		swStones := board[a][0]
		neStones := board[0][a]
		nwStones := board[Size-1-a][0]
		seStones := board[a][Size-1]
		for b := 1; b < 5; b++ {
			swStones += board[a+b][b]
			neStones += board[b][a+b]
			nwStones += board[Size-1-a-b][b]
			seStones += board[a+b][Size-1-b]
		}

		for b := range Size - 5 - a {
			swStones += board[a+b+5][b+5]
			neStones += board[b+5][a+b+5]
			nwStones += board[Size-6-a-b][b+5]
			seStones += board[a+b+5][Size-6-b]
			swScore := CalcScore(stone, swStones)
			neScore := CalcScore(stone, neStones)
			nwScore := CalcScore(stone, nwStones)
			seScore := CalcScore(stone, seStones)
			for c := range 6 {
				scores[a+b+c][b+c] += swScore
				scores[b+c][a+b+c] += neScore
				scores[Size-1-a-b-c][b+c] += nwScore
				scores[a+b+c][Size-1-b-c] += seScore
			}
			swStones -= board[a+b][b]
			neStones -= board[b][a+b]
			nwStones -= board[Size-1-a-b][b]
			seStones -= board[a+b][Size-1-b]
		}
	}

	nwseStones := board[0][0]
	neswStones := board[0][Size-1]
	for a := 1; a < 5; a++ {
		nwseStones += board[a][a]
		neswStones += board[a][Size-1-a]
	}
	for b := range Size - 5 {
		nwseStones += board[b+5][b+5]
		neswStones += board[b+5][Size-6-b]
		nwseScore := CalcScore(stone, nwseStones)
		neswScore := CalcScore(stone, neswStones)
		for c := range 6 {
			scores[b+c][b+c] += nwseScore
			scores[b+c][Size-1-b-c] += neswScore
		}
		nwseStones -= board[b][b]
		neswStones -= board[b][Size-1-b]
	}

	return scores
}

const (
	oneStone    = 2
	twoStones   = 10
	threeStones = 40
	fourStones  = 120
	fiveStones  = 240
	sixStones   = 10_000
)

func CalcScore(stone Stone, stones Stone) int32 {
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
			return sixStones
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
			return -sixStones
		default:
			return 0
		}
	}
}

func (b *Board) String() string {
	buf := &bytes.Buffer{}
	buf.WriteString("\n  ")

	for i := range Size {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')

	for y := range Size {
		fmt.Fprintf(buf, "%2d", y)
		for x := range Size {
			switch b[y][x] {
			case Black:
				buf.WriteString("-X")
			case White:
				buf.WriteString("-O")
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
		fmt.Fprintf(buf, "%2d\n", y)
	}

	buf.WriteString("  ")

	for i := range Size {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')

	return buf.String()
}

func (s *Scores) String() string {
	buf := &bytes.Buffer{}
	for y := range Size {
		for x := range Size {
			fmt.Fprintf(buf, "%4d", s[y][x])
		}
		buf.WriteByte('\n')
	}
	return buf.String()
}

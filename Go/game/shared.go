package game

import (
	"bytes"
	"fmt"
)

const boardSize = 19

type stone byte

const (
	black stone = 0x01
	white stone = 0x10
	none  stone = 0x00
)

type board [boardSize][boardSize]stone
type scores [boardSize][boardSize]int32

func (board *board) calcScores(stone stone) (scores scores) {
	for a := range boardSize {
		hStones := board[a][0]
		vStones := board[0][a]
		for b := 1; b < 5; b++ {
			hStones += board[a][b]
			vStones += board[b][a]
		}
		for b := 0; b < boardSize-5; b++ {
			hStones += board[a][b+5]
			vStones += board[b+5][a]
			eScore := calcScore(stone, hStones)
			sScore := calcScore(stone, vStones)
			for c := 0; c < 6; c++ {
				scores[a][b+c] += eScore
				scores[b+c][a] += sScore
			}
			hStones -= board[a][b]
			vStones -= board[b][a]
		}
	}

	// for (1..board_size - 5) |a| {
	//     var swStones: i32 = @intFromEnum(self.board[a][0]);
	//     var neStones: i32 = @intFromEnum(self.board[0][a]);
	//     var nwStones: i32 = @intFromEnum(self.board[board_size - 1 - a][0]);
	//     var seStones: i32 = @intFromEnum(self.board[a][board_size - 1]);
	//     for (1..5) |b| {
	//         swStones += @intFromEnum(self.board[a + b][b]);
	//         neStones += @intFromEnum(self.board[b][a + b]);
	//         nwStones += @intFromEnum(self.board[board_size - 1 - a - b][b]);
	//         seStones += @intFromEnum(self.board[a + b][board_size - 1 - b]);
	//     }

	//     for (0..board_size - 5 - a) |b| {
	//         swStones += @intFromEnum(self.board[a + b + 5][b + 5]);
	//         neStones += @intFromEnum(self.board[b + 5][a + b + 5]);
	//         nwStones += @intFromEnum(self.board[board_size - 6 - a - b][b + 5]);
	//         seStones += @intFromEnum(self.board[a + b + 5][board_size - 6 - b]);
	//         const swScore = calcScore(stone, swStones);
	//         const neScore = calcScore(stone, neStones);
	//         const nwScore = calcScore(stone, nwStones);
	//         const seScore = calcScore(stone, seStones);
	//         inline for (0..6) |c| {
	//             scores[a + b + c][b + c] += swScore;
	//             scores[b + c][a + b + c] += neScore;
	//             scores[board_size - 1 - a - b - c][b + c] += nwScore;
	//             scores[a + b + c][board_size - 1 - b - c] += seScore;
	//         }
	//         swStones -= @intFromEnum(self.board[a + b][b]);
	//         neStones -= @intFromEnum(self.board[b][a + b]);
	//         nwStones -= @intFromEnum(self.board[board_size - 1 - a - b][b]);
	//         seStones -= @intFromEnum(self.board[a + b][board_size - 1 - b]);
	//     }
	// }

	// var nwseStones: i32 = @intFromEnum(self.board[0][0]);
	// var neswStones: i32 = @intFromEnum(self.board[0][board_size - 1]);
	// for (1..5) |a| {
	//     nwseStones += @intFromEnum(self.board[a][a]);
	//     neswStones += @intFromEnum(self.board[a][board_size - 1 - a]);
	// }
	// for (0..board_size - 5) |b| {
	//     nwseStones += @intFromEnum(self.board[b + 5][b + 5]);
	//     neswStones += @intFromEnum(self.board[b + 5][board_size - 6 - b]);
	//     const nwseScore = calcScore(stone, nwseStones);
	//     const neswScore = calcScore(stone, neswStones);
	//     inline for (0..6) |c| {
	//         scores[b + c][b + c] += nwseScore;
	//         scores[b + c][board_size - 1 - b - c] += neswScore;
	//     }
	//     nwseStones -= @intFromEnum(self.board[b][b]);
	//     neswStones -= @intFromEnum(self.board[b][board_size - 1 - b]);
	// }

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

func calcScore(stone stone, stones stone) int32 {
	if stone == black {
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

func (b *board) String() string {
	buf := &bytes.Buffer{}
	buf.WriteString("\n  ")

	for i := range boardSize {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')

	for y := range boardSize {
		fmt.Fprintf(buf, "%2d", y)
		for x := range boardSize {
			switch b[y][x] {
			case black:
				buf.WriteString("-X")
			case white:
				buf.WriteString("-O")
			default:
				switch y {
				case 0:
					switch x {
					case 0:
						buf.WriteString(" ┌")
					case boardSize - 1:
						buf.WriteString("─┐")
					default:
						buf.WriteString("─┬")
					}
				case boardSize - 1:
					switch x {
					case 0:
						buf.WriteString(" └")
					case boardSize - 1:
						buf.WriteString("─┘")
					default:
						buf.WriteString("─┴")
					}
				default:
					switch x {
					case 0:
						buf.WriteString(" ├")
					case boardSize - 1:
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

	for i := range boardSize {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')

	return buf.String()
}

func (s *scores) String() string {
	buf := &bytes.Buffer{}
	for y := range boardSize {
		for x := range boardSize {
			fmt.Fprintf(buf, "%4d", s[y][x])
		}
		buf.WriteByte('\n')
	}
	return buf.String()
}

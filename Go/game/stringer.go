package game

import (
	"bytes"
	"fmt"
)

func (place Place) String() string {
	return fmt.Sprintf("%c%d", place.X+'a', Size-place.Y)
}

func (m Move) String() string {
	if m.P1 == m.P2 {
		return m.P1.String()
	}
	return m.P1.String() + "-" + m.P2.String()
}

func (m Move) GoString() string {
	state := ""
	if m.IsTerminal() {
		state = " Terminal"
	} else if m.IsDecisive() {
		state = " Decisive"
	}
	return fmt.Sprintf("%-7v v: %4d%s", m, m.value, state)
}
func (game *Game) String() string {
	buf := &bytes.Buffer{}
	game.GameString(buf)
	return buf.String()
}

func (game *Game) GoString() string {
	buf := &bytes.Buffer{}
	game.GameString(buf)
	game.ValuesString(buf, 0)
	game.ValuesString(buf, 1)
	return buf.String()
}

func (game *Game) GameString(buf *bytes.Buffer) {
	buf.WriteString("\n  ")

	for i := range Size {
		fmt.Fprintf(buf, " %c", i+'a')
	}
	buf.WriteByte('\n')

	for y := range Size {
		fmt.Fprintf(buf, "%2d", Size-y)
		for x := range Size {
			switch game.stones[y][x] {
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

func (game *Game) ValuesString(buf *bytes.Buffer, valuesIdx int) {
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
			switch game.stones[y][x] {
			case None:
				value := game.values[y][x][valuesIdx]
				if value == 0 {
					fmt.Fprintf(buf, " Draw │")
				} else if value >= WinValue {
					fmt.Fprintf(buf, " WinX │")
				} else if value <= -WinValue {
					fmt.Fprintf(buf, " WinO │")
				} else {
					fmt.Fprintf(buf, "%5d │", game.values[y][x][valuesIdx])
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

package board

import (
	"testing"
)

func Test1(t *testing.T) {
	b := NewBoard()
	t.Logf("%#v\n", b)
	for y := byte(0); y < Size; y++ {
		for x := byte(0); x < Size; x++ {
			if b.debugRatePlace(x, y, Black) != b.scores[y][x][0] {
				t.Log("black: x", x, "y", y, "expected", b.scores[y][x][0], "got", b.debugRatePlace(x, y, Black))
				t.Fail()
			}
			if b.debugRatePlace(x, y, White) != b.scores[y][x][1] {
				t.Log("white: x", x, "y", y, "expected", b.scores[y][x][1], "got", b.debugRatePlace(x, y, White))
				t.Fail()
			}
		}
	}
}

func Test2(t *testing.T) {
}

func Test3(t *testing.T) {
}

func Test4(t *testing.T) {
}

func Test5(t *testing.T) {
}

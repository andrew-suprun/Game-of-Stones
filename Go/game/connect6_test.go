package game

import (
	"fmt"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", move{x1: 1, y1: 2, x2: 3, y2: 4, score: 5})
	if result != "b17-d15: move{x1: 1, y1: 2, x2: 3, y2: 4, score: 5}" {
		t.Fail()
	}
}

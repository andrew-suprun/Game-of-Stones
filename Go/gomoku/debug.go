//go:build debug

package gomoku

import "log"

func (c *Gomoku) Validate() {
	expected := c.board.BoardValue()
	if c.value != expected {
		log.Printf("Validation failed\nBoard %#v\n", &c.board)
		log.Panicf("expected=%v got=%v\n", expected, c.value)
	}
}

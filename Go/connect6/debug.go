//go:build debug

package connect6

import "log"

func (c *Connect6) Validate() {
	expected := c.board.BoardValue()
	if c.value != expected {
		log.Printf("Validation failed\nBoard %#v\n", &c.board)
		log.Panicf("expected=%v got=%v\n", expected, c.value)
	}
}

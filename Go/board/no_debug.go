//go:build !debug

package board

func (b *Board) Validate() {}

func (b *Board) BoardValue() int {
	return 0
}

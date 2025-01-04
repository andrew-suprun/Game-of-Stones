package turn

type Turn int

const (
	First Turn = iota
	Second
)

func (turn Turn) String() string {
	switch turn {
	case First:
		return "First"
	case Second:
		return "Second"
	}
	panic("Turn.String()")
}

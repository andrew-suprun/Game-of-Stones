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

type Move struct {
	X, Y     int8
	value    float32
	draw     bool
	terminal bool
}

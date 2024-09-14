package connect6

import (
	"errors"
	"fmt"
	"game_of_stones/board"
	"game_of_stones/heap"
	"math"
	"strings"
)

type move struct {
	x1, y1, x2, y2 byte
	score          int16
}

const (
	draw int16 = math.MinInt16
	win  int16 = math.MaxInt16
)

func (m move) IsDraw() bool { return m.score == draw }
func (m move) IsWin() bool  { return m.score == win }
func (m move) Score() int16 { return m.score }
func (m move) String() string {
	return fmt.Sprintf("%c%d-%c%d", m.x1+'a', board.Size-m.y1, m.x2+'a', board.Size-m.y2)
}
func (m move) GoString() string {
	return fmt.Sprintf("makeMove(%d, %d, %d, %d, %d)", m.x1, m.y1, m.x2, m.y2, m.score)
}

type Connect6 struct {
	turn      board.Stone
	board     board.Board
	maxMoves  int
	maxPlaces int
}

func NewGame(maxPlaces int) Connect6 {
	return Connect6{
		turn:      board.Black,
		maxMoves:  maxPlaces * maxPlaces / 16,
		maxPlaces: maxPlaces,
	}
}

func (c *Connect6) MakeMove(moveStr string) (move, error) {
	tokens := strings.Split(moveStr, "-")
	if len(tokens) != 2 {
		return move{}, errors.New("failed to parse move")
	}
	x1, y1, err1 := parseToken(tokens[0])
	x2, y2, err2 := parseToken(tokens[1])
	if err1 != nil || err2 != nil {
		return move{}, errors.New("failed to parse move")
	}

	score1 := c.board.RatePlace(x1, y1, c.turn)
	c.board.PlaceStone(x1, y1, c.turn)
	score2 := c.board.RatePlace(x2, y2, c.turn)
	c.board.RemoveStone(x1, y1)

	return makeMove(x1, y1, x2, y2, score1+score2), nil
}

func parseToken(token string) (int, int, error) {
	if len(token) < 2 || len(token) > 3 {
		return 0, 0, errors.New("failed to parse token")
	}
	if token[0] < 'a' || token[0] > 's' {
		return 0, 0, errors.New("failed to parse token")
	}
	if token[1] < '0' || token[1] > '9' {
		return 0, 0, errors.New("failed to parse token")
	}
	x := token[0] - 'a'
	y := token[1] - '0'
	if len(token) == 3 {
		if token[2] < '0' || token[2] > '9' {
			return 0, 0, errors.New("failed to parse token")
		}
		y = 10*y + token[2] - '0'
	}
	y = board.Size - y
	if x > board.Size || y > board.Size {
		return 0, 0, errors.New("failed to parse token")
	}
	return int(x), int(y), nil
}

func makeMove(x1, y1, x2, y2 int, score int16) move {
	if x1 > x2 || x1 == x2 && y1 > y2 {
		return move{byte(x2), byte(y2), byte(x1), byte(y1), score}
	}
	return move{byte(x1), byte(y1), byte(x2), byte(y2), score}
}

func (c *Connect6) playMove(x1, y1, x2, y2 int) {
	c.board.PlaceStone(x1, y1, c.turn)
	c.board.PlaceStone(x2, y2, c.turn)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) UndoMove(x1, y1, x2, y2 int) {
	c.board.RemoveStone(x1, y1)
	c.board.RemoveStone(x2, y2)
	if c.turn == board.Black {
		c.turn = board.White
	} else {
		c.turn = board.Black
	}
}

func (c *Connect6) PossibleMoves(limit int16) []move {
	scores := c.board.CalcScores(c.turn)
	places := c.possiblePlaces(&scores)
	return c.selectMoves(places)
}

type place struct {
	x, y  int
	score int16
}

func lessForBlackPlace(a, b place) bool {
	return a.score < b.score
}

func lessForWhitePlace(a, b place) bool {
	return b.score < a.score
}

func (c *Connect6) possiblePlaces(scores *board.Scores) []place {
	var h *heap.Heap[place]
	if c.turn == board.Black {
		h = heap.NewHeap(c.maxPlaces, lessForBlackPlace)
	} else {
		h = heap.NewHeap(c.maxPlaces, lessForWhitePlace)
	}
	for y := range board.Size {
		for x := range board.Size {
			if c.board.Stone(x, y) == board.None {
				h.Add(place{x: x, y: y, score: scores.Value(x, y)})
			}
		}
	}
	return h.Items
}

func lessForBlackMove(a, b move) bool {
	return a.score < b.score
}

func lessForWhiteMove(a, b move) bool {
	return b.score < a.score
}

func (c *Connect6) selectMoves(places []place) []move {
	var h *heap.Heap[move]
	if c.turn == board.Black {
		h = heap.NewHeap(c.maxMoves, lessForBlackMove)
	} else {
		h = heap.NewHeap(c.maxMoves, lessForWhiteMove)
	}

	for i, p1 := range places[:len(places)-1] {
		if p1.score >= board.SixStones || -p1.score >= board.SixStones {
			return []move{makeMove(p1.x, p1.y, p1.x, p1.y, win)}
		}
		for _, p2 := range places[i+1:] {
			if p1.x == p2.x || p1.y == p2.y || p1.x+p1.y == p2.x+p2.y || p1.x+p2.y == p2.x+p1.y {
				c.board.PlaceStone(p1.x, p1.y, c.turn)
				p2.score = c.board.RatePlace(p2.x, p2.y, c.turn)
				c.board.RemoveStone(p1.x, p1.y)
			}

			if p2.score >= board.SixStones || -p2.score >= board.SixStones {
				return []move{makeMove(p1.x, p1.y, p2.x, p2.y, win)}
			}

			if p1.score == 0 && p2.score == 0 {
				return []move{makeMove(p1.x, p1.y, p2.x, p2.y, draw)}
			}

			h.Add(makeMove(p1.x, p1.y, p2.x, p2.y, p1.score+p2.score))
		}
	}
	return h.Sorted()
}

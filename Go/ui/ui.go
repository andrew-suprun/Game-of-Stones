package main

import (
	"fmt"
	"game_of_stones/board"
	"image"
	"image/color"
	"log"
	"os"
	"strings"

	"gioui.org/app"
	"gioui.org/io/event"
	"gioui.org/io/key"
	"gioui.org/io/pointer"
	"gioui.org/op"
	"gioui.org/op/clip"
	"gioui.org/op/paint"
)

const (
	windowSize = 800
)

var (
	colorBg       = color.NRGBA{127, 106, 79, 255}
	colorSelected = color.NRGBA{127, 127, 127, 255}
	colorBlack    = color.NRGBA{0, 0, 0, 255}
	colorWhite    = color.NRGBA{255, 255, 255, 255}
)

type cellState int

const (
	stateEmpty cellState = iota
	stateBlackSelected
	stateWhiteSelected
	stateBlack
	stateWhite
)

type turn int

const (
	humanTurn turn = iota
	engineTurn
)

type state struct {
	cells [board.Size][board.Size]cellState
	turn  turn
}

type move string

func runUi(commands chan any, events chan any) error {
	commands <- cmdStart{}
	commands <- cmdMakeMove("j10-j10")
	gameState := state{}
	gameState.cells[9][9] = stateBlack
	stateChan := make(chan *state, 1)
	stateChan <- &gameState

	var ops op.Ops

	window := new(app.Window)
	window.Option(app.Title("Connect6"), app.Size(windowSize, windowSize))
	window.Option(app.Decorated(false))

	go input(window, stateChan, events)

	for {
		switch e := window.Event().(type) {
		case app.DestroyEvent:
			if e.Err != nil {
				log.Fatal(e.Err)
			}
			os.Exit(0)
		case app.FrameEvent:
			frame(&ops, e, commands, stateChan)
		case app.AppKitViewEvent:
			// ignore
		case app.ConfigEvent:
			// ignore
		}
	}
}

func frame(ops *op.Ops, ev app.FrameEvent, commands chan any, stateChan chan *state) {
	state := <-stateChan
	defer func() {
		stateChan <- state
	}()
	ops.Reset()

	size := min(ev.Size.X, ev.Size.Y)
	d := size / 20
	r := d / 2

	paint.Fill(ops, colorBg)

	for i := 1; i < 20; i++ {
		paint.FillShape(ops, colorBlack, clip.Stroke{
			Path:  clip.Rect{Min: image.Point{X: d, Y: i * d}, Max: image.Point{X: board.Size * d, Y: i * d}}.Path(),
			Width: 1,
		}.Op())
		paint.FillShape(ops, colorBlack, clip.Stroke{
			Path:  clip.Rect{Min: image.Point{X: i * d, Y: d}, Max: image.Point{X: i * d, Y: board.Size * d}}.Path(),
			Width: 1,
		}.Op())
	}

	selected := []int{}
	for y := range board.Size {
		for x := range board.Size {
			if state.cells[y][x] == stateBlackSelected {
				selected = append(selected, x, y)
			}
		}
	}

	for y := range board.Size {
		for x := range board.Size {
			for {
				_, ok := ev.Source.Event(pointer.Filter{
					Target: &state.cells[y][x],
					Kinds:  pointer.Press,
				})
				if !ok {
					break
				}
				switch state.cells[y][x] {
				case stateBlackSelected:
					state.cells[y][x] = stateEmpty
				case stateEmpty:
					if state.turn == humanTurn && len(selected) < 4 {
						state.cells[y][x] = stateBlackSelected
					}
				}
			}
			stack := clip.Rect{Min: image.Point{X: (x+1)*d - r, Y: (y+1)*d - r}, Max: image.Point{X: (x+1)*d + r, Y: (y+1)*d + r}}.Push(ops)
			event.Op(ops, &state.cells[y][x])
			stack.Pop()

			var stoneColor color.NRGBA
			switch state.cells[y][x] {
			case stateEmpty:
				continue
			case stateBlack, stateBlackSelected:
				stoneColor = colorBlack
			case stateWhite, stateWhiteSelected:
				stoneColor = colorWhite
			}
			stack = clip.Ellipse{
				Min: image.Point{X: (x+1)*d - r + 2, Y: (y+1)*d - r + 2},
				Max: image.Point{X: (x+1)*d + r - 2, Y: (y+1)*d + r - 2},
			}.Push(ops)
			paint.ColorOp{Color: stoneColor}.Add(ops)
			paint.PaintOp{}.Add(ops)
			stack.Pop()

			if state.cells[y][x] == stateBlackSelected || state.cells[y][x] == stateWhiteSelected {
				rr := r / 6
				stack = clip.Ellipse{
					Min: image.Point{X: (x+1)*d - rr, Y: (y+1)*d - rr},
					Max: image.Point{X: (x+1)*d + rr, Y: (y+1)*d + rr},
				}.Push(ops)
				paint.ColorOp{Color: colorSelected}.Add(ops)
				paint.PaintOp{}.Add(ops)
				stack.Pop()
			}
		}
	}

	if keyEv, ok := ev.Source.Event(key.Filter{Name: ""}); ok {
		keyEvent := keyEv.(key.Event)
		if keyEvent.State == key.Press {
			switch keyEvent.Name {
			case key.NameReturn:
				if len(selected) == 4 {
					for y := range board.Size {
						for x := range board.Size {
							if state.cells[y][x] == stateWhiteSelected {
								state.cells[y][x] = stateWhite
							}
						}
					}
					state.cells[selected[1]][selected[0]] = stateBlack
					state.cells[selected[3]][selected[2]] = stateBlack
					state.turn = engineTurn

					place1 := fmt.Sprintf("%c%d", selected[0]+'a', board.Size-selected[1])
					place2 := fmt.Sprintf("%c%d", selected[2]+'a', board.Size-selected[3])
					moveStr := place1 + "-" + place2
					commands <- cmdMakeMove(moveStr)
				}
			case key.NameEscape:
				for y := range board.Size {
					for x := range board.Size {
						if state.cells[y][x] == stateBlackSelected || state.cells[y][x] == stateWhiteSelected {
							state.cells[y][x] = stateEmpty
						}
					}
				}
			default:
				fmt.Println("Other", keyEvent)
			}
		}
	}

	ev.Frame(ops)
}

func input(window *app.Window, stateChan chan *state, events chan any) {
	for engineEvent := range events {
		state := <-stateChan
		switch e := engineEvent.(type) {
		case evMove:
			x1, y1, x2, y2 := ParseMove(e)
			state.cells[y1][x1] = stateWhiteSelected
			state.cells[y2][x2] = stateWhiteSelected
			window.Invalidate()
		}
		state.turn = humanTurn
		stateChan <- state
	}
}

func ParseMove(moveStr evMove) (int, int, int, int) {
	tokens := strings.Split(string(moveStr), "-")
	p1, _ := board.ParsePlace(tokens[0])
	p2 := p1
	if len(tokens) > 1 {
		p2, _ = board.ParsePlace(tokens[1])
	}
	return int(p1.X), int(p1.Y), int(p2.X), int(p2.Y)
}

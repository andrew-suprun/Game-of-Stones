package main

import (
	"fmt"
	"game_of_stones/board"
	"image"
	"image/color"
	"log"
	"os"

	"gioui.org/app"
	"gioui.org/io/event"
	"gioui.org/io/pointer"
	"gioui.org/op"
	"gioui.org/op/clip"
	"gioui.org/op/paint"
)

const (
	windowSize = 1000
)

var (
	colorBg       = color.NRGBA{127, 106, 79, 255}
	colorSelected = color.NRGBA{0, 0, 0, 195}
	colorBlack    = color.NRGBA{0, 0, 0, 255}
	colorWhite    = color.NRGBA{255, 255, 255, 255}
)

func runUi(state chan *gameState) error {
	var ops op.Ops

	window := new(app.Window)
	window.Option(app.Title("Connect6"), app.Size(windowSize, windowSize))
	window.Option(app.Decorated(false))

	for {
		switch e := window.Event().(type) {
		case app.DestroyEvent:
			if e.Err != nil {
				log.Fatal(e.Err)
			}
			os.Exit(0)
		case app.FrameEvent:
			frame(&ops, e, state)
		case app.AppKitViewEvent:
			// ignore
		case app.ConfigEvent:
			// ignore
		default:
			fmt.Printf("event %T\n", e)
		}
	}
}

func frame(ops *op.Ops, ev app.FrameEvent, stateChan chan *gameState) {
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

	nSelected := 0
	for y := range board.Size {
		for x := range board.Size {
			if state.cells[y][x] == selected {
				nSelected++
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
				case selected:
					state.cells[y][x] = empty
				case empty:
					if nSelected < 2 {
						state.cells[y][x] = selected
					}
				}
			}
			stack := clip.Rect{Min: image.Point{X: (x+1)*d - r, Y: (y+1)*d - r}, Max: image.Point{X: (x+1)*d + r, Y: (y+1)*d + r}}.Push(ops)
			event.Op(ops, &state.cells[y][x])
			stack.Pop()

			var stoneColor color.NRGBA
			switch state.cells[y][x] {
			case empty:
				continue
			case black:
				stoneColor = colorBlack
			case white:
				stoneColor = colorWhite
			case selected:
				stoneColor = colorSelected
			}
			stack = clip.Ellipse{
				Min: image.Point{X: (x+1)*d - r + 1, Y: (y+1)*d - r + 1},
				Max: image.Point{X: (x+1)*d + r - 1, Y: (y+1)*d + r - 1},
			}.Push(ops)
			paint.ColorOp{Color: stoneColor}.Add(ops)
			paint.PaintOp{}.Add(ops)
			stack.Pop()
		}
	}
	ev.Frame(ops)
}

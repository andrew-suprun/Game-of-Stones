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
	bg    = color.NRGBA{127, 106, 79, 255}
	black = color.NRGBA{0, 0, 0, 255}
	white = color.NRGBA{255, 255, 255, 255}
)

func main() {
	go run()
	app.Main()
}

func run() error {
	var ops op.Ops

	cells := [board.Size][board.Size]struct {
		stone board.Stone
	}{}

	stones := []struct {
		x     int
		y     int
		stone board.Stone
	}{
		{x: 9, y: 9, stone: board.Black},
		{x: 8, y: 9, stone: board.White},
		{x: 8, y: 8, stone: board.White},
	}

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
			ops.Reset()
			size := min(e.Size.X, e.Size.Y)
			d := size / 20
			r := d / 2

			for y := range board.Size {
				for x := range board.Size {
					for {
						_, ok := e.Source.Event(pointer.Filter{
							Target: &cells[y][x],
							Kinds:  pointer.Press,
						})
						if !ok {
							break
						}
						fmt.Println("clicked", x, y)
					}
					stack := clip.Rect{Min: image.Point{X: (x+1)*d - r, Y: (y+1)*d - r}, Max: image.Point{X: (x+1)*d + r, Y: (y+1)*d + r}}.Push(&ops)
					event.Op(&ops, &cells[y][x])
					stack.Pop()
				}
			}

			paint.Fill(&ops, bg)

			for i := 1; i < 20; i++ {
				paint.FillShape(&ops, black, clip.Stroke{
					Path:  clip.Rect{Min: image.Point{X: d, Y: i * d}, Max: image.Point{X: board.Size * d, Y: i * d}}.Path(),
					Width: 1,
				}.Op())
				paint.FillShape(&ops, black, clip.Stroke{
					Path:  clip.Rect{Min: image.Point{X: i * d, Y: d}, Max: image.Point{X: i * d, Y: board.Size * d}}.Path(),
					Width: 1,
				}.Op())
				for _, stone := range stones {
					color := black
					if stone.stone == board.White {
						color = white
					}
					stack := clip.Ellipse{
						Min: image.Point{X: (stone.x+1)*d - r + 1, Y: (stone.y+1)*d - r + 1},
						Max: image.Point{X: (stone.x+1)*d + r - 1, Y: (stone.y+1)*d + r - 1},
					}.Push(&ops)
					paint.ColorOp{Color: color}.Add(&ops)
					paint.PaintOp{}.Add(&ops)
					stack.Pop()
				}

			}

			e.Frame(&ops)
		case app.AppKitViewEvent:
			// ignore
		case app.ConfigEvent:
			// ignore
		default:
			fmt.Printf("event %T\n", e)
		}
	}
}

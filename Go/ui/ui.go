package main

import (
	"image/color"
	"time"

	"math/rand"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/layout"
)

const boardSize = 1000
const radius = boardSize/40 - 1
const diameter = boardSize / 20

func main() {
	app := app.New()
	win := app.NewWindow("Connect6")
	win.Resize(fyne.NewSize(boardSize, boardSize))
	win.SetPadded(false)

	rect := canvas.NewRectangle(color.NRGBA{127, 106, 79, 255})
	rect.Move(fyne.Position{X: 0, Y: 0})
	rect.Resize(fyne.Size{Width: boardSize, Height: boardSize})

	objects := []fyne.CanvasObject{rect}
	var i float32 = diameter
	for ; i < 20*diameter; i += diameter {
		objects = append(objects,
			&canvas.Line{
				Position1:   fyne.Position{X: diameter - 1, Y: i - 1},
				Position2:   fyne.Position{X: boardSize - diameter - 1, Y: i - 1},
				StrokeColor: color.NRGBA{R: 0, G: 0, B: 0, A: 127},
				StrokeWidth: 3,
			},
			&canvas.Line{
				Position1:   fyne.Position{X: i - 1, Y: diameter - 1},
				Position2:   fyne.Position{X: i - 1, Y: boardSize - diameter - 1},
				StrokeColor: color.NRGBA{R: 0, G: 0, B: 0, A: 127},
				StrokeWidth: 3,
			},
		)
	}

	texts := []fyne.CanvasObject{}
	for range 19 * 19 {
		switch rand.Intn(3) {
		case 0:
			texts = append(texts, canvas.NewCircle(color.Black))
		case 1:
			texts = append(texts, canvas.NewCircle(color.White))
		case 2:
			texts = append(texts, canvas.NewCircle(color.Transparent))
		}
	}
	grid := container.New(layout.NewGridLayout(19), texts...)
	grid.Move(fyne.Position{X: radius, Y: radius})
	grid.Resize(fyne.Size{Width: 1000 - diameter, Height: 1000 - diameter})

	go func() {
		for {
			time.Sleep(time.Second)
			for _, object := range grid.Objects {
				switch rand.Intn(3) {
				case 0:
					object.(*canvas.Circle).FillColor = color.Black
				case 1:
					object.(*canvas.Circle).FillColor = color.White
				case 2:
					object.(*canvas.Circle).FillColor = color.Transparent
				}
			}
			grid.Refresh()
		}
	}()

	objects = append(objects, grid)

	content := container.NewWithoutLayout(objects...)
	// content := container.NewWithoutLayout(c)
	win.SetContent(content)
	win.ShowAndRun()
}

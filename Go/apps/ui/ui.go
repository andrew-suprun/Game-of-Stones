package main

import (
	"bufio"
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
	windowSize = 1000
)

var (
	colorBg       = color.NRGBA{127, 106, 79, 255}
	colorSelected = color.NRGBA{127, 127, 127, 255}
	colorBlack    = color.NRGBA{0, 0, 0, 255}
	colorWhite    = color.NRGBA{255, 255, 255, 255}
)

type placeState int

const (
	stateEmpty placeState = iota
	stateBlackSelected
	stateWhiteSelected
	stateBlack
	stateWhite
)

type state [board.Size][board.Size]placeState

func main() {
	go run()
	app.Main()
}

func run() {
	gameState := state{}
	stateChan := make(chan *state, 1)
	stateChan <- &gameState

	var ops op.Ops

	window := new(app.Window)
	window.Option(app.Title("Connect6"), app.Size(windowSize, windowSize))
	window.Option(app.Decorated(false))

	go input(window, stateChan)

	for {
		switch e := window.Event().(type) {
		case app.DestroyEvent:
			if e.Err != nil {
				log.Fatal(e.Err)
			}
			os.Exit(0)
		case app.FrameEvent:
			frame(&ops, e, stateChan)
		case app.AppKitViewEvent:
			// ignore
		case app.ConfigEvent:
			// ignore
		}
	}
}

func frame(ops *op.Ops, ev app.FrameEvent, stateChan chan *state) {
	state := <-stateChan
	defer func() {
		stateChan <- state
	}()
	ops.Reset()

	size := min(ev.Size.X, ev.Size.Y)
	d := size/board.Size - 1
	r := d / 2

	paint.Fill(ops, colorBg)

	for i := 1; i <= board.Size; i++ {
		paint.FillShape(ops, colorBlack, clip.Stroke{
			Path:  clip.Rect{Min: image.Point{X: d, Y: i * d}, Max: image.Point{X: board.Size * d, Y: i * d}}.Path(),
			Width: 1,
		}.Op())
		paint.FillShape(ops, colorBlack, clip.Stroke{
			Path:  clip.Rect{Min: image.Point{X: i * d, Y: d}, Max: image.Point{X: i * d, Y: board.Size * d}}.Path(),
			Width: 1,
		}.Op())
	}

	for y := range board.Size {
		for x := range board.Size {
			for {
				_, ok := ev.Source.Event(pointer.Filter{
					Target: &state[y][x],
					Kinds:  pointer.Press,
				})
				if !ok {
					break
				}
				fmt.Printf("click: %s\n", board.Place{X: int8(x), Y: int8(y)})
			}
			stack := clip.Rect{Min: image.Point{X: (x+1)*d - r, Y: (y+1)*d - r}, Max: image.Point{X: (x+1)*d + r, Y: (y+1)*d + r}}.Push(ops)
			event.Op(ops, &state[y][x])
			stack.Pop()

			var stoneColor color.NRGBA
			switch state[y][x] {
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

			if state[y][x] == stateBlackSelected || state[y][x] == stateWhiteSelected {
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
				fmt.Printf("key: Enter\n")
			case key.NameEscape:
				fmt.Printf("key: Excape\n")
			default:
				fmt.Println("key:", keyEvent)
			}
		}
	}

	ev.Frame(ops)
}

func input(window *app.Window, stateChan chan *state) {
	reader := bufio.NewReader(os.Stdin)

	for {
		text, err := reader.ReadString('\n')
		text = strings.TrimSpace(text)
		if err != nil {
			fmt.Println("error: Failed to read from standard input.")
			os.Exit(1)
		}
		if text == "stop" {
			fmt.Println("info: Stopped.")
			os.Exit(0)
		}
		if strings.HasPrefix(text, "set ") {
			setStone(stateChan, text)
		}
		window.Invalidate()
	}
}

func setStone(stateChan chan *state, cmd string) {
	state := <-stateChan

	parts := strings.Fields(cmd)
	if len(parts) != 3 {
		fmt.Printf("error: Invalid set command: %q\n", cmd)
		os.Exit(1)
	}
	place, err := board.ParsePlace(parts[1])
	if err != nil {
		fmt.Printf("error: Invalid set command: %q\n", cmd)
		os.Exit(1)
	}

	state[place.Y][place.X] = parseStone(parts[2])

	stateChan <- state
}

func parseStone(str string) placeState {
	switch str {
	case "b":
		return stateBlack
	case "B":
		return stateBlackSelected
	case "w":
		return stateWhite
	case "W":
		return stateWhiteSelected
	case "e":
		return stateEmpty
	}
	fmt.Printf("error: Invalid set command: %q\n", str)
	os.Exit(1)
	return stateEmpty
}

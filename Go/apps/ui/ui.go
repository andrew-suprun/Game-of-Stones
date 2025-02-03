package main

import (
	"bufio"
	"fmt"
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

	. "game_of_stones/common"
	"game_of_stones/game"
)

const (
	windowSize = 800
)

var (
	colorBg       = color.NRGBA{127, 106, 79, 255}
	colorSelected = color.NRGBA{255, 127, 127, 255}
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

var gameName string = "connect6"
var maxSelected int = 1

type state struct {
	places     [game.Size][game.Size]placeState
	respond    bool
	turn       Turn
	n_selected int
}

func main() {
	go run()
	app.Main()
}

func run() {
	if len(os.Args) > 1 && os.Args[1] == "gomoku" {
		gameName = "gomoku"
		maxSelected = 2
	}
	gameState := state{}
	stateChan := make(chan *state, 1)
	stateChan <- &gameState

	var ops op.Ops

	window := new(app.Window)
	window.Option(app.Title(gameName), app.Size(windowSize, windowSize))
	// window.Option(app.Decorated(false))

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
	d := size / (game.Size + 1)
	r := d / 2

	paint.Fill(ops, colorBg)

	for i := 1; i <= game.Size; i++ {
		paint.FillShape(ops, colorBlack, clip.Stroke{
			Path:  clip.Rect{Min: image.Point{X: d, Y: i * d}, Max: image.Point{X: game.Size * d, Y: i * d}}.Path(),
			Width: 1,
		}.Op())
		paint.FillShape(ops, colorBlack, clip.Stroke{
			Path:  clip.Rect{Min: image.Point{X: i * d, Y: d}, Max: image.Point{X: i * d, Y: game.Size * d}}.Path(),
			Width: 1,
		}.Op())
	}

	for y := range game.Size {
		for x := range game.Size {
			for {
				_, ok := ev.Source.Event(pointer.Filter{
					Target: &state.places[y][x],
					Kinds:  pointer.Press,
				})
				if !ok {
					break
				}
				place := state.places[y][x]
				if state.respond {
					if state.turn == First {
						if place == stateBlackSelected {
							state.places[y][x] = stateEmpty
							state.n_selected--
						} else if place == stateEmpty && state.n_selected < maxSelected {
							state.places[y][x] = stateBlackSelected
							state.n_selected++
						}
					} else {
						if place == stateWhiteSelected {
							state.places[y][x] = stateEmpty
							state.n_selected--
						} else if place == stateEmpty && state.n_selected < maxSelected {
							state.places[y][x] = stateWhiteSelected
							state.n_selected++
						}
					}
				}
			}
			stack := clip.Rect{Min: image.Point{X: (x+1)*d - r, Y: (y+1)*d - r}, Max: image.Point{X: (x+1)*d + r, Y: (y+1)*d + r}}.Push(ops)
			event.Op(ops, &state.places[y][x])
			stack.Pop()

			var stoneColor color.NRGBA
			switch state.places[y][x] {
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

			if state.places[y][x] == stateBlackSelected || state.places[y][x] == stateWhiteSelected {
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
				if state.respond && state.n_selected == maxSelected {
					selected := []game.Place{}
					for x := range game.Size {
						for y := range game.Size {
							switch state.places[y][x] {
							case stateBlackSelected:
								state.places[y][x] = stateBlack
								if state.turn == First {
									selected = append(selected, game.Place{X: int8(x), Y: int8(y)})
								}
							case stateWhiteSelected:
								state.places[y][x] = stateWhite
								if state.turn == Second {
									selected = append(selected, game.Place{X: int8(x), Y: int8(y)})
								}
							}
						}
					}
					move := game.Move{P1: selected[0], P2: selected[0]}
					if maxSelected == 2 {
						move = game.Move{P1: selected[0], P2: selected[1]}
					}
					state.respond = false
					state.n_selected = 0
					if state.turn == First {
						state.turn = Second
					} else {
						state.turn = First
					}
					fmt.Printf("move %s\n", move)
				}
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
		if strings.HasPrefix(text, "game-kind") {
			gameName = strings.Fields(text)[1]
		}
		if strings.HasPrefix(text, "move ") {
			playMove(stateChan, text)
		}
		if strings.HasPrefix(text, "respond") {
			state := <-stateChan
			state.respond = true
			stateChan <- state
		}
		if strings.HasPrefix(text, "clear") {
			state := <-stateChan
			for y := range game.Size {
				for x := range game.Size {
					state.places[y][x] = stateEmpty
				}
			}

			state.respond = true
			stateChan <- state
		}
		window.Invalidate()
	}
}

func playMove(stateChan chan *state, cmd string) {
	terms := strings.Fields(cmd)
	if len(terms) < 2 {
		fmt.Printf("error: Invalid move command: %q\n", cmd)
		os.Exit(1)
	}
	move, err := game.ParseMove(terms[1])
	if err != nil {
		fmt.Printf("error: Invalid move command: %q\n", cmd)
		os.Exit(1)
	}

	state := <-stateChan
	for y := range game.Size {
		for x := range game.Size {
			switch state.places[y][x] {
			case stateBlackSelected:
				state.places[y][x] = stateBlack
			case stateWhiteSelected:
				state.places[y][x] = stateWhite
			}
		}
	}

	maxStones := 5
	if gameName == "connect6" {
		maxStones = 6
	}
	if state.turn == First {
		state.places[move.P1.Y][move.P1.X] = stateBlack
		state.places[move.P2.Y][move.P2.X] = stateBlack
	} else {
		state.places[move.P1.Y][move.P1.X] = stateWhite
		state.places[move.P2.Y][move.P2.X] = stateWhite
	}

	xx, yy, dx, dy := 0, 0, 0, 0

	for y := range game.Size {
		for x := range game.Size {
			if x <= game.Size-maxStones {
				b, w := 0, 0
				for i := range maxStones {
					if state.places[y][x+i] == stateBlack {
						b++
						if b == maxStones {
							xx, yy, dx, dy = x, y, 1, 0
						}
					} else if state.places[y][x+i] == stateWhite {
						w++
						if w == maxStones {
							xx, yy, dx, dy = x, y, 1, 0
						}
					}
				}
			}
			if y <= game.Size-maxStones {
				b, w := 0, 0
				for i := range maxStones {
					if state.places[y+i][x] == stateBlack {
						b++
						if b == maxStones {
							xx, yy, dx, dy = x, y, 0, 1
						}
					} else if state.places[y+i][x] == stateWhite {
						w++
						if w == maxStones {
							xx, yy, dx, dy = x, y, 0, 1
						}
					}
				}
			}
			if x <= game.Size-maxStones && y <= game.Size-maxStones {
				b, w := 0, 0
				for i := range maxStones {
					if state.places[y+i][x+i] == stateBlack {
						b++
						if b == maxStones {
							xx, yy, dx, dy = x, y, 1, 1
						}
					} else if state.places[y+i][x+i] == stateWhite {
						w++
						if w == maxStones {
							xx, yy, dx, dy = x, y, 1, 1
						}
					}
				}
			}
			if x >= maxStones-1 && y <= game.Size-maxStones {
				b, w := 0, 0
				for i := range maxStones {
					if state.places[y+i][x-i] == stateBlack {
						b++
						if b == maxStones {
							xx, yy, dx, dy = x, y, -1, 1
						}
					} else if state.places[y+i][x-i] == stateWhite {
						w++
						if w == maxStones {
							xx, yy, dx, dy = x, y, -1, 1
						}
					}
				}
			}
		}
	}

	if dx != 0 || dy != 0 {
		for i := range maxStones {
			switch state.places[yy+dy*i][xx+dx*i] {
			case stateBlack:
				state.places[yy+dy*i][xx+dx*i] = stateBlackSelected
			case stateWhite:
				state.places[yy+dy*i][xx+dx*i] = stateWhiteSelected
			}
		}
	}

	if state.turn == First {
		state.places[move.P1.Y][move.P1.X] = stateBlackSelected
		state.places[move.P2.Y][move.P2.X] = stateBlackSelected
		state.turn = Second
	} else {
		state.places[move.P1.Y][move.P1.X] = stateWhiteSelected
		state.places[move.P2.Y][move.P2.X] = stateWhiteSelected
		state.turn = First
	}

	state.respond = false
	stateChan <- state
}

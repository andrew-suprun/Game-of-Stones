package main

import (
	"fmt"
	"os"
	"text/template"
)

const tmpl = `// Code generated by 'go generate game_of_stones/...'. DO NOT EDIT.

//go:build {{.Game}}

package board

const (
	maxStones = {{.MaxStones}}
	WinValue  = {{.WinValue}}
)

func valueStones(stone, stones Stone) (int16, int16) {
	if stone == Black {
		switch stones {
{{ range .BlackCases }}		case {{.Stones | printf "0x%02x"}}:
			return {{.BlackValue}}, {{.WhiteValue}}
{{ end }}		}
	} else {
		switch stones {
{{ range .WhiteCases }}		case {{.Stones | printf "0x%02x"}}:
			return {{.BlackValue}}, {{.WhiteValue}}
{{ end }}		}
	}
	return 0, 0
}
`

const testTmpl = `// Code generated by 'go generate game_of_stones/...'. DO NOT EDIT.

//go:build {{.Game}} && debug

package board

func debugStonesValues(stones Stone) (int16, int16) {
	switch stones {
{{ range .TestCases }}	case {{.Stones | printf "0x%02x"}}:
		return {{.BlackValue}}, {{.WhiteValue}}
{{ end }}
	}
	return 0, 0
}

func debugStonesValue(stones Stone) int16 {
	switch stones {
{{ range .ScoreCases }}	case {{.Stones | printf "0x%02x"}}:
		return {{.BlackValue}}
{{ end }}
	}
	return 0
}
`

func main() {
	gen("gomoku", 0, 1, 4, 12, 24, 10_000)
	gen("connect6", 0, 1, 5, 20, 60, 120, 10_000)
}

func gen(game string, values ...int) {
	fmt.Println("Generating", game)
	data := prepareData(game, values...)

	wd, _ := os.Getwd()
	fmt.Println(wd)
	file, err := os.Create(wd + "/" + game + "_values.go")
	if err != nil {
		panic(err)
	}
	defer file.Close()
	fmt.Println(file.Name())

	tmpl := template.Must(template.New("").Parse(tmpl))
	err = tmpl.Execute(file, data)
	if err != nil {
		panic(err)
	}

	file, err = os.Create(wd + "/" + game + "_values_debug.go")
	if err != nil {
		panic(err)
	}
	defer file.Close()
	fmt.Println(file.Name())

	tmpl = template.Must(template.New("").Parse(testTmpl))
	err = tmpl.Execute(file, data)
	if err != nil {
		panic(err)
	}
}

type Data struct {
	Game       string
	MaxStones  int
	BlackCases []Case
	WhiteCases []Case
	TestCases  []Case
	ScoreCases []Case
	WinValue   int
}

type Case struct {
	Stones     int
	BlackValue int
	WhiteValue int
}

func prepareData(game string, values ...int) Data {
	data := Data{
		Game:      game,
		MaxStones: len(values) - 1,
		WinValue:  values[len(values)-1] / 2,
	}
	for i := 0; i < len(values)-2; i++ {
		data.BlackCases = append(data.BlackCases,
			Case{
				Stones:     i,
				BlackValue: values[i] + values[i+2] - 2*values[i+1],
				WhiteValue: values[i] - values[i+1],
			})
	}

	for i := 1; i < len(values)-2; i++ {
		data.BlackCases = append(data.BlackCases,
			Case{
				Stones:     i * 0x10,
				BlackValue: -values[i],
				WhiteValue: values[i+1] - values[i],
			})
	}
	data.WhiteCases = append(data.WhiteCases,
		Case{
			Stones:     0,
			BlackValue: 0,
			WhiteValue: 2*values[1] - values[0] - values[2],
		})
	for i := 1; i < len(values)-2; i++ {
		data.WhiteCases = append(data.WhiteCases,
			Case{
				Stones:     i,
				BlackValue: values[i] - values[i+1],
				WhiteValue: values[i],
			})
	}
	for i := 1; i < len(values)-2; i++ {
		data.WhiteCases = append(data.WhiteCases,
			Case{
				Stones:     i * 0x10,
				BlackValue: values[i+1] - values[i],
				WhiteValue: 2*values[i+1] - values[i] - values[i+2],
			})
	}

	data.BlackCases[0].WhiteValue = 0

	// Test values
	data.TestCases = append(data.TestCases, Case{
		Stones:     0,
		BlackValue: 1,
		WhiteValue: -1,
	})
	for i := 1; i < len(values)-1; i++ {
		data.TestCases = append(data.TestCases, Case{
			Stones:     i,
			BlackValue: values[i+1] - values[i],
			WhiteValue: -values[i],
		})
	}
	for i := 1; i < len(values)-1; i++ {
		data.TestCases = append(data.TestCases, Case{
			Stones:     i * 0x10,
			BlackValue: values[i],
			WhiteValue: values[i] - values[i+1],
		})
	}
	// Score cases
	for i := 1; i < len(values); i++ {
		data.ScoreCases = append(data.ScoreCases, Case{
			Stones:     i,
			BlackValue: values[i],
		})
	}
	for i := 1; i < len(values); i++ {
		data.ScoreCases = append(data.ScoreCases, Case{
			Stones:     i * 0x10,
			BlackValue: -values[i],
		})
	}

	return data
}

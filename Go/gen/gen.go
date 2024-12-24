package main

import (
	"fmt"
	"os"
	"text/template"
)

const tmpl = `// Code generated by 'go generate game_of_stones/gen'. DO NOT EDIT.

//go:build {{.Game}}

package board

import "game_of_stones/score"

const (
	maxStones = {{.MaxStones}}
)

func scoreStones(stone, stones Stone) (score.Score, score.Score) {
	if stone == Black {
		switch stones {
{{ range .BlackCases }}		case {{.Stones | printf "0x%02x"}}:
			return {{.BlackScore}}, {{.WhiteScore}}
{{ end }}		}
	} else {
		switch stones {
{{ range .WhiteCases }}		case {{.Stones | printf "0x%02x"}}:
			return {{.BlackScore}}, {{.WhiteScore}}
{{ end }}		}
	}
	return 0, 0
}
`

const testTmpl = `// Code generated by 'go generate game_of_stones/gen'. DO NOT EDIT.

//go:build {{.Game}} && debug

package board

import "game_of_stones/score"

func debugScoreStones(stones Stone) (score.Score, score.Score) {
	switch stones {
{{ range .TestCases }}	case {{.Stones | printf "0x%02x"}}:
		return {{.BlackScore}}, {{.WhiteScore}}
{{ end }}
	}
	return 0, 0
}
`

func main() {
	gen("gomoku", 0, 2, 16, 96, 384, 100_672)
	gen("connect6", 0, 2, 16, 96, 384, 672, 100_960)
}

func gen(game string, scores ...int) {
	data := prepareData(game, scores...)

	wd, _ := os.Getwd()
	fmt.Println(wd)
	file, err := os.Create(wd + "/" + game + "_scores.go")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	tmpl := template.Must(template.New("").Parse(tmpl))
	err = tmpl.Execute(file, data)
	if err != nil {
		panic(err)
	}

	file, err = os.Create(wd + "/" + game + "_scores_debug.go")
	if err != nil {
		panic(err)
	}
	defer file.Close()

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
}

type Case struct {
	Stones     int
	BlackScore int
	WhiteScore int
}

func prepareData(game string, scores ...int) Data {
	data := Data{Game: game, MaxStones: len(scores) - 1}
	for i := 0; i < len(scores)-2; i++ {
		data.BlackCases = append(data.BlackCases,
			Case{
				Stones:     i,
				BlackScore: scores[i] + scores[i+2] - 2*scores[i+1],
				WhiteScore: scores[i] - scores[i+1],
			})
	}

	for i := 1; i < len(scores)-2; i++ {
		data.BlackCases = append(data.BlackCases,
			Case{
				Stones:     i * 0x10,
				BlackScore: -scores[i],
				WhiteScore: scores[i+1] - scores[i],
			})
	}
	data.WhiteCases = append(data.WhiteCases,
		Case{
			Stones:     0,
			BlackScore: 0,
			WhiteScore: 2*scores[1] - scores[0] - scores[2],
		})
	for i := 1; i < len(scores)-2; i++ {
		data.WhiteCases = append(data.WhiteCases,
			Case{
				Stones:     i,
				BlackScore: scores[i] - scores[i+1],
				WhiteScore: scores[i],
			})
	}
	for i := 1; i < len(scores)-2; i++ {
		data.WhiteCases = append(data.WhiteCases,
			Case{
				Stones:     i * 0x10,
				BlackScore: scores[i+1] - scores[i],
				WhiteScore: 2*scores[i+1] - scores[i] - scores[i+2],
			})
	}

	data.BlackCases[0].WhiteScore = 0

	// Test scores
	data.TestCases = append(data.TestCases, Case{
		Stones:     0,
		BlackScore: 2,
		WhiteScore: -2,
	})
	for i := 1; i < len(scores)-1; i++ {
		data.TestCases = append(data.TestCases, Case{
			Stones:     i,
			BlackScore: scores[i+1] - scores[i],
			WhiteScore: -scores[i],
		})
	}
	for i := 1; i < len(scores)-1; i++ {
		data.TestCases = append(data.TestCases, Case{
			Stones:     i * 0x10,
			BlackScore: scores[i],
			WhiteScore: scores[i] - scores[i+1],
		})
	}

	return data
}
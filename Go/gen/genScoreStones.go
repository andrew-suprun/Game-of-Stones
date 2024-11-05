package main

import (
	"os"
	"text/template"
)

const tmpl = `func scoreStones(stone, stones Stone) (Score, Score) {
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

func main() {
	// data := prepareData(0, 1, 8, 56, 336, 100616)
	data := prepareData(0, 1, 8, 56, 336, 1680, 103024)
	tmpl := template.Must(template.New("").Parse(tmpl))
	err := tmpl.Execute(os.Stdout, data)
	if err != nil {
		panic(err)
	}
}

type Data struct {
	BlackCases []Case
	WhiteCases []Case
}

type Case struct {
	Stones     int
	BlackScore int
	WhiteScore int
}

func prepareData(scores ...int) Data {
	data := Data{}
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
	return data
}

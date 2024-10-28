package main

import (
	"fmt"
	"os"
	"text/template"
)

const tmpl = `func scoreStones(stone, stones Stone, coeff Score) (Score, Score, Stone) {
	if stone == Black {
		switch stones {
{{ range .BlackCases }}		case {{.Stones | printf "0x%02x"}}:
			return {{.BlackScore}}, {{.WhiteScore}}, {{.Winner}}
{{ end }}		}
	} else {
		switch stones {
{{ range .WhiteCases }}		case {{.Stones | printf "0x%02x"}}:
			return {{.BlackScore}}, {{.WhiteScore}}, {{.Winner}}
{{ end }}		}
	}
	return 0, 0, None
}
`

func main() {
	// data := prepareData(0, 1, 8, 56, 336, 1680)
	data := prepareData(0, 1, 8, 56, 336, 1680, 6720)
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
	BlackScore string
	WhiteScore string
	Winner     string
}

func prepareData(scores ...int) Data {
	data := Data{}
	for i := 0; i < len(scores)-2; i++ {
		data.BlackCases = append(data.BlackCases,
			Case{
				Stones:     i,
				BlackScore: toString(scores[i] + scores[i+2] - 2*scores[i+1]),
				WhiteScore: toString(scores[i] - scores[i+1]),
				Winner:     "None",
			})
	}
	data.BlackCases = append(data.BlackCases,
		Case{
			Stones:     len(scores) - 2,
			BlackScore: "0",
			WhiteScore: "0",
			Winner:     "Black",
		})

	for i := 1; i < len(scores)-2; i++ {
		data.BlackCases = append(data.BlackCases,
			Case{
				Stones:     i * 0x10,
				BlackScore: toString(-scores[i]),
				WhiteScore: toString(scores[i+1] - scores[i]),
				Winner:     "None",
			})
	}
	data.WhiteCases = append(data.WhiteCases,
		Case{
			Stones:     0,
			BlackScore: "0",
			WhiteScore: toString(2*scores[1] - scores[0] - scores[2]),
			Winner:     "None",
		})
	for i := 1; i < len(scores)-2; i++ {
		data.WhiteCases = append(data.WhiteCases,
			Case{
				Stones:     i,
				BlackScore: toString(scores[i] - scores[i+1]),
				WhiteScore: toString(scores[i]),
				Winner:     "None",
			})
	}
	for i := 1; i < len(scores)-2; i++ {
		data.WhiteCases = append(data.WhiteCases,
			Case{
				Stones:     i * 0x10,
				BlackScore: toString(scores[i+1] - scores[i]),
				WhiteScore: toString(2*scores[i+1] - scores[i] - scores[i+2]),
				Winner:     "None",
			})
	}
	data.WhiteCases = append(data.WhiteCases,
		Case{
			Stones:     (len(scores) - 2) * 0x10,
			BlackScore: "0",
			WhiteScore: "0",
			Winner:     "White",
		})

	data.BlackCases[0].WhiteScore = "0"
	return data
}

func toString(v int) string {
	switch v {
	case 0:
		return "0"
	case 1:
		return "coeff"
	case -1:
		return "-coeff"
	}
	return fmt.Sprintf("%d * coeff", v)
}

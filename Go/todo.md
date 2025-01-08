* generalize UI
* benchmark tree search
* Julia
* enrich UI

go run -tags connect6 game_of_stones/ui
go run -tags connect6 game_of_stones/sim -a=22,64,20,500 -b=22,64,20,1000
go test -tags connect6 game_of_stones/...

go build -o out/ui -tags gomoku apps/ui/ui.go
go build -o out/game_of_stones -tags gomoku apps/game_of_stones/game_of_stones.go
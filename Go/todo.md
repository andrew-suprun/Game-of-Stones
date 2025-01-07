* generalize UI
* benchmark tree search
* Julia
* enrich UI

go run -tags connect6 game_of_stones/ui
go run -tags connect6 game_of_stones/sim -a=22,64,20,500 -b=22,64,20,1000
go test -tags connect6 game_of_stones/...
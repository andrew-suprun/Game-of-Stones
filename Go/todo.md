* generalize UI
* benchmark tree search
* Julia
* enrich UI

go run game_of_stones/ui
go run game_of_stones/sim -a=22,64,20,500 -b=22,64,20,1000
go test game_of_stones/...

go build -o out/ui apps/ui/ui.go
go build -o out/game_of_stones apps/game_of_stones/*.go
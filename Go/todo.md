Go:
* rework gomoku opening moves
* refresh Game of Stones
* run multiple sims

Julia:
* keep subtree if possible in tree.CommitMove()
* engine

go run game_of_stones/ui
go run -tags=connect6 game_of_stones/sim -a=22,64,20,500 -b=22,64,20,1000
go test game_of_stones/...

go build -o out/game_of_stones apps/game_of_stones/*.go && out/game_of_stones -game=connect6 -stones=black

go build -o out/sim apps/sim/*.go
go build -o out/ui apps/ui/ui.go

go build -o out/gomoku -tags=gomoku apps/engine/*.go
out/sim "gomoku -log=black.log" "gomoku -log=white.log"

go build -o out/connect6 -tags=connect6 apps/engine/*.go
out/sim connect6 connect6

go generate game_of_stones/...
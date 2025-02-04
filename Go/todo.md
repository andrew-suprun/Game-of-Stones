Go:
* refresh Game of Stones

Julia:
* keep subtree if possible in tree.CommitMove()
* engine

go test game_of_stones/...

go build -o out/game_of_stones apps/game_of_stones/*.go && out/game_of_stones -game=connect6 -stones=black

go build -o out/sim apps/sim/*.go
go build -o out/ui apps/ui/ui.go
go build -o out/gomoku -tags=gomoku apps/engine/*.go
go build -o out/connect6 -tags=connect6 apps/engine/*.go

out/sim 500 "gomoku -log=black.log" "gomoku -log=white.log"
out/sim 2000 "connect6 -log=black.log" "connect6 -log=white.log"

"connect6 -places=16 -moves=64 -C=32"
"gomoku -C=24 -places=16"

out/sim 500 "gomoku -C=28 -places=18" "gomoku -C=32 -places=18"

go generate game_of_stones/...


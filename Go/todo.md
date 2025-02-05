Julia:
* modularize
* keep subtree if possible in tree.CommitMove()
* engine

go test game_of_stones/...

go build -o out/game_of_stones apps/game_of_stones/*.go && out/game_of_stones -game=connect6 -spm=0.1

go build -o out/game-of-stones apps/game_of_stones/game_of_stones.go
go build -o out/ui apps/ui/ui.go
go build -o out/gomoku -tags=gomoku apps/engine/*.go
go build -o out/connect6 -tags=connect6 apps/engine/*.go

out/game_of_stones -engine=connect6 -spm=0.1


go generate game_of_stones/...


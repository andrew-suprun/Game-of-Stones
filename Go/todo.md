Go:
* PlayMove should return Decision
* split Game struct into Board, Gomoku and Connect6
* use copy of Board in tree.Expand()


go test game_of_stones/...

go build -o out/game_of_stones apps/game_of_stones/*.go && out/game_of_stones -game=connect6 -spm=0.1

go build -o out/sim apps/sim/sim.go
go build -o out/ui apps/ui/ui.go
go build -o out/game-of-stones apps/game_of_stones/game_of_stones.go
go build -o out/go-gomoku -tags=gomoku apps/engine/*.go
go build -o out/go-connect6 -tags=connect6 apps/engine/*.go

out/game-of-stones -engine=connect6 -spm=0.1
out/game-of-stones -engine=../../Julia/gomoku.jl

out/sim 250 gomoku ../../Julia/gomoku.jl

go generate game_of_stones/...


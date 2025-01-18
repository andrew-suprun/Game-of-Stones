include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_show.jl")

@show game_values(Val(:Gomoku), Val(:First), 1 + 2)
@show game_values(Val(:Gomoku), Val(:Second), 1 + 2 * 6)
@show game_values(Val(:Connect6), Val(:First), 1 + 3)
@show game_values(Val(:Connect6), Val(:Second), 1 + 3 * 6)

game = Game(Val(:Gomoku))
println(game.values)
place_stone!(game, Val(:Gomoku), Place(1, 1), 1)
println(board_value(game, Val(:Gomoku)))
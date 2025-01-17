include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_show.jl")

@show game_values(Gomoku(), First(), 1 + 2)
@show game_values(Gomoku(), Second(), 1 + 2 * 6)
@show game_values(Connect6(), First(), 1 + 3)
@show game_values(Connect6(), Second(), 1 + 3 * 6)

game = Game(Gomoku())
println(game.values)
place_stone(game, Place(1, 1), 1)
println(board_value(game))
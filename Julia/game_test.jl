include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_show.jl")

# @show game_values(Gomoku(), First(), Int8(1 + 2))
# @show game_values(Gomoku(), Second(), Int8(1 + 2 * 6))
# @show game_values(Connect6(), First(), Int8(1 + 3))
# @show game_values(Connect6(), Second(), Int8(1 + 3 * 6))

game = Game(Gomoku())
place_stone(game, Place(1, 1), Int16(1))
println(board_value(game))
include("interface.jl")
include("game.jl")
include("game_values.jl")

@show values(Gomoku(), First(), Int8(1 + 2))
@show values(Gomoku(), Second(), Int8(1 + 2 * 6))
@show values(Connect6(), First(), Int8(1 + 3))
@show values(Connect6(), Second(), Int8(1 + 3 * 6))

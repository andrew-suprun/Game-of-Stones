include("interface.jl")
include("game.jl")
include("game_values.jl")

value(Gomoku(), First(), Int8(1))
value(Gomoku(), Second(), Int8(1))
value(Connect6(), Second(), Int8(1))

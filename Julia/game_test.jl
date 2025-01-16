include("interface.jl")
include("game.jl")
include("value.jl")

value(Gomoku(), First())
value(Gomoku(), Second())
value(Connect6(), Second())

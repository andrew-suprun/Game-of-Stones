include("interface.jl")
include("tree.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")

tree = Tree{Move}(200.0)
game = Game(connect6)
play_move!(game, Move(Place(10, 10)))
play_move!(game, Move(Place(9, 9), Place(9, 11)))
println(game)



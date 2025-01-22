include("interface.jl")
include("tree.jl")
include("game.jl")
include("game_values.jl")

tree = Tree{Move}(20.0)
game = Game(gomoku)
expand(tree, game)
commit_move!(tree, game, "j10")



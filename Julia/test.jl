include("interface.jl")
include("tree.jl")
include("game.jl")

tree = Tree{Move}(3, 20.0)
game = Game(:Gomoku)
expand(tree, game)
commit_move(tree, game, "j10")



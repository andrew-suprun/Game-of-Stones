include("interface.jl")
include("tree.jl")
include("game.jl")

struct TestMove end
struct TestGame end
isdecisive(::TestMove) = false


tree = Tree{TestMove}(3, 20.0)
game = Game(Black, First())
expand(tree, game)


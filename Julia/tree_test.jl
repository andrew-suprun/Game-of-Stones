include("interface.jl")
include("tree.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")

tree = Tree{Move}(200.0)
game = Game(connect6)
play_move!(game, Move(Place(10, 10)))
play_move!(game, Move(Place(9, 9), Place(9, 11)))
println(game.stones)
while true
    for i in 1:10_000
        expand!(tree, game)
        root = tree.nodes[1]
        if root.decision != no_decision
            println("decision: $(root.decision) $(root.n_sims)")
            break
        end
    end
    move = best_move(tree, game)
    commit_move!(tree, game, "$move")
    println("move $move")
    println(game.stones)
    dec = decision(game)
    if dec[1] != no_decision
        println(dec)
        break
    end
end



include("interface.jl")
include("tree.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")


function run_simulation(tree, game)
    println(game.stones)
    while true
        for i in 1:20_000
            expand!(tree, game)
            root = tree.nodes[1]
            if root.decision != no_decision
                println("decision: $(root.decision) $(root.n_sims)")
                # for i in root.first_child:root.last_child
                #     println("  $(tree.moves[i]): $(tree.nodes[i])")
                # end
                break
            end
        end
        move = best_move(tree, game)
        println("move $move stone $(game.stone)")
        commit_move!(tree, game, "$move")
        println(game.stones)
        dec = decision(game)
        if dec[1] != no_decision
            println(dec)
            break
        end
    end
end

begin
    tree = Tree{Move}(100.0)
    game = Game(gomoku)
    commit_move!(tree, game, "j10")
    commit_move!(tree, game, "i9")
    run_simulation(tree, game)
end

begin
    tree = Tree{Move}(100.0)
    game = Game(connect6)
    commit_move!(tree, game, "j10")
    commit_move!(tree, game, "i9-i11")
    run_simulation(tree, game)
end
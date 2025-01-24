function run_server(name)
    tree = Tree{Move}(20.0)
    game = Game(name)
    println(stderr, game.stones)
    while true
        line = readline()
        terms = split(line)
        if terms[1] == "move"
            commit_move!(tree, game, terms[2])
            println(stderr, game.stones)
        elseif terms[1] == "respond"
            for i in 1:10_000
                cont = expand!(tree, game)
                if game.stone == black && tree.root.decision == black_win
                    println(stderr, "decision: Black win after $i expands")
                    break
                elseif game.stone == white && tree.root.decision == white_win
                    println(stderr, "decision: White win after $i expands")
                    break
                end
                if !cont
                    println(stderr, "decision: single undecided after $i expands")
                    break
                end
            end
            move = best_move(tree, game)
            println(stderr, "move: $move, turn: $(game.stone) dec: $(tree.root.decision)")
            commit_move!(tree, game, "$move")
            println(stderr, game.stones)
            println("move $move")
            term = isterminal(game)
            if !isnothing(term)
                println(stderr, term)
                # println("terminal $(term[1]) $(term[2]) $(term[3]) $(term[4])")
                println("terminal $(join(term, " "))")
                break
            end
        elseif terms[1] == "stop"
            break
        end
    end
end

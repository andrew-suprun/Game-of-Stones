using Dates

function run_engine(name)
    tree = Tree{Move}(20.0)
    game = Game(name)
    println(stderr, game.stones)
    while true
        line = strip(readline())
        println(stderr, "engine read `$line`")
        if line == ""
            continue
        end
        terms = split(line)
        if terms[1] == "game-name"
            println("game-name $name")
        elseif terms[1] == "move"
            commit_move!(tree, game, terms[2])
            println(stderr, game.stones)
        elseif terms[1] == "respond"
            expand!(tree, game)
            millis = parse(Int, terms[2])
            deadline = now() + Millisecond(millis)

            while true
                dec, done = expand!(tree, game)
                if done || dec != no_decision || now() > deadline
                    break
                end
            end

            move = best_move(tree, game)
            println(stderr, "move: $move")
            println("move $move")
            commit_move!(tree, game, "$move")
            println(stderr, game.stones)
        elseif terms[1] == "decision"
            println("decision $(decision(game))")
        elseif terms[1] == "stop"
            break
        end
    end
end

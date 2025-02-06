using Dates

function run_engine(name)
    tree = Tree{Move}(20.0)
    game = Game(name)
    while true
        line = strip(readline())
        if line == ""
            continue
        end
        terms = split(line)
        if terms[1] == "game-name"
            println("game-name $name")
        elseif terms[1] == "move"
            commit_move!(tree, game, terms[2])
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
            println("move $move")
            commit_move!(tree, game, "$move")
        elseif terms[1] == "decision"
            dec = decision(game)
            println("decision $(string(dec))")
        elseif terms[1] == "stop"
            break
        end
    end
end

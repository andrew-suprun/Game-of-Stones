using Printf

Base.show(io::IO, place::Place) = print(io, "$(place.x+'a'-1)$(place.y)")
Base.show(io::IO, move::Move) = print(io, move.p1 == move.p2 ? "$(move.p1)" : "$(move.p1)-$(move.p2)")

function Base.show(io::IO, stones::Matrix{Stone})
    print(io, "  ")
    for i in 0:board_size-1
        @printf io " %c" i + 'a'
    end
    println(io)
    for y in 1:board_size
        @printf io "%2d" y
        for x in 1:board_size
            stone = stones[x, y]
            if stone == black
                if x == 1
                    print(io, " X")
                else
                    print(io, "─X")
                end
            elseif stone == white
                if x == 1
                    print(io, " O")
                else
                    print(io, "─O")
                end
            else
                if y == 1
                    if x == 1
                        print(io, " ┌")
                    elseif x == board_size
                        print(io, "─┐")
                    else
                        print(io, "─┬")
                    end
                elseif y == board_size
                    if x == 1
                        print(io, " └")
                    elseif x == board_size
                        print(io, "─┘")
                    else
                        print(io, "─┴")
                    end
                else
                    if x == 1
                        print(io, " ├")
                    elseif x == board_size
                        print(io, "─┤")
                    else
                        print(io, "─┼")
                    end
                end
            end
        end
        @printf io " %2d\n" y
    end
    print(io, "  ")
    for i in 0:board_size-1
        @printf io " %c" i + 'a'
    end
end

function Base.show(io::IO, game::Game)
    println(game.stones)
    println()
    print_game_values(io, game, 1, false)
    print_game_values(io, game, 2, true)
end

function print_game_values(io, game, idx, footer)
    values = game.values
    print(io, "   │")
    for i in 0:board_size-1
        @printf io " %c %2d │" i + 'a' i + 1
    end
    println(io, "\n", "───┼", "──────┼"^19, "───")

    for y in 1:board_size
        @printf(io, "%2d │", y)
        for x in 1:board_size
            if game.stones[x, y] == black
                print(io, "    X │")
            elseif game.stones[x, y] == white
                print(io, "    O │")
            else
                value = values[idx, x, y]
                if value == 0
                    print(io, " Draw │")
                elseif value >= win_value
                    print(io, " WinX │")
                elseif value <= -win_value
                    print(io, " WinO │")
                else
                    @printf(io, "%5d │", values[idx, x, y])
                end
            end
        end

        @printf(io, " %2d", y)
        println(io)
    end
    println(io, "───┼", "──────┼"^19, "───")

    if footer
        print(io, "   │")
        for i in 0:board_size-1
            @printf io " %c %2d │" i + 'a' i + 1
        end
    end
end

function Base.show(io::IO, values::Array{Int16,3})
    print_values(io, values, 1, false)
    print_values(io, values, 2, true)
end

function print_values(io, values, idx, footer)
    print(io, "   │")
    for i in 0:board_size-1
        @printf io " %c %2d │" i + 'a' i + 1
    end
    println(io, "\n───┼", "──────┼"^19, "───")

    for y in 1:board_size
        @printf(io, "%2d │", y)
        for x in 1:board_size
            @printf(io, "%5d │", values[idx, x, y])
        end

        @printf(io, " %2d", y)
        println(io)
    end
    println(io, "───┼", "──────┼"^19, "───")

    if footer
        print(io, "   │")
        for i in 0:board_size-1
            @printf io " %c %2d │" i + 'a' i + 1
        end
    end
end
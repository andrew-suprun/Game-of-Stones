using Test
using Random
using Printf

include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")

const Gomoku = Val(:Gomoku)
const Connect6 = Val(:Connect6)



# @show game_values(Gomoku, Val(:First), 1 + 2)
# @show game_values(Gomoku, Val(:Second), 1 + 2 * 6)
# @show game_values(Connect6, Val(:First), 1 + 3)
# @show game_values(Connect6, Val(:Second), 1 + 3 * 6)



function test_board_values()
    Random.seed!(1)
    game = Game(Connect6)

    stones = [None, None, None, None, Black, White]
    for y in 1:board_size
        for x in 1:board_size
            game.stones[x, y] = rand(stones)
        end
    end

    v = board_values(game, Connect6)
    # println(game.stones)
    # println(v)

    for y in 1:board_size
        for x in 1:board_size
            if game.stones[x, y] != 0
                continue
            end
            orig = board_value(game, Connect6)
            game.stones[x, y] = Black
            vb = board_value(game, Connect6)
            if v[1, x, y] != vb - orig
                @printf("Failed:X %d:%d expected  %d  got %d\n", x, y, vb - orig, v[1, x, y])
                return false
            end
            game.stones[x, y] = White
            vw = board_value(game, Connect6)
            if v[2, x, y] != vw - orig
                @printf("Failed:Y %d:%d expected  %d  got %d\n", x, y, vw - orig, v[2, x, y])
                return false
            end
            game.stones[x, y] = None
        end
    end
    return true
end

@test test_board_values()


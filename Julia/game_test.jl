using Test
using Random

include("interface.jl")
include("game.jl")
include("game_values.jl")
include("game_printer.jl")

function test_board_values(name)
    Random.seed!(1)
    game = Game(name)

    stones = [None, None, None, None, Black, White]
    for y in 1:board_size, x in 1:board_size
        game.stones[x, y] = rand(stones)
    end

    v = board_values(game, name)
    # println(game.stones)
    # println(v)

    for y in 1:board_size, x in 1:board_size
        if game.stones[x, y] != 0
            continue
        end
        orig = board_value(game, name)
        game.stones[x, y] = Black
        vb = board_value(game, name)
        if v[1, x, y] != vb - orig
            println("Failed:X $x:$y expected  $(vb - orig)  got $(v[1, x, y])")
            return false
        end
        game.stones[x, y] = White
        vw = board_value(game, name)
        if v[2, x, y] != vw - orig
            println("Failed:Y $x:$y expected  $(vb - orig)  got $(v[2, x, y])")
            return false
        end
        game.stones[x, y] = None
    end
    return true
end

function test_place_stone(name)
    game = Game(name)

    # next_turn!(game)
    # place_stone!(game, name, Place(1, 1), 1)
    # check_values(game, name) || return false

    Random.seed!(1)
    places = Vector{Place}()
    j = 1
    for i in 1:100
        place = Place(rand(1:board_size), rand(1:board_size))
        if place in places
            continue
        end
        place_stone!(game, name, place, 1)
        check_values(game, name) || return false
        push!(places, place)
        next_turn!(game)
        j += 1
    end
    while !isempty(places)
        j -= 1
        place = pop!(places)
        next_turn!(game)
        place_stone!(game, name, place, -1)
        check_values(game, name) || return false
    end
    return true
end

function check_values(game, name)
    success = true
    v = board_values(game, name)
    for y in 1:board_size, x = 1:board_size, c = 1:2
        if game.stones[x, y] == None && v[c, x, y] != game.values[c, x, y]
            println("Failure [$c, $x, $y] expected $(v[c,x,y]) got $(game.values[c,x,y])")
            success = false
        end
    end
    if !success
        print(game)
    end
    success
end

@testset begin
    @test test_board_values(Val(:Gomoku))
    @test test_board_values(Val(:Connect6))

    @test test_place_stone(Val(:Gomoku))
    @test test_place_stone(Val(:Connect6))
end

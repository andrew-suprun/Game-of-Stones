struct Place
    x::Int8
    y::Int8
end

struct Move
    p1::Place
    p2::Place
end

Move() = Move(Place(0, 0), Place(0, 0))

const None = 0
const Black = 1
const White = 6

abstract type GameName end
struct Gomoku <: GameName end
struct Connect6 <: GameName end


mutable struct Game
    name::GameName
    turn::Turn
    turn_idx::Int
    stones::Matrix{Int8}
    values::Matrix{Tuple{Int16,Int16}}
    value::Int16
    stone::Int8
    max_stones::Int8

    function Game(name::GameName)
        stones = zeros(Int8, size, size)
        values = init_values(name)

        return name == Gomoku() ? new(name, First(), 1, stones, values, 0, Black, 5) :
               name == Connect6() ? new(name, First(), 1, stones, values, 0, Black, 6) :
               throw(ArgumentError("Game must be either Gomoku() or Connect6()"))
    end
end

function init_values(name::GameName)
    max_stones = name == Gomoku() ? 5 : 6
    values = Matrix{Tuple{Int16,Int16}}(undef, size, size)
    for y in 1:size
        v = min(max_stones, y, size + 1 - y)
        for x in 1:size
            h = min(max_stones, x, size + 1 - x)
            m = min(x, y, size - x, size - y)
            t1 = max(0, min(max_stones, m, size - max_stones - y + x, size - max_stones - x + y))
            t2 = max(0, min(max_stones, m, 2 * size - max_stones - y - x, x + y - max_stones))
            # h = 0
            # v = 0
            # t1 = 0
            total = v + h + t1 + t2
            values[x, y] = (total, -total)
        end
    end
    values
end

function play_move(game::Game, move::Move)
    place_stone(game, move.p1, 1)

    if move.p1 != move.p2
        place_stone(game, move.p2, 1)
    end

    next_turn(game)

    validate(game, debug)
end

function undo_move(game::Game, move::Move)
    next_turn(game)

    if move.p1 != move.p2
        place_stone(game, move.p2, -1)
    end

    place_stone(game, move.p1, -1)

    validate(game, debug)
end

function next_turn(game::Game)
    if game.Turn == First()
        game.turn = Second()
        game.turn_idx = 2
        game.stone = White
    else
        game.turn = First()
        game.turn_idx = 1
        game.stone = Black
    end
end

function place_stone(game::Game, place::Place, coeff)
    x, y = place.x, place.y
    if coeff == 1
        game.value += game.values[x, y][game.turn_idx]
    else
        game.stones[x, y] = None
    end

    max_stones = game.max_stones
    begin
        start_x = max(1, x - max_stones)
        end_x = min(x + max_stones, size) - max_stones
        n = end_x - start_x
        update_row(game, start_x, y, 1, 0, n, coeff)
    end

    begin
        start_y = max(1, y - max_stones)
        end_y = min(y + max_stones, size) - max_stones
        n = end_y - start_y
        update_row(game, x, start_y, 0, 1, n, coeff)
    end

    m = 1 + min(x, y, size - x, size - y)

    begin
        n = min(max_stones, m, size - max_stones - y + x, size - max_stones - x + y)
        if n > 0
            mn = min(x, y, max_stones)
            xStart = x - mn + 1
            yStart = y - mn + 1
            update_row(game, xStart, yStart, 1, 1, n, coeff)
        end
    end

    begin
        n = min(max_stones, m, 2 * size - max_stones - y - x, x + y - max_stones)
        if n > 0
            mn = min(size - x, y, max_stones)
            xStart = x + mn
            yStart = y - mn
            update_row(game, xStart, yStart, -1, 1, n, coeff)
        end
    end

    if coeff == 1
        game.stones[x, y] = game.stone
    else
        game.value -= game.values[x, y][game.turn_idx]
    end
    validate(game, debug)
end

function update_row(game::Game, x, y, dx, dy, n, coeff)
    stones = 1
    for i in 1:game.max_stones
        stones += game.stones[x+i*dx, y+i*dy]
    end
    max_stones1 = game.max_stones
    @show x y
    for _ in 1:n
        stones += game.stones[x+max_stones1*dx, y+max_stones1*dy]
        values = game_values(game.name, game.turn, stones) .* coeff
        if values != (0, 0)
            for j in 0:game.max_stones
                old_values = game.values[x+j*dx, y+j*dy]
                game.values[x+j*dx, y+j*dy] = (old_values[1] + values[1], old_values[2] + values[2])
            end
        end
        stones -= game.stones[x, y]
        x += dx
        y += dy
    end
end

function board_value(game::Game)
    result = 0
    max_stones = game.max_stones
    max_stones1 = max_stones - 1
    for y in 1:size
        stones = 1
        for x in 1:max_stones1
            stones += game.stones[x, y]
        end
        for x in 1:size-game.max_stones
            stones += game.stones[x+max_stones1, y]
            result += stones_value(game.name, stones)
            stones -= game.stones[x, y]
        end
    end
    result
end

function top_moves(game::Game, moves::Vector{MoveValue{Move}}, max_moves::Int)
    error("TODO: Implement")
end

function parse_move(move::String)::Move
    tokens = split(move, '-')
    p1 = parse_place(tokens[begin])

    if length(tokens) == 1
        return Move(p1, p1)
    end
    p2 = parse_place(tokens[end])
    Move(p1, p2)
end

function parse_place(place)::Place
    if length(place) < 2 || length(place) > 3
        throw(ArgumentError("Invalid Place"))
    end
    if place[1] < 'a' || place[1] > 's'
        throw(ArgumentError("Invalid Place"))
    end
    if place[2] < '0' || place[2] > '9'
        throw(ArgumentError("Invalid Place"))
    end
    x = place[1] + 1 - 'a'
    y = place[2] - '0'
    if length(place) == 3
        if place[3] < '0' || place[3] > '9'
            throw(ArgumentError("Invalid Place"))
        end
        y = 10 * y + place[3] - '0'
    end
    y = size + 1 - y
    if x > size || y > size
        throw(ArgumentError("Invalid Place"))
    end
    Place(x, y)
end

game_values(name::Gomoku, turn::First, stones) = gomoku_first[stones]
game_values(name::Gomoku, turn::Second, stones) = gomoku_second[stones]
game_values(name::Connect6, turn::First, stones) = connect6_first[stones]
game_values(name::Connect6, turn::Second, stones) = connect6_second[stones]

stones_values(name::Connect6, stones) = connect6_values[stones]
stones_values(name::Gomoku, stones) = gomoku_values[stones]

stones_value(name::Connect6, stones) = connect6_value[stones]
stones_value(name::Gomoku, stones) = gomoku_value[stones]

function validate(game::Game, debug::Val{true})
    # TODO: Implement
    # error("TODO: Implement")
end

validate(game::Game, debug::Val{false}) = nothing

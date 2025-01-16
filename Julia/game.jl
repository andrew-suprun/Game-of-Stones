struct Place
    x::Int8
    y::Int8
end

struct Move
    p1::Place
    p2::Place
end

Move() = Move(Place(0, 0), Place(0, 0))

const None = Int8(0)
const Black = Int8(1)
const White = Int8(6)

abstract type GameName end
struct Gomoku <: GameName end
struct Connect6 <: GameName end


mutable struct Game
    name::GameName
    turn::Turn
    turn_idx::Int
    stone::Int8
    max_stones::Int8

    function Game(name::GameName)
        if name == Gomoku()
            return new(name, First(), 1, Black, 5)
        elseif name == Connect6()
            return new(name, First(), 1, Black, 6)
        else
            throw(ArgumentError("Game must be either :Gomoku or :Connect6"))
        end
    end
end

function play_move(game::Game, move::Move)
    place_stone(game, move.p1, 1)

    if move.p1 != move.p2
        place_stone(game, move.p2, 1)
    end

    next_turn(game)

    validate(debug, game)
end

function undo_move(game::Game, move::Move)
    next_turn(game)

    if move.p1 != move.p2
        place_stone(game, move.p2, -1)
    end

    place_stone(game, move.p1, -1)

    validate(debug, game)
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

function place_stone(game::Game, move::Move, coeff::Int)
    x, y = place.x, place.y
    if coeff == 1
        game.value += game.values[x, y][game.turn_idx]
    else
        game.stones[y][x] = None
    end

    begin
        start_x = max(1, x - maxStones)
        end_x = min(x + maxStones, Size) - maxStones
        n = end_x - start_x
        update_row(game, start_x, y, 1, 0, n, coeff)
    end

    begin
        start_y = max(1, y - maxStones)
        end_y = min(y + maxStones, Size) - maxStones
        n = end_y - start_y
        update_row(game, x, start_y, 0, 1, n, coeff)
    end

    m = 1 + min(x, y, Size - x, Size - y)

    begin
        n = min(maxStones, m, Size - maxStones - y + x, Size - maxStones - x + y)
        if n > 0
            mn = min(x, y, maxStones)
            xStart = x - mn
            yStart = y - mn
            update_row(game, xStart, yStart, 1, 1, n, coeff)
        end
    end

    begin
        n = min(maxStones, m, 2 * Size - maxStones - y - x, x + y - maxStones)
        if n > 0
            mn = min(Size - x, y, maxStones)
            xStart = x + mn
            yStart = y - mn
            update_row(game, xStart, yStart, -1, 1, n, coeff)
        end
    end

    if coeff == 1
        game.stones[y][x] = game.stone
    else
        game.value -= game.values[y][x][game.turn_idx]
    end
    validate(debug, game)
end

function update_row(game::Game, x::Int8, y::Int8, dx::Int8, dy::Int8, n::Int8, coeff::Int)
    stones = Int8(0)
    for i in Int8(1):game.maxStones
        stones += game.stones[y+i*dy][x+i*dx]
    end
    max_stones1 = game.max_stones
    for _ in 1:n
        stones += game.stones[y+max_stones1*dy][x+max_stones1*dx]
        values = value(game.name, game.turn, stones) .* coeff
        if values != (0, 0)
            for j in int8(0):game.maxStones
                game.values[y+j*dy][x+j*dx] .+= values
            end
        end
        stones -= game.stones[y][x]
        x += dx
        y += dy
    end
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
    x = Int8(place[1] + 1 - 'a')
    y = Int8(place[2] - '0')
    if length(place) == 3
        if place[3] < '0' || place[3] > '9'
            throw(ArgumentError("Invalid Place"))
        end
        y = 10 * y + Int8(place[3] - '0')
    end
    y = size + 1 - y
    if x > size || y > size
        throw(ArgumentError("Invalid Place"))
    end
    Place(x, y)
end
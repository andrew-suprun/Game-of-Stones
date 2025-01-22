const board_size = 19

struct MoveValue{Move}
    move::Move
    value::Int16
    isterminal::Bool
end

struct Name{x} end
Name(x) = Name{x}()
const gomoku = Name(:Gomoku)
const connect6 = Name(:Connect6)

struct Debug{x} end
Debug(x) = Debug{x}()
const debug = Debug(false)
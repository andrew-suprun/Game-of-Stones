const board_size = 19

@enum Decision::Int8 no_decision draw black_win white_win

struct MoveValue{Move}
    move::Move
    value::Int16
    terminal::Decision
end

struct Name{x} end
Name(x) = Name{x}()
const gomoku = Name(:Gomoku)
const connect6 = Name(:Connect6)

const board_size = 19

@enum Decision::Int8 no_decision draw first_win second_win

function string(decision::Decision)
    if decision == no_decision
        return "no-decision"
    elseif decision == first_win
        return "first-win"
    elseif decision == second_win
        return "second-win"
    elseif decision == draw
        return "draw"
    end
end

struct MoveValue{Move}
    move::Move
    value::Int16
    terminal::Decision
end

struct Name{x} end
Name(x) = Name{x}()
const gomoku = Name(:Gomoku)
const connect6 = Name(:Connect6)

Base.show(io::IO, ::Name{:Gomoku}) = print(io, "gomoku")
Base.show(io::IO, ::Name{:Connect6}) = print(io, "connect6")

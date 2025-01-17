using Printf

function Base.show(io::IO, values::Matrix{Tuple{Int16,Int16}})
    print_values(io, values, 1, true)
    print_values(io, values, 2, false)

end

function print_values(io::IO, values::Matrix{Tuple{Int16,Int16}}, idx::Int, header::Bool)
    if header
        print(io, "      │")
        for i in 0:size-1
            @printf io " %c %2d │" i + 'a' i + 1
        end
    end
    println(io, "\n", "──────┼"^20, "──────")

    for y in 1:size
        @printf(io, "%2d %2d │", size + 1 - y, y)
        for x in 1:size
            if values[x, y] == Black
                print(io, "    X │")
            elseif values[x, y] == White
                print(io, "    O │")
            else
                value = values[x, y][idx]
                if value == 0
                    print(io, " Draw │")
                elseif value >= win_value
                    print(io, " WinX │")
                elseif value <= -win_value
                    print(io, " WinO │")
                else
                    @printf(io, "%5d │", values[x, y][idx])
                end
            end
        end

        @printf(io, " %2d %2d", size + 1 - y, y)
        println(io)
    end
    println(io, "──────┼"^20, "──────")

    print(io, "      │")
    for i in 0:size-1
        @printf io " %c %2d │" i + 'a' i + 1
    end
end

function Base.show(io::IO, m::Matrix{Int8})
end
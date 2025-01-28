function gen(file, name, values...)

    gen_game_values(file, name, values)
    gen_values(file, name, values)
    gen_value(file, name, values)
end

Base.zero(::Type{Tuple{Int64,Int64}}) = (0, 0)

conv(v) = "($(v[1]), $(v[2]))"

function gen_game_values(file, name, values)
    println(file, "const $(name)_stone_values = Tuple{Int16,Int16}[")
    v = zeros(Tuple{Int,Int}, 8, 8)

    for i in 1:length(values)-2
        v[1, i] = (-values[i], values[i+1] - values[i])
        v[i, 1] = (values[i] + values[i+2] - 2values[i+1], values[i] - values[i+1])
    end
    v[1, 1] = (v[1, 1][1], 0)
    s = conv.(v)
    for y in 1:8
        print(file, "\t", join(s[:, y], "; "))
        print(file, ";")
        if y < 8
            println(file)
        end
    end
    println(file, ";")

    v = zeros(Tuple{Int,Int}, 8, 8)

    for i in 1:length(values)-2
        v[i, 1] = (values[i] - values[i+1], values[i])
        v[1, i] = (values[i+1] - values[i], 2values[i+1] - values[i] - values[i+2])
    end
    v[1, 1] = (0, v[1, 1][2])
    s = conv.(v)
    for y in 1:8
        print(file, "\t", join(s[:, y], "; "))
        if y < 8
            println(file, ";")
        end
    end
    println(file, "\n]\n")
end

function gen_values(file, name, values)
    println(file, "const $(name)_values = Tuple{Int16,Int16}[")
    v = zeros(Tuple{Int,Int}, 8, 8)

    v[1, 1] = (1, -1)
    for i in 2:length(values)-1
        v[i, 1] = (values[i+1] - values[i], -values[i])
        v[1, i] = (values[i], values[i] - values[i+1])
    end
    s = conv.(v)
    for y in 1:8
        println(file, "\t", join(s[:, y], ", "), ",")
    end
    println(file, "]\n")
end

function gen_value(file, name, values)
    println(file, "const $(name)_value = Int16[")
    v = zeros(Int, 8, 8)

    for i in 2:8
        v[i, 1] = values[i]
        v[1, i] = -values[i]
    end
    for y in 1:8
        println(file, "\t", join(v[:, y], ", ",), ",")
    end
    println(file, "]\n")
end

file = open("game_values.jl", "w")

println(file, "# Generated. Don't edit.\n")
println(file, "const win_value::Int16 = 500\n")
gen(file, "connect6", 0, 1, 5, 20, 60, 120, 1000, 1000)
gen(file, "gomoku", 0, 1, 4, 12, 24, 1000, 1000, 1000)

close(file)

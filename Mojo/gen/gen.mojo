from builtin.file import open
from pathlib import cwd
from os import makedirs
from utils.numerics import inf, neg_inf, nan, isinf, isnan


alias header = """# Generated. DO NOT EDIT.

from collections import InlineArray
from utils.numerics import inf, neg_inf

alias Value = Float16
alias dtype = DType.float16
alias win = inf[DType.float16]()
alias loss = neg_inf[DType.float16]()


fn pair(x: Value, y: Value, out result: SIMD[dtype, 2]):
    result = SIMD[dtype, 2](x, y)


"""

alias win = inf[DType.float16]()
alias invalid = nan[DType.float16]()


fn main() raises:
    gen_tables("gomoku", 5, 0, 1, 5, 25, 125, win, invalid, invalid)
    gen_tables("connect6", 6, 0, 1, 5, 25, 125, 625, win, invalid)


fn gen_tables(name: String, max_stones: Int, *values: Float16) raises:
    var path = String(name, "/", name, "_tables.mojo")
    makedirs(name, exist_ok=True)
    with open(path, "w") as file:
        file.write(header)
        file.write("alias max_stones = ", max_stones, "\n\n\n")
        gen_values(file, values)


fn gen_values(mut file: FileHandle, values: VariadicList[Float16]):
    file.write("alias game_values = (\n")
    file.write("    InlineArray[SIMD[dtype, 2], 37]( # first\n")
    file.write(
        "        pair(", values[0] + values[2] - 2 * values[1], ", 0.0),\n"
    )
    for i in range(1, 6):
        file.write(
            "        pair(",
            str(values[i] + values[i + 2] - 2 * values[i + 1]),
            ", ",
            str(values[i] - values[i + 1]),
            "),\n",
        )

    file.write("\n")

    for i in range(1, 6):
        file.write(
            "        pair(",
            str(-values[i]),
            ", ",
            str(values[i + 1] - values[i]),
            "),\n",
        )
        for _ in range(5):
            file.write("        pair(0.0, 0.0),\n")
        file.write("\n")

    file.write("        pair(0.0, 0.0),\n")
    file.write("    ),\n\n")

    file.write("    InlineArray[SIMD[dtype, 2], 37]( # second\n")
    file.write(
        "        pair(0.0, ", 2 * values[1] - values[0] - values[2], "),\n"
    )
    for i in range(1, 6):
        file.write(
            "        pair(",
            str(values[i] - values[i + 1]),
            ", ",
            str(values[i]),
            "),\n",
        )

    file.write("\n")

    for i in range(1, 6):
        file.write(
            "        pair(",
            str(values[i + 1] - values[i]),
            ", ",
            str(2 * values[i + 1] - values[i] - values[i + 2]),
            "),\n",
        )
        for _ in range(5):
            file.write("        pair(0.0, 0.0),\n")
        file.write("\n")

    file.write("        pair(0.0, 0.0),\n")
    file.write("    )\n")
    file.write(")\n")


fn str(v: Float16, out result: String):
    if isinf(v):
        result = "win" if v > 0 else "loss"
    elif isnan(v):
        result = "0.0"
    else:
        result = String(v)

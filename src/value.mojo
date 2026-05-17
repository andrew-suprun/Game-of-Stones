from std.sys.defines import get_defined_string
from std.utils.numerics import FPUtils, isinf, isnan, isfinite, inf, nan

comptime AssertMode = get_defined_string["ASSERT", "none"]()
comptime Assert = AssertMode == "all"

comptime Value = Float32
comptime Win = Value.MAX
comptime Loss = Value.MIN
comptime Draw = nan[Value.dtype]()


def is_win(v: Value) -> Bool:
    return isinf(v) and v > 0


def is_loss(v: Value) -> Bool:
    return isinf(v) and v < 0


def is_draw(v: Value) -> Bool:
    return isnan(v)


def is_decisive(v: Value) -> Bool:
    return not isfinite(v)


def write_to[W: Writer](v: Value, mut writer: W):
    if isinf(v):
        if v > 0:
            writer.write("win")
        else:
            writer.write("loss")
    elif is_draw(v):
        writer.write("draw")
    else:
        writer.write(String(v))

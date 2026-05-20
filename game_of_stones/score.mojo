from std.sys.defines import get_defined_string
from std.utils.numerics import isinf, isnan, isfinite, nan

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


def str(v: Value) -> String:
    if isinf(v):
        if v > 0:
            return "win"
        else:
            return "loss"
    elif is_draw(v):
        return "draw"
    else:
        return String(v)

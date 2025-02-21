# Generated. DO NOT EDIT.

from collections import InlineArray
from utils.numerics import inf, neg_inf

alias Value = Float16
alias dtype = DType.float16
alias win = inf[DType.float16]()
alias loss = neg_inf[DType.float16]()


fn pair(x: Value, y: Value, out result: SIMD[dtype, 2]):
    result = SIMD[dtype, 2](x, y)


alias max_stones = 5


alias game_values = (
    InlineArray[SIMD[dtype, 2], 37]( # first
        pair(3.0, 0.0),
        pair(16.0, -4.0),
        pair(80.0, -20.0),
        pair(win, -100.0),
        pair(0.0, loss),
        pair(0.0, 0.0),

        pair(-1.0, 4.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-5.0, 20.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-25.0, 100.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-125.0, win),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(loss, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(0.0, 0.0),
    ),

    InlineArray[SIMD[dtype, 2], 37]( # second
        pair(0.0, -3.0),
        pair(-4.0, 1.0),
        pair(-20.0, 5.0),
        pair(-100.0, 25.0),
        pair(loss, 125.0),
        pair(0.0, win),

        pair(4.0, -16.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(20.0, -80.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(100.0, loss),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(win, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(0.0, 0.0),
    )
)

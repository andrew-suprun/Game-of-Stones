# Generated. DO NOT EDIT.

from collections import InlineArray
from utils.numerics import inf, neg_inf

alias Value = Float16
alias dtype = DType.float16
alias win = inf[DType.float16]()
alias loss = neg_inf[DType.float16]()


fn pair(x: Value, y: Value, out result: SIMD[dtype, 2]):
    result = SIMD[dtype, 2](x, y)


alias max_stones = 6


alias game_values = (
    InlineArray[SIMD[dtype, 2], 37]( # first
        pair(3.0, 0.0),
        pair(11.0, -4.0),
        pair(25.0, -15.0),
        pair(20.0, -40.0),
        pair(win, -60.0),
        pair(0.0, loss),

        pair(-1.0, 4.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-5.0, 15.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-20.0, 40.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-60.0, 60.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(-120.0, win),
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
        pair(-15.0, 5.0),
        pair(-40.0, 20.0),
        pair(-60.0, 60.0),
        pair(loss, 120.0),

        pair(4.0, -11.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(15.0, -25.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(40.0, -20.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),
        pair(0.0, 0.0),

        pair(60.0, loss),
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
    )
)

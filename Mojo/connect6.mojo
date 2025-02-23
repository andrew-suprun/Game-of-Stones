from collections import InlineArray
from utils.numerics import inf
import values as v

alias max_stones = 6

alias values = InlineArray[Float16, max_stones + 1](
    Float16(0),
    Float16(1),
    Float16(5),
    Float16(25),
    Float16(125),
    Float16(625),
    inf[DType.float16](),
)

alias value_table = v.value_table[values]()

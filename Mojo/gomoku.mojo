from utils.numerics import inf

import values as v

alias max_stones = 5

alias values = List[Float32](
    Float32(0),
    Float32(1),
    Float32(5),
    Float32(25),
    Float32(125),
    inf[DType.float32](),
)

alias value_table = v.value_table[max_stones, values]()

from utils.numerics import inf

from scores import Score
import values as v

alias max_stones = 5

alias values = List[Score](
    Score(0),
    Score(1),
    Score(5),
    Score(25),
    Score(125),
    inf[DType.float32](),
)

alias value_table = v.value_table[max_stones, values]()

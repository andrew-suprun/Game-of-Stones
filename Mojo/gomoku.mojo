from values import *

alias max_stones = 5

alias values = InlineArray[Float16, max_stones + 1](
    Float16(0),
    Float16(1),
    Float16(5),
    Float16(25),
    Float16(125),
    inf[DType.float16](),
)

alias t1 = table1[values]()
alias t2 = table2[values]()
alias t3 = table3[t2[0]]()

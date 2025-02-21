from collections import InlineArray


fn top_places[
    table_size: Int, //, table: InlineArray[SIMD[DType.float16, 2], table_size]
]():
    print(table[0])
    print(table[1])
    print(table[2])
    print(table[3])


alias Value = Float16
alias dtype = DType.float16


fn pair(x: Value, y: Value, out result: SIMD[dtype, 2]):
    result = SIMD[dtype, 2](x, y)


alias table = (
    InlineArray[SIMD[dtype, 2], 4](
        pair(1, 2),
        pair(3, 4),
        pair(5, 6),
        pair(7, 8),
    ),
    InlineArray[SIMD[dtype, 2], 4](
        pair(1, 2),
        pair(3, 4),
        pair(5, 6),
        pair(7, 8),
    ),
)

alias table2 = InlineArray[SIMD[dtype, 2], 4](
    pair(1, 2),
    pair(3, 4),
    pair(5, 6),
    pair(7, 8),
)


fn main():
    var x = (1, "foo")
    print(x[1])
    print(table[1][1][1])
    print(table2[1])

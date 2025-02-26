* run with `mojo -D ASSERT=all main.mojo`
* make Move an alias type in Game

bench for Parametrized InlineArray of SIMD of Float16:
bench_update_row  0.15290429737311909
bench_place_stone 0.6144289014373717

pass value_table as argument:
bench_update_row  0.11899786430912883
bench_place_stone 0.459621600919188


type of value_table is List[SIMD]:
bench_update_row  0.13883511729798678
bench_place_stone 0.23857141424272815

type of values: Float32:
bench_update_row  0.2498296236341562
bench_place_stone 0.44518079200592153

type of values: Int16:
bench_update_row  0.2135391
bench_place_stone 0.4856856160226583

type of values: Int32:
bench_update_row  0.24905404303048842
bench_place_stone 0.4508037904124861

type of values: Float64:
bench_update_row  0.35003117188648725
bench_place_stone 0.5626714082503556

type of values: Float32:
bench_update_row  0.1906488
bench_place_stone 0.3797839516000637

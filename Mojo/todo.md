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

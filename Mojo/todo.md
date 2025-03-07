* use sys.param_env for compile time config
* make Move an alias type in Game

mojo -D ASSERT=all heap_bench.mojo
heap bench        0.093

mojo -D ASSERT=all board_bench.mojo
bench_update_row  0.086
bench_place_stone 0.602
bench_max_score   0.227
bench_top_places  3.238

mojo -D ASSERT=all connect6_bench.mojo 
bench_top_moves 459.5984

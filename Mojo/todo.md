* use sys.param_env for compile time config
* make Move an alias type in Game

mojo -D ASSERT=all board_bench.mojo
bench_update_row  0.045
bench_place_stone 0.231
bench_top_places  2.661

mojo -D ASSERT=all heap_bench.mojo
heap bench        0.093
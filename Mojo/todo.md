* use SIMD for board scores
* make score Int16
* use sys.param_env for compile time config
* make Move an alias type in Game

mojo -D ASSERT=all board_bench.mojo
bench_update_row  0.0868
bench_place_stone 0.3752
bench_max_score   0.2302
bench_top_places  3.2338

mojo -D ASSERT=all heap_bench.mojo
heap bench        0.093

mojo -D ASSERT=all simd_bench.mojo
SIMD:  79249
List:  557091
ratio: 7.029
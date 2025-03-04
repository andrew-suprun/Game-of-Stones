* optimize place_stone
* use SIMD for board scores
* make score Int16
* use sys.param_env for compile time config
* make Move an alias type in Game

mojo -D ASSERT=all board_bench.mojo
bench_update_row  0.043
bench_place_stone 0.352
bench_top_places  2.661

mojo -D ASSERT=all heap_bench.mojo
heap bench        0.093

mojo -D ASSERT=all simd_bench.mojo
SIMD:  66118
List:  462008
ratio: 6.987
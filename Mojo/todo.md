* add board.remove_stone()
* make Move an alias type in Game

mojo -D ASSERT=all board_bench.mojo
bench_update_row  0.044
bench_place_stone 0.175
* ui
* sim
* make Move an alias type in Game

mojo -D ASSERT=all heap_bench.mojo
heap bench        0.093

mojo -D ASSERT=all board_bench.mojo
bench_update_row  0.041
bench_place_stone 0.187
bench_max_score   0.004
bench_top_places  1.866

mojo -D ASSERT=all connect6_bench.mojo 
bench_top_moves 420.488
bench_extend    432.837

* Viva La Dirt League: tin foil hat
* JD Kirk: Him
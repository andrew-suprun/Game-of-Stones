pixi run mojo -I src -D ASSERT=none benches/basic_bench.mojo
pixi run mojo -I src -D ASSERT=none benches/board_bench.mojo
pixi run mojo -I src -D ASSERT=none benches/connect6_bench.mojo
pixi run mojo -I src -D ASSERT=none benches/gomoku_bench.mojo
pixi run mojo -I src -D ASSERT=none benches/heap_bench.mojo
pixi run mojo -I src -D ASSERT=none benches/logger_bench.mojo
pixi run mojo -I src -D ASSERT=none benches/perf_counter_bench.mojo
pixi run mojo -I src -D ASSERT=all benches/assert_bench.mojo
zig run -O ReleaseSafe src/heap.zig
heap: 0.00462 µsec

zig run -O ReleaseFast src/heap.zig
heap: 0.00440 µsec

zig run -O ReleaseSafe src/board.zig
updateRow:  0.196 µsec
placeStone: 0.431 µsec
topPlaces:  1.844 µsec

zig run -O ReleaseFast src/board.zig
updateRow:  0.171 µsec
placeStone: 0.456 µsec
topPlaces:  1.795 µsec

zig run -O ReleaseSafe src/connect6.zig
connect6TopMoves: 0.298 msec

zig run -O ReleaseFast src/connect6.zig
connect6TopMoves: 0.297 msec

zig run -O ReleaseSafe src/gomoku.zig
gomokuTopMoves: 0.019 msec

zig run -O ReleaseFast src/gomoku.zig
gomokuTopMoves: 0.019 msec

zig run -O ReleaseSafe src/tree_connect6.zig
c6Expand: 0.326 msec

zig run -O ReleaseFast src/tree_connect6.zig
c6Expand: 0.319 msec

zig run -O ReleaseSafe src/tree_gomoku.zig
gomokuExpand: 0.00930 msec

zig run -O ReleaseFast src/tree_gomoku.zig
gomokuExpand: 0.00913 msec
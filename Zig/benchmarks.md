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
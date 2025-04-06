zig run -O ReleaseSafe src/heap.zig
heap:       0.383215667 sec

zig run -O ReleaseFast src/heap.zig
heap:       0.365684459 sec

zig run -O ReleaseSafe src/board.zig
updateRow:  0.117833 msec
placeStone: 0.377625 msec
topPlaces : 2.109292 msec

zig run -O ReleaseFast src/board.zig
updateRow:  0.122042 msec
placeStone: 0.35275 msec
topPlaces : 1.4835 msec
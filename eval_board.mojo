from std.time import perf_counter_ns

from engine import board_size, win_stones
from engine import Board, Place, Value


comptime script = (
    "j10 i10-j11 k12-l12 s:52.0 i12-i9 i11-l9 s:54.0 k8-l8 k11-n14 s:148.0 k13-m13 l13-l14 s:185.0 m14-l11 m12-n12 s:285.0 n11-o12 l15-m9 s:120.0 l16-n8 m7-m8 s:168.0 p13-m10"
    " n7-r15 s:68.0 p11-o11 m6-q11 s:186.0 m5-n13 o13-q10 s:186.0 p9-p12 p8-p14 s:181.0 k7-l6 j8-q15 s:499.0 l10-r16 o6-q7 s:413.0 p5-q9 n10-o9 s:935.0 r6-m11 o7-q13 s:456.0"
    " q12-p7 n16-o15 s:452.0 l18-r12 m15-n15 s:1672.0 k15-p15 n18-o17 s:277.0 p18-n17 o14-r14 s:455.0 q14-o16"
)


def main() raises:
    var board = Board[win_stones]()
    var open_moves = script.split(" ")
    print("opening", script)
    var turn = 0
    for move in open_moves:
        var move_str = String(move)
        if move_str.startswith("s:"):
            continue
        var move_places = move_str.split("-")
        for p in move_places:
            var total_places = 0
            var place_str = String(p)
            var place = Place(place_str)
            print(t"\n----\nplace={place} turn={turn}")
            print(board)
            var value_offsence = Value(0)
            var place_offsence = Place(0, 0)
            var value_defence = Value(0)
            var place_defence = Place(0, 0)
            for y in range(board_size):
                for x in range(board_size):
                    if board._places[y * board_size + x] == Board.empty:
                        var values = board._values[y * board_size + x]
                        for dir in range(4):
                            if value_offsence < values[dir][turn]:
                                value_offsence = max(value_offsence, values[dir][turn])
                                place_offsence = Place(x, y)
                            if value_defence < values[dir][1 - turn]:
                                value_defence = max(value_defence, values[dir][1 - turn])
                                place_defence = Place(x, y)
            var min_offence = max(value_defence / 20, 30)
            print(t"  place_offsence={place_offsence} value_offence={value_offsence} min_offence={min_offence}")
            print(t"  place_defence={place_defence} max_value={value_defence}")
            for y in range(board_size):
                for x in range(board_size):
                    value_offsence = 0
                    var values = board._values[y * board_size + x]
                    for dir in range(4):
                        value_offsence = max(value_offsence, values[dir][turn])
                    if value_offsence >= min_offence and board._places[y * board_size + x] == Board.empty:
                        print(t"    {Place(x, y)}: {values}")
                        total_places += 1
            print(t"  total:{total_places}")
            board.place_stone(place, turn)
        turn = 1 - turn

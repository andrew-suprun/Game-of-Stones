from std.time import perf_counter_ns

from engine import Board, Place


comptime script = (
    "j10 i10-j11 k12-l12 s:52.0 i12-i9 i11-l9 s:54.0 k8-l8 k11-n14 s:148.0 k13-m13 l13-l14 s:185.0 m14-l11 m12-n12 s:285.0 n11-o12 l15-m9 s:120.0 l16-n8 m7-m8 s:168.0 p13-m10"
    " n7-r15 s:68.0 p11-o11 m6-q11 s:186.0 m5-n13 o13-q10 s:186.0 p9-p12 p8-p14 s:181.0 k7-l6 j8-q15 s:499.0 l10-r16 o6-q7 s:413.0 p5-q9 n10-o9 s:935.0 r6-m11 o7-q13 s:456.0"
    " q12-p7 n16-o15 s:452.0 l18-r12 m15-n15 s:1672.0 k15-p15 n18-o17 s:277.0 p18-n17 o14-r14 s:455.0 q14-o16"
)


comptime size = 19
comptime win_stones = 6


def main() raises:
    var board = Board[win_stones]()
    var open_moves = script.split(" ")
    print("opening", script)
    var places = List[String]()
    for move in open_moves:
        var move_str = String(move)
        if move_str.startswith("s:"):
            continue
        var move_places = move_str.split("-")
        for place in move_places:
            places.append(String(place))
    board.place_stone(Place(places[0]), 0)
    print(t"place: {places[0]} {0}")
    print(board)
    var turn = 2
    for place in places[1 : len(places) - 2]:
        print(t"place: {place} {turn / 2}")
        board.place_stone(Place(String(place)), turn / 2)
        turn = (turn + 1) % 4
        print(board)

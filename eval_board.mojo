from std.time import perf_counter_ns

from engine import board_size
from engine import Board, Place


comptime script = "g10 a10-b10-c10-d10-e10-f10 f12-g12-h12-i12-k12-l12-m12-n12-j12"


comptime size = 19
comptime win_stones = 6


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
            var place_str = String(p)
            var place = Place(place_str)
            print(t"place={place} turn={turn}")
            print(board._values[Int(place.y) * board_size + Int(place.x)])
            board.place_stone(place, turn)
            print(board)
        turn = 1 - turn

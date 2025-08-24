from time import perf_counter_ns

from score import draw
from connect6 import Connect6
from negamax import Negamax

alias Game = Connect6[max_moves=32, max_places=15]
alias Tree = Negamax[Game]
alias moves_str = "j10 j11-l12 k9-i12 k10-k8"
    "i9-i11 h12-i10 h9-j9 g9-l9 j7-j8 j6-n7 k6-m8 l8-l10 k7-l11 h8-i7 e11-k5 i8-l6 k3-l5 k4-n9 g11-m4 h10-n3 m5-n5 j5-p5 l3-o6 j1-p7 h11-o7 d11-j2 j3-p8 m7-n6 o4-o5 o3-o9 k14-n8 g10-i3 j13-p6 l15-m9 q9-r4 i6-q5 i4-n4 g8-q4 h7-m3 l2-r8 i14-m2 g6-m6 g5-h14 d10-j14 e10-i15 d8-i16 e8-g13 d9-j16 d7-d13 e6-k13 h6-n10 q3-q6 q2-q8 e12-g16 f13-k16 e13-m10 j15-r5 g12-l17 f15-g15 f16-h15 e16-n11 g14-m12 l14-q11 j17-q12 k18-m14 k17-m17 h17-n17 k15-l16 i13-n18 n12-o12 k12-p12 n14-o11 l18-o13 d6-j18 f8-m15 f6-f12 c6-c12 e5-g7 d4-f4 e3-e4 e2-e14 a10-r6 f9-n2 b5-f5 m18-o2 o18-r2 h3-o16 c2-q14 b1-e15 d5-r11 c5-e17 e18-s3 c4-r3 c7-p9 f17-q10 d17-r10 d15-r9 c15-g18 c16-h2 a18-h4 n15-p17 l13-r19 a12-f18 b13-r14 p14-p16 b16-p15 d14-r17 b14-o17 b12-r12 b6-e1 a5-b18 h1-i1 f2-g1 b7-b10 b8-q13 a11-b3 b4-c9 c11-f14 a9-m1 d2-s11 a6-s16 a4-q16 c3-s14 q19-s13 n19-q18 a15-s6 p13-s8 m13-s2 p1-s4 g19-o1 a14-h19 i19-s15 b19-d19 e19-l19 a1-c1 d1-f1 k1-l1 n1-q1 r1-s1 a2-b2 g2-i2 k2-p2 a3-d3 f3-g3 g4-p3 j4-l4 h5-p4 i5-s5 a7-e7 f7-l7 q7-r7 a8-s7 c8-o8 b9-e9 c10-s9 f10-o10 p10-s10 b11-f11 k11-m11 d12-p11 j12-s12 a13-c13 h13-n13 c14-r13 b15-o14 o15-q15 a16-r15 d16-h16 m16-n16 a17-r16 b17-c17 i17-i18 g17-q17 a19-c18 d18-s17 h18-p18"


fn main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var moves = moves_str.split(" ")
    for move in moves:
        _ = game.play_move(Tree.Game.Move(move))
        print(move)
        print(game)
    print(game)
    var start = perf_counter_ns()
    var move = tree.search(game, 100)
    print("move", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    print()

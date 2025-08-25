from time import perf_counter_ns

from score import draw
from connect6 import Connect6
from negamax import Negamax

alias Game = Connect6[max_moves=32, max_places=15]
alias Tree = Negamax[Game]
alias moves_str = "j10 j8-h11 k8-h8 j9-h12"
    " i9-k11 f6-l12 k10-l10 i10-k12 j12-k7 k6-m9 h14-m10 g15-o10 j11-l9 i12-j7 l7-n7 j6-o6 j4-l6 h6-l8 g6-n11 o11-o12 i11-o9 m11-p12 n10-n12 g12-n8 f13-j13 j14-o13 o14-p7 n14-o7 k13-m15 l14-p6 i13-q5 g13-m14 k14-n13 g14-l13 g10-g16 d12-r10 e12-s9 e13-f14 b10-h16 e15-n15 d16-o16 f15-h15 d15-j15 d17-e16 c18-h13 f4-g5 i7-l11 f8-p15 c10-f7 e7-h4 d8-j2 e14-l17 e18-l15 e3-e8 d2-n17 d10-o18 d11-g7 b9-e5 e6-g8 g3-g9 c4-d5 b3-h9 d4-d6 d3-d9 f3-f9 c14-e10 b14-h2 n6-p8 k5-q9 i3-o8 f2-m8 g2-r8 q8-r6 b7-o5 f11-o4 m5-q7 l4-m3 l5-m4 i8-n3 p4-q3 m7-r2 p13-r9 p14-r7 p3-p5 i16-p2 f16-p11 i4-p9 b6-i5 b4-k16 h5-j16 j5-k15 h18-k18 d14-r5 f19-r4 f18-n2 l18-r13 m2-r12 o2-q12 b18-s14 d18-k2 l3-m18 e17-k4 j3-n16 o3-q13 p16-s13 l16-r16 i18-s15 i17-s12 f17-q15 r14-s18 b15-r17 b13-c9 f12-q17 c11-p17 a13-c2 a2-b16 a10-c6 c3-q18 a14-n18 a9-a15 g4-k17 a6-f5 a4-s6 e19-s7 g1-g19 h1-m1 c13-l1 l19-m19 k19-p19 c1-f1 s1-s3 q1-s5 b1-b19 k1-q19 j1-o1 a1-d1 e1-i1 n1-p1 b2-r1 e2-i2 l2-q2 a3-s2 h3-k3 e4-r3 n4-q4 a5-s4 b5-c5 i6-n5 m6-q6 a7-c7 d7-h7 a8-b8 c8-s8 e9-k9 f10-n9 h10-p10 q10-s10 a11-b11 e11-g11 q11-r11 a12-s11 b12-c12 d13-m12 i14-m13 c15-q14 i15-o15 a16-r15 c16-m16 q16-s16 a17-b17 c17-g17 h17-j17 m17-o17 a18-s17 g18-j18 p18-r18"


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
    var move = tree.search(game, 10)
    print("move", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    print()

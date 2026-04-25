* ABS._search() returns best_move?
* PVS: skip zero window when alpha == beta


result: abs: 14 - mcts: 10

====

opening 1: j10 k9-k11 j9-i9 i11-k12

abs vs. mcts

   5: abs  i10-k10 no-score  0.25   j11-l11 h11-n11 l7-l10 h10-l9 f10-m10 h8-h9 j13-n9 
   6: mcts h10-j12     43.0  0.25   l11-m12 i8-n13 g12-h11 f13-l7 g9-l10 l14-n10 g10-k13 f9-g11 h13-j11 i12-n11 g7-n12 i13-i14 g8-i15 g5-j14 h12-h14 h15-m14 f7-n14 e6-g16 e7-f17 o12-p11 l15-q10 e12-g14 c10-i16 
   7: abs  k8-l7   no-score  0.25   g12-m6 i8-l11 h7-m12 j8-l8 h8-m8 l9-l10 l6-l12 
   8: mcts g12-m6      74.0  0.251  l11-m12 i8-o14 l9-l10 l8-m10 g9-h12 f11-l14 j11-k13 h13-i14 e10-j15 h9-j7 g10-m8 k6-n7 k14-l5 l6-l13 i6-n6 n15-o16 f9-m14 m16-p13 g8-h7 
   9: abs  i8-l11#      win  0.054  h7-m12 j8-l8 h8-m8 l9-l10 l6-l12 m10-n10 
  10: mcts h7-n13    -584.0  0.012  l8-l10 l9-m10 h8-j8 
  11: abs  j8-l8#       win  0.009  h8-m8 l9-l10 l6-l12 m10-n10 
  12: mcts g8-m8     -565.0  0.0    l9-l10 
  13: abs  l9-l10#      win  0.0    l6-l12 m10-n10 
  14: mcts l6-l12    -477.0  0.0    
  15: abs  m10-n10#     win  0.0    

opening 1: j10 k9-k11 j9-i9 i11-k12

mcts vs. abs

   5: mcts j11-j12     27.0  0.25   j8-j13 k10-l11 i8-l10 m8-m11 h6-i12 i7-m12 m9-n13 l7-n7 h11-o6 k14-o7 g10-m7 e8-k6 l13-n9 m13-o9 m14-n10 n12-o11 o12-p11 k16-q10 l14-o16 m6-n15 h8-k8 
   6: abs  j7-j13  no-score  0.251  k10-m10 l10-l11 i10-l9 i7-j8 h6-m11 i14-m8 g10-h15 

   7: mcts k10-m10    -10.0  0.251  i12-l10 g10-i10 f10-i7 h7-j8 g9-h8 e11-k5 i14-l11 f5-h15 g6-l13 k8-l7 h11-m6 k7-l6 h10-m5 m7-n8 
   8: abs  i8-l10  no-score  0.251  g10-m11 k6-m8 h9-h10 f10-l7 h7-h8 h6-h12 
   9: mcts m11-m12    -52.0  0.251  k6-m9 h9-l11 m13-n13 l13-n11 k14-l5 f9-m4 g9-o7 n8-o11 k15-p11 k13-o12 i12-l15 g10-m16 i15-j15 p13-q14 
  10: abs  m8-m14#     draw  0.001  h8-h9 


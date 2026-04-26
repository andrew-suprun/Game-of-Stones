* ABS._search() returns best_move?
* PVS: skip zero window when alpha == beta

C6:
result: abs: 4 - mcts: 14

result: mcts-10: 19 - mcts-20: 14
result: mcts-8:  25 - mcts-4:  10
result: mcts-8:  10 - mcts-12: 15
result: mcts-8:  13 - mcts-16: 21
result: mcts-10: 13 - mcts-12: 15
result: mcts-12: 15 - mcts-14: 16
result: mcts-12:  9 - mcts-14: 10
result: mcts-12: 15 - mcts-16: 11
result: mcts-16: 12 - mcts-24: 13
result: mcts-20: 10 - mcts-24:  9
result: mcts-20: 11 - mcts-30: 13
result: mcts-30: 15 - mcts-45: 9

Gomoku:

result: abs: 1 - mcts: 18

result: g-mcts-4:   6 - g-mcts-8:  8
result: g-mcts-6:   7 - g-mcts-8:  7
result: g-mcts-6:  10 - g-mcts-8:  1
result: g-mcts-8:   8 - g-mcts-10: 4
result: g-mcts-8:  11 - g-mcts-12: 7
result: g-mcts-10: 12 - g-mcts-20: 3

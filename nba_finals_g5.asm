# NBA Finals 2026, Game 5 (Jun 13, 2026) — Knicks 94, Spurs 90
# Top 6 individual scorers of the game (mixed both teams), hardcoded as
# constants pulled from the real box score:
#   x1 = 45  Jalen Brunson   (NYK)
#   x2 = 25  Dylan Harper    (SAS)
#   x3 = 19  Victor Wembanyama (SAS)
#   x4 = 14  Mikal Bridges   (NYK)
#   x5 = 14  Julian Champagnie (SAS)
#   x6 = 13  Josh Hart       (NYK)
#
# Program computes, on real CPU hardware:
#   x8 / mem[6] = sum of these 6 players' points        -> expect 130
#   x7 / mem[7] = highest single scoring total (the max) -> expect 45

addi x1, x0, 45
addi x2, x0, 25
addi x3, x0, 19
addi x4, x0, 14
addi x5, x0, 14
addi x6, x0, 13

sw x1, 0(x0)
sw x2, 4(x0)
sw x3, 8(x0)
sw x4, 12(x0)
sw x5, 16(x0)
sw x6, 20(x0)

# --- sum of the 6 point totals ---
addi x8, x1, 0
add  x8, x8, x2
add  x8, x8, x3
add  x8, x8, x4
add  x8, x8, x5
add  x8, x8, x6
sw   x8, 24(x0)

# --- max of the 6 point totals (top scorer of the game) ---
addi x7, x1, 0
slt  x9, x7, x2
beq  x9, x0, skip1
addi x7, x2, 0
skip1:
slt  x9, x7, x3
beq  x9, x0, skip2
addi x7, x3, 0
skip2:
slt  x9, x7, x4
beq  x9, x0, skip3
addi x7, x4, 0
skip3:
slt  x9, x7, x5
beq  x9, x0, skip4
addi x7, x5, 0
skip4:
slt  x9, x7, x6
beq  x9, x0, skip5
addi x7, x6, 0
skip5:
sw   x7, 28(x0)

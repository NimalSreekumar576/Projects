# ---------- Part 1: sum 1..10 (expect x1 = 55) ----------
        addi x1, x0, 0          # sum = 0
        addi x2, x0, 1          # i = 1
        addi x3, x0, 11         # limit = 11
loop1:  add  x1, x1, x2         # sum += i
        addi x2, x2, 1          # i++
        bne  x2, x3, loop1      # repeat until i == 11

# ---------- Part 2: store / load (expect x4 = 55, mem word0 = 55) ----------
        sw   x1, 0(x0)
        lw   x4, 0(x0)

# ---------- Part 3: first 10 Fibonacci numbers -> mem words 1..10 ----------
        addi x5, x0, 0          # a = 0
        addi x6, x0, 1          # b = 1
        addi x7, x0, 4          # byte address pointer
        addi x8, x0, 0          # count = 0
        addi x9, x0, 10         # n = 10
fib:    sw   x5, 0(x7)          # store a
        add  x10, x5, x6        # next = a + b
        add  x5, x0, x6         # a = b
        add  x6, x0, x10        # b = next
        addi x7, x7, 4
        addi x8, x8, 1
        bne  x8, x9, fib

# ---------- Part 4: ALU tests ----------
        addi x11, x0, 12
        addi x12, x0, 10
        and  x13, x11, x12      # 8
        or   x14, x11, x12      # 14
        sub  x15, x11, x12      # 2
        slt  x16, x12, x11      # 1  (10 < 12)
        slt  x17, x11, x12      # 0  (12 < 10 false)
        andi x18, x11, 5        # 12 & 5 = 4
        ori  x19, x12, 5        # 10 | 5 = 15

# ---------- Part 5: beq, jal, lui, negative immediate ----------
        beq  x15, x15, skip1    # always taken
        addi x20, x0, 99        # must be skipped (x20 stays 0)
skip1:  jal  x21, target        # x21 = PC+4, jump
        addi x22, x0, 99        # must be skipped (x22 stays 0)
target: lui  x23, 0x12345       # x23 = 0x12345000
        addi x24, x0, -1        # x24 = 0xFFFFFFFF
        addi x25, x0, 1         # done marker
end:    beq  x0, x0, end        # park here forever

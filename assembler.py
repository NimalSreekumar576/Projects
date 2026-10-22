#!/usr/bin/env python3
"""
Tiny RV32I assembler for the 14-instruction subset used in this project.
Usage:  python assembler.py program.asm
Prints (1) a listing and (2) Verilog lines you can paste into imem.v,
and also writes program.hex (one 32-bit word per line, for $readmemh).

Supported: add sub and or slt | addi andi ori | lw sw | beq bne | jal | lui
Syntax:    one instruction per line, labels end with ':', comments start with '#'
Examples:  addi x1, x0, 5      lw x4, 0(x0)      bne x2, x3, loop      jal x21, target
"""
import sys, re

REGS = {f"x{i}": i for i in range(32)}

R_TYPE = {  # name: (funct7, funct3)
    "add": (0x00, 0b000), "sub": (0x20, 0b000), "and": (0x00, 0b111),
    "or":  (0x00, 0b110), "slt": (0x00, 0b010),
}
I_TYPE = {"addi": 0b000, "andi": 0b111, "ori": 0b110}   # opcode 0010011
B_TYPE = {"beq": 0b000, "bne": 0b001}                   # opcode 1100011


def reg(tok):
    tok = tok.strip()
    if tok not in REGS:
        raise ValueError(f"bad register '{tok}'")
    return REGS[tok]


def num(tok):
    return int(tok.strip(), 0)


def enc_r(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(imm, rs1, f3, rd, op):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(imm, rs2, rs1, f3, op):
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1F) << 7) | op


def enc_b(imm, rs2, rs1, f3, op):
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | op


def enc_u(imm20, rd, op):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | op


def enc_j(imm, rd, op):
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | \
           (((imm >> 12) & 0xFF) << 12) | (rd << 7) | op


def assemble(lines):
    # pass 1: strip comments, collect labels
    insts, labels = [], {}
    for raw in lines:
        line = raw.split("#")[0].strip()
        if not line:
            continue
        while ":" in line:
            lab, line = line.split(":", 1)
            labels[lab.strip()] = len(insts) * 4
            line = line.strip()
        if line:
            insts.append(line)

    words = []
    for idx, line in enumerate(insts):
        pc = idx * 4
        m = re.match(r"(\w+)\s*(.*)", line)
        op, args = m.group(1).lower(), [a.strip() for a in m.group(2).split(",")]
        if op in R_TYPE:
            f7, f3 = R_TYPE[op]
            w = enc_r(f7, reg(args[2]), reg(args[1]), f3, reg(args[0]), 0b0110011)
        elif op in I_TYPE:
            w = enc_i(num(args[2]), reg(args[1]), I_TYPE[op], reg(args[0]), 0b0010011)
        elif op == "lw":
            mm = re.match(r"(-?\w+)\((\w+)\)", args[1])
            w = enc_i(num(mm.group(1)), reg(mm.group(2)), 0b010, reg(args[0]), 0b0000011)
        elif op == "sw":
            mm = re.match(r"(-?\w+)\((\w+)\)", args[1])
            w = enc_s(num(mm.group(1)), reg(args[0]), reg(mm.group(2)), 0b010, 0b0100011)
        elif op in B_TYPE:
            off = labels[args[2]] - pc
            w = enc_b(off, reg(args[1]), reg(args[0]), B_TYPE[op], 0b1100011)
        elif op == "jal":
            off = labels[args[1]] - pc
            w = enc_j(off, reg(args[0]), 0b1101111)
        elif op == "lui":
            w = enc_u(num(args[1]), reg(args[0]), 0b0110111)
        else:
            raise ValueError(f"unsupported instruction: {line}")
        words.append((pc, w, line))
    return words


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python assembler.py program.asm")
    with open(sys.argv[1]) as f:
        prog = assemble(f.readlines())

    print("// ---- listing ----")
    for pc, w, src in prog:
        print(f"// 0x{pc:04X}: {w:08X}   {src}")
    print("\n// ---- paste into imem.v ----")
    for pc, w, src in prog:
        print(f"        mem[{pc // 4}] = 32'h{w:08X};   // {src}")
    with open("program.hex", "w") as f:
        for _, w, _ in prog:
            f.write(f"{w:08X}\n")
    print("\nWrote program.hex")

#!/usr/bin/env python3
"""
build.py  -  one command that keeps everything in sync with program.asm

    python3 build.py            rebuild once
    python3 build.py --watch    rebuild automatically every time program.asm is saved

What it does:
  1. Assembles program.asm (via assembler.py) into 32-bit machine words.
  2. Rewrites the program section of imem.v.
  3. Runs the program on a small Python reference model (an instruction-set
     simulator) to compute the expected final state:
       - all 32 registers, every memory word the program stored to,
         the final PC, and how many cycles the program needs.
  4. Rewrites the expected-value checks and cycle count in tb_riscv_top.v.

The reference model decodes the machine words itself (independently of the
Verilog), so a hardware bug shows up as a FAIL in the testbench.
"""
import os, re, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
ASM = os.path.join(HERE, "program.asm")
IMEM = os.path.join(HERE, "imem.v")
TB = os.path.join(HERE, "tb_riscv_top.v")

sys.path.insert(0, HERE)
from assembler import assemble  # noqa: E402

IMEM_WORDS = 64      # must match imem.v
DMEM_WORDS = 256     # must match dmem.v
MAX_STEPS = 100000
MARGIN_CYCLES = 20


class BuildError(Exception):
    pass


# ---------------------------------------------------------------- reference model
def _sx(value, bits):
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def run_iss(words):
    """Execute machine words the way the RTL should. Returns (regs, mem, halt_pc, steps)."""
    n = len(words)
    regs = [0] * 32
    mem = {}                       # word index -> value (only words that were stored to)
    pc, steps = 0, 0
    M = 0xFFFFFFFF

    while True:
        if pc % 4 or not (0 <= pc // 4 < n):
            raise BuildError(
                f"PC reached 0x{pc:X}, outside the program. Finish the program with a "
                "parking loop such as  'end: beq x0, x0, end'.")
        if steps >= MAX_STEPS:
            raise BuildError("Program did not halt. End it with  'end: beq x0, x0, end'.")

        w = words[pc // 4]
        op, rd = w & 0x7F, (w >> 7) & 31
        f3, rs1, rs2, f7 = (w >> 12) & 7, (w >> 15) & 31, (w >> 20) & 31, w >> 25
        a, b = regs[rs1], regs[rs2]
        imm_i = _sx(w >> 20, 12)
        imm_s = _sx(((w >> 25) << 5) | ((w >> 7) & 31), 12)
        imm_b = _sx((((w >> 31) & 1) << 12) | (((w >> 7) & 1) << 11) |
                    (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1), 13)
        imm_j = _sx((((w >> 31) & 1) << 20) | (((w >> 12) & 0xFF) << 12) |
                    (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1), 21)
        nxt, wr = pc + 4, None     # wr = value written to rd

        if op == 0x33:             # R-type
            if f3 == 0 and f7 == 0x00:   wr = (a + b) & M
            elif f3 == 0 and f7 == 0x20: wr = (a - b) & M
            elif f3 == 7:                wr = a & b
            elif f3 == 6:                wr = a | b
            elif f3 == 2:                wr = int(_sx(a, 32) < _sx(b, 32))
            else: raise BuildError(f"unsupported R-type word 0x{w:08X} at PC 0x{pc:X}")
        elif op == 0x13:           # I-type ALU
            if f3 == 0:   wr = (a + imm_i) & M
            elif f3 == 7: wr = (a & imm_i) & M
            elif f3 == 6: wr = (a | imm_i) & M
            else: raise BuildError(f"unsupported I-type word 0x{w:08X} at PC 0x{pc:X}")
        elif op == 0x03:           # lw
            addr = (a + imm_i) & M
            _check_addr(addr, pc)
            wr = mem.get(addr >> 2, 0)
        elif op == 0x23:           # sw
            addr = (a + imm_s) & M
            _check_addr(addr, pc)
            mem[addr >> 2] = b
        elif op == 0x63:           # beq / bne
            if f3 == 0:   taken = a == b
            elif f3 == 1: taken = a != b
            else: raise BuildError(f"unsupported branch word 0x{w:08X} at PC 0x{pc:X}")
            if taken:
                nxt = (pc + imm_b) & M
        elif op == 0x6F:           # jal
            wr, nxt = pc + 4, (pc + imm_j) & M
        elif op == 0x37:           # lui
            wr = w & 0xFFFFF000
        else:
            raise BuildError(f"unsupported opcode 0x{op:02X} (word 0x{w:08X}) at PC 0x{pc:X}")

        if wr is not None and rd != 0:
            regs[rd] = wr & M
        steps += 1
        if nxt == pc:              # jumped to itself = parking loop = done
            return regs, mem, pc, steps
        pc = nxt


def _check_addr(addr, pc):
    if addr % 4 or addr >= DMEM_WORDS * 4:
        raise BuildError(f"lw/sw at PC 0x{pc:X} uses address 0x{addr:X}: must be word-aligned "
                         f"and below 0x{DMEM_WORDS * 4:X}")


# ---------------------------------------------------------------- file rewriting
def replace_region(text, name, body, path):
    pat = re.compile(rf"([ \t]*// BEGIN AUTO-GENERATED {name}[^\n]*\n)(.*?)([ \t]*// END AUTO-GENERATED {name})", re.S)
    if not pat.search(text):
        raise BuildError(f"markers 'AUTO-GENERATED {name}' not found in {os.path.basename(path)}")
    return pat.sub(lambda m: m.group(1) + body + m.group(3), text, count=1)


def build():
    with open(ASM) as f:
        try:
            prog = assemble(f.readlines())
        except KeyError as e:
            raise BuildError(f"undefined label {e}. Check spelling of the label in program.asm")
        except (ValueError, AttributeError, IndexError) as e:
            raise BuildError(f"assembly error: {e}. Check the syntax of your last edit")
    if not prog:
        raise BuildError("program.asm has no instructions")
    if len(prog) > IMEM_WORDS:
        raise BuildError(f"program has {len(prog)} instructions; imem.v holds {IMEM_WORDS}")

    words = [w for _, w, _ in prog]
    regs, mem, halt_pc, steps = run_iss(words)
    cycles = steps + MARGIN_CYCLES

    # --- imem.v
    body = "".join(f"        mem[{pc // 4}] = 32'h{w:08X};   // {src}\n" for pc, w, src in prog)
    text = open(IMEM).read()
    open(IMEM, "w").write(replace_region(text, "PROGRAM", body, IMEM))

    # --- tb_riscv_top.v
    params = (f"    localparam RUN_CYCLES = {cycles};\n"
              f"    localparam [31:0] EXPECTED_PC = 32'h{halt_pc:08X};\n")
    lines = []
    for i in range(32):
        lines.append(f'        check("x{i}", uut.rf.regs[{i}], 32\'h{regs[i]:08X});'
                     f'   // {_sx(regs[i], 32)}\n')
    for idx in sorted(mem):
        lines.append(f'        check("mem[{idx}]", uut.dm.mem[{idx}], 32\'h{mem[idx]:08X});'
                     f'   // byte addr 0x{idx * 4:X}, value {_sx(mem[idx], 32)}\n')
    tb = open(TB).read()
    tb = replace_region(tb, "PARAMS", params, TB)
    tb = replace_region(tb, "CHECKS", "".join(lines), TB)
    open(TB, "w").write(tb)

    return len(prog), steps, cycles, halt_pc, len(mem)


def run_once():
    try:
        n, steps, cycles, halt_pc, nmem = build()
    except BuildError as e:
        print(f"[build] ERROR: {e}")
        return False
    print(f"[build] OK  {n} instructions -> imem.v | reference model: {steps} instructions, "
          f"halts at PC 0x{halt_pc:X} | testbench: {cycles} cycles, 32 registers + {nmem} memory words checked")
    return True


if __name__ == "__main__":
    if "--watch" not in sys.argv:
        sys.exit(0 if run_once() else 1)

    print(f"[build] watching {ASM}  (Ctrl+C to stop)")
    last = None
    while True:
        try:
            m = os.stat(ASM).st_mtime
            if m != last:
                last = m
                run_once()
            time.sleep(0.5)
        except KeyboardInterrupt:
            print("\n[build] stopped")
            break

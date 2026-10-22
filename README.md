# Single-Cycle RV32I Core in Verilog (Vivado + WSL)

Supported instructions (14): `add sub and or slt | addi andi ori | lw sw | beq bne | jal | lui`

**Daily workflow:** edit `program.asm` -> run `python3 build.py` (in WSL) -> `imem.v` and the testbench's expected values are regenerated -> re-run the simulation in Vivado.

## Files

| File | Role | Edited by |
|---|---|---|
| `program.asm` | The program the core runs (assembly) | **You** |
| `build.py` | Assembles `program.asm`, rewrites `imem.v`, computes expected results, rewrites the testbench checks | Nobody (run it) |
| `assembler.py` | Assembly -> machine code (used by `build.py`) | Nobody |
| `imem.v` | Instruction memory. The program section is **auto-generated** | `build.py` |
| `tb_riscv_top.v` | Self-checking testbench. Cycle count, final PC and all checks are **auto-generated** | `build.py` |
| `alu.v` `regfile.v` `imm_gen.v` `control.v` `dmem.v` `riscv_top.v` | The processor | You (when developing the core) |
| `rebuild.tcl` | Optional: rebuild + simulate with one command from the Vivado Tcl console | Nobody |

Never edit the text between `BEGIN AUTO-GENERATED` and `END AUTO-GENERATED` markers; the next build overwrites it.

## One-time setup

1. **Put the project on a Windows drive**, for example `C:\rv32_project`. Do not keep it inside the WSL filesystem (`\\wsl$\...`): Vivado handles those paths poorly. WSL sees the same folder as `/mnt/c/rv32_project`.
2. Check Python in WSL: open the WSL terminal and run `python3 --version` (no extra packages needed).
3. **Create the Vivado project:** RTL Project, tick "Do not specify sources at this time", any part.
4. Add the 7 design files (`alu.v regfile.v imm_gen.v control.v imem.v dmem.v riscv_top.v`) as **Design Sources**, and `tb_riscv_top.v` as a **Simulation Source**.
   **Untick "Copy sources into project"** in the Add Sources dialog. If it is ticked, Vivado works on its own copies, and the files that `build.py` updates are never seen by Vivado.
5. Confirm `riscv_top` is the design top and `tb_riscv_top` the simulation top.

## Every time you change the program

**Manual (simplest):**
```bash
cd /mnt/c/rv32_project
python3 build.py
```
It prints one line, for example:
```
[build] OK  37 instructions -> imem.v | reference model: 125 instructions, halts at PC 0x90 | testbench: 145 cycles, 32 registers + 11 memory words checked
```
If you made a mistake in `program.asm`, it prints `[build] ERROR: ...` and leaves `imem.v` and the testbench untouched.

**Automatic:** leave this running in a WSL terminal and it rebuilds every time you save `program.asm`:
```bash
cd /mnt/c/rv32_project
python3 build.py --watch
```

**Then in Vivado:** if it shows a "source files modified" prompt, choose to reload. Then use **Run Simulation -> Relaunch Simulation** (or close the old simulation and run Behavioral Simulation again). Type `run all` in the Tcl console, because Vivado's default run time of 1000 ns is shorter than the program.

**Or one step from Vivado:** in the Tcl console run `source C:/rv32_project/rebuild.tcl`. It calls `build.py` through WSL, then relaunches the simulation and runs it. (I could not test this Tcl script in Vivado here; if it errors, use the manual route above.)

## How the expected values are computed

`build.py` contains a small Python instruction-set simulator. It decodes the machine words itself, runs the program to its final parking loop, and records:
- all 32 register values,
- every memory word the program stored to,
- the final PC and the number of cycles needed.

These become the `check(...)` lines in the testbench. Because the Python model and the Verilog are written independently, a hardware bug makes a check FAIL (I tested this by deliberately breaking `sub`).

## Rules for your program.asm

- **Finish with a parking loop**: `end: beq x0, x0, end`. Without it `build.py` reports an error.
- Max **64 instructions** (the size of `imem.v`).
- `lw`/`sw` addresses must be multiples of 4 and below `0x400` (data memory is 256 words).
- Only the 14 supported instructions work. Adding a new instruction needs changes in `assembler.py`, `build.py` (reference model), `control.v` and `alu.v`.
- Registers `x0` to `x31` only (not ABI names like `t0`).
- Memory checks cover words the program stored to; registers are all checked, so an unexpected write to any register is caught.

## Troubleshooting

- **Vivado still shows old results:** sources were copied into the project (see setup step 4), or you did not relaunch the simulation.
- **`python3: command not found` in WSL:** install it with `sudo apt install python3`.
- **`--watch` does not trigger:** it polls the file every 0.5 s (needed because WSL cannot get change notifications for `/mnt/c`). Make sure you actually saved the file.
- **Simulation ends at 1000 ns with no RESULT line:** type `run all`.
- **`ERROR: PC reached ... outside the program`:** your program lacks the final `end: beq x0, x0, end` loop.

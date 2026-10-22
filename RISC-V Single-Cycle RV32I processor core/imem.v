`timescale 1ns / 1ps
//==============================================================
// imem.v  -  Instruction memory, 64 words (256 bytes)
// The test program is hard-coded in the initial block, so no
// .mem / .hex file path problems in Vivado. Unused words = NOP.
// To change the program: run assembler.py and paste its output
// over the mem[...] lines below.
//==============================================================
module imem (
    input  wire [31:0] addr,        // byte address (PC)
    output wire [31:0] inst
);
    reg [31:0] mem [0:63];
    integer i;

    initial begin
        // fill with NOP (addi x0, x0, 0)
        for (i = 0; i < 64; i = i + 1)
            mem[i] = 32'h00000013;

        // ---------------- test program ----------------
        // BEGIN AUTO-GENERATED PROGRAM (edit program.asm, not this)
        mem[0] = 32'h00000093;   // addi x1, x0, 0
        mem[1] = 32'h00100113;   // addi x2, x0, 1
        mem[2] = 32'h00B00193;   // addi x3, x0, 11
        mem[3] = 32'h002080B3;   // add  x1, x1, x2
        mem[4] = 32'h00110113;   // addi x2, x2, 1
        mem[5] = 32'hFE311CE3;   // bne  x2, x3, loop1
        mem[6] = 32'h00102023;   // sw   x1, 0(x0)
        mem[7] = 32'h00002203;   // lw   x4, 0(x0)
        mem[8] = 32'h00000293;   // addi x5, x0, 0
        mem[9] = 32'h00100313;   // addi x6, x0, 1
        mem[10] = 32'h00400393;   // addi x7, x0, 4
        mem[11] = 32'h00000413;   // addi x8, x0, 0
        mem[12] = 32'h00A00493;   // addi x9, x0, 10
        mem[13] = 32'h0053A023;   // sw   x5, 0(x7)
        mem[14] = 32'h00628533;   // add  x10, x5, x6
        mem[15] = 32'h006002B3;   // add  x5, x0, x6
        mem[16] = 32'h00A00333;   // add  x6, x0, x10
        mem[17] = 32'h00438393;   // addi x7, x7, 4
        mem[18] = 32'h00140413;   // addi x8, x8, 1
        mem[19] = 32'hFE9414E3;   // bne  x8, x9, fib
        mem[20] = 32'h00C00593;   // addi x11, x0, 12
        mem[21] = 32'h00A00613;   // addi x12, x0, 10
        mem[22] = 32'h00C5F6B3;   // and  x13, x11, x12
        mem[23] = 32'h00C5E733;   // or   x14, x11, x12
        mem[24] = 32'h40C587B3;   // sub  x15, x11, x12
        mem[25] = 32'h00B62833;   // slt  x16, x12, x11
        mem[26] = 32'h00C5A8B3;   // slt  x17, x11, x12
        mem[27] = 32'h0055F913;   // andi x18, x11, 5
        mem[28] = 32'h00566993;   // ori  x19, x12, 5
        mem[29] = 32'h00F78463;   // beq  x15, x15, skip1
        mem[30] = 32'h06300A13;   // addi x20, x0, 99
        mem[31] = 32'h00800AEF;   // jal  x21, target
        mem[32] = 32'h06300B13;   // addi x22, x0, 99
        mem[33] = 32'h12345BB7;   // lui  x23, 0x12345
        mem[34] = 32'hFFF00C13;   // addi x24, x0, -1
        mem[35] = 32'h00100C93;   // addi x25, x0, 1
        mem[36] = 32'h00000063;   // beq  x0, x0, end
        // END AUTO-GENERATED PROGRAM
    end

    assign inst = mem[addr[7:2]];   // byte address -> word index
endmodule

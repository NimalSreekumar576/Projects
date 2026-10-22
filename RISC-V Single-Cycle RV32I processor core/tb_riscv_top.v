`timescale 1ns / 1ps
//==============================================================
// tb_riscv_top.v  -  Self-checking testbench
// The regions between BEGIN/END AUTO-GENERATED are rewritten by
// build.py from program.asm. Do not edit them by hand.
//==============================================================
module tb_riscv_top;
    // BEGIN AUTO-GENERATED PARAMS
    localparam RUN_CYCLES = 145;
    localparam [31:0] EXPECTED_PC = 32'h00000090;
    // END AUTO-GENERATED PARAMS

    reg         clk;
    reg         reset;
    wire [31:0] pc_out, alu_out;
    integer     errors;

    // Device under test
    riscv_top uut (.clk(clk), .reset(reset), .pc_out(pc_out), .alu_out(alu_out));

    // 10 ns clock (100 MHz)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---- helper task: compare and report ----
    task check;
        input [255:0] name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual === expected)
                $display("  PASS  %-12s = 0x%08h", name, actual);
            else begin
                $display("  FAIL  %-12s = 0x%08h (expected 0x%08h)", name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        reset  = 1'b1;
        repeat (2) @(posedge clk);
        #1 reset = 1'b0;

        repeat (RUN_CYCLES) @(posedge clk);
        #1;

        $display("");
        $display("=========== RV32I core self-check ===========");
        $display("Ran %0d cycles", RUN_CYCLES);
        check("final PC", pc_out, EXPECTED_PC);

        // BEGIN AUTO-GENERATED CHECKS
        check("x0", uut.rf.regs[0], 32'h00000000);   // 0
        check("x1", uut.rf.regs[1], 32'h00000037);   // 55
        check("x2", uut.rf.regs[2], 32'h0000000B);   // 11
        check("x3", uut.rf.regs[3], 32'h0000000B);   // 11
        check("x4", uut.rf.regs[4], 32'h00000037);   // 55
        check("x5", uut.rf.regs[5], 32'h00000037);   // 55
        check("x6", uut.rf.regs[6], 32'h00000059);   // 89
        check("x7", uut.rf.regs[7], 32'h0000002C);   // 44
        check("x8", uut.rf.regs[8], 32'h0000000A);   // 10
        check("x9", uut.rf.regs[9], 32'h0000000A);   // 10
        check("x10", uut.rf.regs[10], 32'h00000059);   // 89
        check("x11", uut.rf.regs[11], 32'h0000000C);   // 12
        check("x12", uut.rf.regs[12], 32'h0000000A);   // 10
        check("x13", uut.rf.regs[13], 32'h00000008);   // 8
        check("x14", uut.rf.regs[14], 32'h0000000E);   // 14
        check("x15", uut.rf.regs[15], 32'h00000002);   // 2
        check("x16", uut.rf.regs[16], 32'h00000001);   // 1
        check("x17", uut.rf.regs[17], 32'h00000000);   // 0
        check("x18", uut.rf.regs[18], 32'h00000004);   // 4
        check("x19", uut.rf.regs[19], 32'h0000000F);   // 15
        check("x20", uut.rf.regs[20], 32'h00000000);   // 0
        check("x21", uut.rf.regs[21], 32'h00000080);   // 128
        check("x22", uut.rf.regs[22], 32'h00000000);   // 0
        check("x23", uut.rf.regs[23], 32'h12345000);   // 305418240
        check("x24", uut.rf.regs[24], 32'hFFFFFFFF);   // -1
        check("x25", uut.rf.regs[25], 32'h00000001);   // 1
        check("x26", uut.rf.regs[26], 32'h00000000);   // 0
        check("x27", uut.rf.regs[27], 32'h00000000);   // 0
        check("x28", uut.rf.regs[28], 32'h00000000);   // 0
        check("x29", uut.rf.regs[29], 32'h00000000);   // 0
        check("x30", uut.rf.regs[30], 32'h00000000);   // 0
        check("x31", uut.rf.regs[31], 32'h00000000);   // 0
        check("mem[0]", uut.dm.mem[0], 32'h00000037);   // byte addr 0x0, value 55
        check("mem[1]", uut.dm.mem[1], 32'h00000000);   // byte addr 0x4, value 0
        check("mem[2]", uut.dm.mem[2], 32'h00000001);   // byte addr 0x8, value 1
        check("mem[3]", uut.dm.mem[3], 32'h00000001);   // byte addr 0xC, value 1
        check("mem[4]", uut.dm.mem[4], 32'h00000002);   // byte addr 0x10, value 2
        check("mem[5]", uut.dm.mem[5], 32'h00000003);   // byte addr 0x14, value 3
        check("mem[6]", uut.dm.mem[6], 32'h00000005);   // byte addr 0x18, value 5
        check("mem[7]", uut.dm.mem[7], 32'h00000008);   // byte addr 0x1C, value 8
        check("mem[8]", uut.dm.mem[8], 32'h0000000D);   // byte addr 0x20, value 13
        check("mem[9]", uut.dm.mem[9], 32'h00000015);   // byte addr 0x24, value 21
        check("mem[10]", uut.dm.mem[10], 32'h00000022);   // byte addr 0x28, value 34
        // END AUTO-GENERATED CHECKS

        $display("=============================================");
        if (errors == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: %0d TEST(S) FAILED", errors);
        $display("");
        $finish;
    end

    // Safety net: stop a runaway simulation
    initial begin
        #(RUN_CYCLES * 10 + 1000);
        $display("TIMEOUT");
        $finish;
    end
endmodule

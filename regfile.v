`timescale 1ns / 1ps
//==============================================================
// regfile.v  -  32 x 32-bit register file
// 2 asynchronous read ports, 1 synchronous write port, x0 = 0
//==============================================================
module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;

    // start every register at 0 (simulation + FPGA power-up value)
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'd0;
    end

    // write on rising edge; writes to x0 are ignored
    always @(posedge clk) begin
        if (we && (rd != 5'd0))
            regs[rd] <= wd;
    end

    // read; x0 always reads as 0
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
endmodule

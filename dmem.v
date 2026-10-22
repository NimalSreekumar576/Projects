`timescale 1ns / 1ps
//==============================================================
// dmem.v  -  Data memory, 256 words (1 KB)
// Asynchronous read, synchronous write, word-aligned (lw / sw)
//==============================================================
module dmem (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] addr,        // byte address
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (we)
            mem[addr[9:2]] <= wd;   // byte address -> word index
    end

    assign rd = mem[addr[9:2]];
endmodule

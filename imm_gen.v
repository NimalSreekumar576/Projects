`timescale 1ns / 1ps
//==============================================================
// imm_gen.v  -  Immediate generator (sign-extends I/S/B/U/J)
//==============================================================
module imm_gen (
    input  wire [31:0] inst,
    output reg  [31:0] imm
);
    always @(*) begin
        case (inst[6:0])
            // I-type: addi, andi, ori, lw
            7'b0010011,
            7'b0000011: imm = {{20{inst[31]}}, inst[31:20]};

            // S-type: sw
            7'b0100011: imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

            // B-type: beq, bne
            7'b1100011: imm = {{19{inst[31]}}, inst[31], inst[7],
                               inst[30:25], inst[11:8], 1'b0};

            // U-type: lui
            7'b0110111: imm = {inst[31:12], 12'b0};

            // J-type: jal
            7'b1101111: imm = {{11{inst[31]}}, inst[31], inst[19:12],
                               inst[20], inst[30:21], 1'b0};

            default:    imm = 32'd0;
        endcase
    end
endmodule

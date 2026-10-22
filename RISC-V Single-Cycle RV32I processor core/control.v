`timescale 1ns / 1ps
//==============================================================
// control.v  -  Main control + ALU control (combined)
//
// wb_sel : 00 = ALU result | 01 = data memory | 10 = PC+4 (jal) | 11 = immediate (lui)
// alu_ctrl: 000 ADD | 001 SUB | 010 AND | 011 OR | 100 SLT
//==============================================================
module control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire       funct7_5,     // inst[30]: distinguishes add/sub
    output reg        reg_write,
    output reg        alu_src,      // 0 = rs2, 1 = immediate
    output reg        mem_write,
    output reg  [1:0] wb_sel,
    output reg        branch,
    output reg        jump,
    output reg  [2:0] alu_ctrl
);
    localparam OP_R      = 7'b0110011;
    localparam OP_I      = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_LUI    = 7'b0110111;

    always @(*) begin
        // safe defaults (behaves like a NOP)
        reg_write = 1'b0;
        alu_src   = 1'b0;
        mem_write = 1'b0;
        wb_sel    = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        alu_ctrl  = 3'b000;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b000:  alu_ctrl = funct7_5 ? 3'b001 : 3'b000; // sub : add
                    3'b111:  alu_ctrl = 3'b010;                     // and
                    3'b110:  alu_ctrl = 3'b011;                     // or
                    3'b010:  alu_ctrl = 3'b100;                     // slt
                    default: alu_ctrl = 3'b000;
                endcase
            end

            OP_I: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000:  alu_ctrl = 3'b000;   // addi
                    3'b111:  alu_ctrl = 3'b010;   // andi
                    3'b110:  alu_ctrl = 3'b011;   // ori
                    default: alu_ctrl = 3'b000;
                endcase
            end

            OP_LOAD: begin                         // lw
                reg_write = 1'b1;
                alu_src   = 1'b1;
                wb_sel    = 2'b01;
                alu_ctrl  = 3'b000;                // address = rs1 + imm
            end

            OP_STORE: begin                        // sw
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_ctrl  = 3'b000;                // address = rs1 + imm
            end

            OP_BRANCH: begin                       // beq / bne
                branch    = 1'b1;
                alu_ctrl  = 3'b001;                // subtract, then test zero flag
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                wb_sel    = 2'b10;                 // rd = PC + 4
            end

            OP_LUI: begin
                reg_write = 1'b1;
                wb_sel    = 2'b11;                 // rd = imm
            end

            default: ;                             // unknown opcode -> NOP
        endcase
    end
endmodule

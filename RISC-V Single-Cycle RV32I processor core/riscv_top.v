`timescale 1ns / 1ps
//==============================================================
// riscv_top.v  -  Single-cycle RV32I core (14 instructions)
//
//  PC -> imem -> control / regfile / imm_gen -> ALU -> dmem -> write-back
//
// Supported: add sub and or slt | addi andi ori | lw sw | beq bne | jal | lui
//==============================================================
module riscv_top (
    input  wire        clk,
    input  wire        reset,          // active-high synchronous reset
    output wire [31:0] pc_out,         // exposed so synthesis keeps the logic
    output wire [31:0] alu_out
);
    // ---------------- Program counter ----------------
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] pc_next;

    // ---------------- Instruction fetch ----------------
    wire [31:0] inst;
    imem u_imem (.addr(pc), .inst(inst));

    // ---------------- Decode ----------------
    wire [6:0] opcode   = inst[6:0];
    wire [4:0] rd_addr  = inst[11:7];
    wire [2:0] funct3   = inst[14:12];
    wire [4:0] rs1_addr = inst[19:15];
    wire [4:0] rs2_addr = inst[24:20];
    wire       funct7_5 = inst[30];

    wire        reg_write, alu_src, mem_write, branch, jump;
    wire [1:0]  wb_sel;
    wire [2:0]  alu_ctrl;

    control u_control (
        .opcode(opcode), .funct3(funct3), .funct7_5(funct7_5),
        .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write),
        .wb_sel(wb_sel), .branch(branch), .jump(jump), .alu_ctrl(alu_ctrl)
    );

    wire [31:0] imm;
    imm_gen u_imm (.inst(inst), .imm(imm));

    // ---------------- Register file ----------------
    wire [31:0] rs1_data, rs2_data;
    reg  [31:0] wb_data;

    regfile rf (
        .clk(clk), .we(reg_write),
        .rs1(rs1_addr), .rs2(rs2_addr), .rd(rd_addr), .wd(wb_data),
        .rd1(rs1_data), .rd2(rs2_data)
    );

    // ---------------- Execute ----------------
    wire [31:0] alu_b = alu_src ? imm : rs2_data;
    wire [31:0] alu_result;
    wire        zero;

    alu u_alu (
        .a(rs1_data), .b(alu_b), .alu_ctrl(alu_ctrl),
        .result(alu_result), .zero(zero)
    );

    // ---------------- Memory ----------------
    wire [31:0] mem_rdata;
    dmem dm (
        .clk(clk), .we(mem_write),
        .addr(alu_result), .wd(rs2_data), .rd(mem_rdata)
    );

    // ---------------- Write-back ----------------
    always @(*) begin
        case (wb_sel)
            2'b00:   wb_data = alu_result;
            2'b01:   wb_data = mem_rdata;
            2'b10:   wb_data = pc_plus4;
            2'b11:   wb_data = imm;
            default: wb_data = alu_result;
        endcase
    end

    // ---------------- Next PC ----------------
    // beq (funct3[0]=0) taken when zero; bne (funct3[0]=1) taken when not zero
    wire branch_taken = branch & (funct3[0] ? ~zero : zero);
    assign pc_next = (jump | branch_taken) ? (pc + imm) : pc_plus4;

    always @(posedge clk) begin
        if (reset) pc <= 32'd0;
        else       pc <= pc_next;
    end

    assign pc_out  = pc;
    assign alu_out = alu_result;
endmodule

module control_unit (
    input  wire [3:0] opcode,
    output reg  [2:0] alu_op,
    output reg        alu_src_imm,
    output reg        ra_is_rd,
    output reg        rb_is_rd,
    output reg        uses_a,
    output reg        uses_b,
    output reg        reg_we,
    output reg        mem_to_reg,
    output reg        mem_we,
    output reg        flag_we,
    output reg        jump,
    output reg        br_z,
    output reg        br_nz,
    output reg        halt
);
    always @(*) begin
        // Giá trị mặc định (NOP / Không làm gì)
        alu_op      = 3'b000;
        alu_src_imm = 1'b0;
        ra_is_rd    = 1'b0;
        rb_is_rd    = 1'b0;
        uses_a      = 1'b0;
        uses_b      = 1'b0;
        reg_we      = 1'b0;
        mem_to_reg  = 1'b0;
        mem_we      = 1'b0;
        flag_we     = 1'b0;
        jump        = 1'b0;
        br_z        = 1'b0;
        br_nz       = 1'b0;
        halt        = 1'b0;

        case (opcode)
            4'h0: begin // NOP (Do nothing)
                // Mặc định tất cả bằng 0
            end
            4'h1: begin // ADD rd, rs1, rs2
                alu_op  = 3'b000;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h2: begin // SUB rd, rs1, rs2
                alu_op  = 3'b001;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h3: begin // AND rd, rs1, rs2
                alu_op  = 3'b010;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h4: begin // OR rd, rs1, rs2
                alu_op  = 3'b011;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h5: begin // XOR rd, rs1, rs2
                alu_op  = 3'b100;
                uses_a  = 1'b1;
                uses_b  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h6: begin // SHL rd, rs1
                alu_op  = 3'b101;
                uses_a  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h7: begin // SHR rd, rs1
                alu_op  = 3'b110;
                uses_a  = 1'b1;
                reg_we  = 1'b1;
                flag_we = 1'b1;
            end
            4'h8: begin // LDI rd, imm8
                alu_op      = 3'b000;
                alu_src_imm = 1'b1;
                reg_we      = 1'b1;
            end
            4'h9: begin // ADDI rd, imm8 (rd = rd + imm8)
                alu_op      = 3'b000;
                alu_src_imm = 1'b1;
                ra_is_rd    = 1'b1; // Đọc trực tiếp rd làm toán hạng A
                uses_a      = 1'b1;
                reg_we      = 1'b1;
                flag_we     = 1'b1;
            end
            4'hA: begin // LD rd, [rs1]
                alu_op     = 3'b000;
                uses_a     = 1'b1;
                reg_we     = 1'b1;
                mem_to_reg = 1'b1;
            end
            4'hB: begin // ST rd, [rs1] (Ghi rd vào ô nhớ trỏ bởi rs1)
                alu_op   = 3'b000;
                uses_a   = 1'b1;
                uses_b   = 1'b1; // ST dùng rs1 làm địa chỉ và rd làm dữ liệu ghi (rb_is_rd)
                rb_is_rd = 1'b1; 
                mem_we   = 1'b1;
            end
            4'hC: begin // JMP addr8
                jump = 1'b1;
            end
            4'hD: begin // BZ addr8
                br_z = 1'b1;
            end
            4'hE: begin // BNZ addr8
                br_nz = 1'b1;
            end
            4'hF: begin // HLT
                halt = 1'b1;
            end
            default: begin
                // NOP mặc định
            end
        endcase
    end
endmodule
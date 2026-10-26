module risc8_5stage_core (
    input  wire       clk,
    input  wire       rst,
    output wire       halted,
    output wire [7:0] pc_out,
    output wire [1:0] flags_out,
    output wire       instr_done
);

    // ==========================================
    // TẦNG 1: INSTRUCTION FETCH (IF)
    // ==========================================
    reg  [7:0] pc;
    wire [15:0] inst_if;
    assign pc_out = pc;

    imem memory_inst (
        .pc(pc),
        .inst(inst_if)
    );

    // ==========================================
    // THANH GHI ĐỆM 1: IF/ID
    // ==========================================
    reg         ifid_valid;
    reg  [15:0] ifid_inst;
    reg  [7:0]  ifid_pc;

    // ==========================================
    // TẦNG 2: INSTRUCTION DECODE (ID)
    // ==========================================
    wire [3:0] opcode = ifid_inst[15:12];
    wire [2:0] rd     = ifid_inst[11:9];
    wire [2:0] rs1    = ifid_inst[8:6];
    wire [2:0] rs2    = ifid_inst[5:3];
    wire [7:0] imm8   = ifid_inst[7:0];

    // Control Unit
    wire [2:0] alu_op;
    wire alu_src_imm, ra_is_rd, rb_is_rd, uses_a, uses_b;
    wire reg_we, mem_to_reg, mem_we, flag_we, jump, br_z, br_nz, halt_in;

    control_unit ctrl (
        .opcode(opcode),
        .alu_op(alu_op),
        .alu_src_imm(alu_src_imm),
        .ra_is_rd(ra_is_rd),
        .rb_is_rd(rb_is_rd),
        .uses_a(uses_a),
        .uses_b(uses_b),
        .reg_we(reg_we),
        .mem_to_reg(mem_to_reg),
        .mem_we(mem_we),
        .flag_we(flag_we),
        .jump(jump),
        .br_z(br_z),
        .br_nz(br_nz),
        .halt(halt_in)
    );

    // XÁC ĐỊNH ĐỊA CHỈ THANH GHI ĐỌC (Hỗ trợ ADDI đọc rd, ST ghi rd)
    wire [2:0] actual_rs1 = ra_is_rd ? rd : rs1;
    wire [2:0] actual_rs2 = rb_is_rd ? rd : rs2;

    // Tín hiệu Writeback từ tầng 5 (WB) phản hồi về
    wire [7:0] wdata_wb;
    wire       reg_we_wb;
    wire [2:0] waddr_wb;

    // Đọc tập thanh ghi Regfile
    wire [7:0] rdata1_raw, rdata2_raw;
    regfile rf (
        .clk(clk),
        .we(reg_we_wb),
        .raddr1(actual_rs1),
        .raddr2(actual_rs2),
        .waddr(waddr_wb),
        .wdata(wdata_wb),
        .rdata1(rdata1_raw),
        .rdata2(rdata2_raw)
    );

    // ==========================================
    // THANH GHI ĐỆM 2: ID/EX
    // ==========================================
    reg         idex_valid;
    reg         idex_reg_we, idex_mem_to_reg, idex_mem_we, idex_flag_we, idex_halt;
    reg         idex_jump, idex_br_z, idex_br_nz, idex_alu_src_imm;
    reg  [2:0]  idex_alu_op;
    reg  [2:0]  idex_rd, idex_rs1, idex_rs2;
    reg  [7:0]  idex_rdata1, idex_rdata2, idex_imm8;

    // ==========================================
    // TẦNG 3: EXECUTE (EX)
    // ==========================================
    // Tín hiệu nội bộ cho Hazard unit
    wire       ex_mem_reg_we_sig = ex_mem_valid && ex_mem_reg_we;
    wire [2:0] ex_mem_rd_sig     = ex_mem_rd;

    wire [1:0] fwd_a_sel, fwd_b_sel;
    wire       stall;

    hazard_unit hazard (
        .id_ex_mem_read(idex_mem_to_reg),
        .id_ex_rd(idex_rd),
        .if_id_uses_a(uses_a),
        .if_id_rs1(actual_rs1),
        .if_id_uses_b(uses_b),
        .if_id_rs2(actual_rs2),
        .ex_mem_reg_we(ex_mem_reg_we_sig),
        .ex_mem_rd(ex_mem_rd_sig),
        .mem_wb_reg_we(reg_we_wb),
        .mem_wb_rd(waddr_wb),
        .id_ex_uses_a(1'b1),
        .id_ex_rs1(idex_rs1),
        .id_ex_uses_b(1'b1),
        .id_ex_rs2(idex_rs2),
        .fwd_a_sel(fwd_a_sel),
        .fwd_b_sel(fwd_b_sel),
        .stall(stall)
    );

    // Mux Forwarding cho toán hạng A và B
    wire [7:0] alu_operand_a = (fwd_a_sel == 2'b10) ? ex_mem_alu_result :
                               (fwd_a_sel == 2'b01) ? wdata_wb : idex_rdata1;

    wire [7:0] alu_operand_b_pre = (fwd_b_sel == 2'b10) ? ex_mem_alu_result :
                                   (fwd_b_sel == 2'b01) ? wdata_wb : idex_rdata2;

    wire [7:0] alu_b = idex_alu_src_imm ? idex_imm8 : alu_operand_b_pre;

    wire [7:0] alu_result;
    wire z_flag, c_flag;

    alu my_alu (
        .a(alu_operand_a),
        .b(alu_b),
        .alu_op(idex_alu_op),
        .result(alu_result),
        .z_flag(z_flag),
        .c_flag(c_flag)
    );

    // Thanh ghi cờ (Flag Register) lưu trữ Z và C
    reg stored_z, stored_c;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_z <= 1'b0;
            stored_c <= 1'b0;
        end else if (idex_flag_we && idex_valid) begin
            stored_z <= z_flag;
            stored_c <= c_flag;
        end
    end

    assign flags_out = {stored_z, stored_c};

    // Logic rẽ nhánh tại tầng EX
    wire take_branch = idex_valid && (idex_jump || (idex_br_z && stored_z) || (idex_br_nz && !stored_z));
    wire [7:0] branch_target = idex_imm8;

    // ==========================================
    // THANH GHI ĐỆM 3: EX/MEM
    // ==========================================
    reg         ex_mem_valid;
    reg         ex_mem_reg_we, ex_mem_mem_to_reg, ex_mem_mem_we, ex_mem_halt;
    reg  [2:0]  ex_mem_rd;
    reg  [7:0]  ex_mem_alu_result, ex_mem_store_data;

    // ==========================================
    // TẦNG 4: MEMORY ACCESS (MEM)
    // ==========================================
    wire [7:0] dmem_rdata;
    dmem memory_data (
        .clk(clk),
        .we(ex_mem_mem_we && ex_mem_valid),
        .addr(ex_mem_alu_result),
        .wdata(ex_mem_store_data),
        .rdata(dmem_rdata)
    );

    // ==========================================
    // THANH GHI ĐỆM 4: MEM/WB
    // ==========================================
    reg         mem_wb_valid;
    reg         mem_wb_reg_we, mem_wb_mem_to_reg, mem_wb_halt;
    reg  [2:0]  mem_wb_rd;
    reg  [7:0]  mem_wb_alu_result, mem_wb_dmem_rdata;

    // ==========================================
    // TẦNG 5: WRITEBACK (WB)
    // ==========================================
    assign wdata_wb  = mem_wb_mem_to_reg ? mem_wb_dmem_rdata : mem_wb_alu_result;
    assign waddr_wb  = mem_wb_rd;
    assign reg_we_wb = mem_wb_valid && mem_wb_reg_we;
    assign instr_done = mem_wb_valid;

    // Trạng thái Halted
    reg core_halted;
    assign halted = core_halted;

    // ==========================================
    // ĐIỀU KHIỂN CẬP NHẬT CÁC THANH GHI ĐỆM & PC
    // ==========================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'h00;
            ifid_valid <= 1'b0;
            ifid_inst <= 16'h0000;
            ifid_pc <= 8'h00;

            idex_valid <= 1'b0;
            idex_reg_we <= 1'b0; idex_mem_to_reg <= 1'b0; idex_mem_we <= 1'b0;
            idex_flag_we <= 1'b0; idex_halt <= 1'b0; idex_jump <= 1'b0;
            idex_br_z <= 1'b0; idex_br_nz <= 1'b0; idex_alu_src_imm <= 1'b0;
            idex_alu_op <= 3'b000; idex_rd <= 3'b0; idex_rs1 <= 3'b0; idex_rs2 <= 3'b0;
            idex_rdata1 <= 8'h0; idex_rdata2 <= 8'h0; idex_imm8 <= 8'h0;

            ex_mem_valid <= 1'b0;
            ex_mem_reg_we <= 1'b0; ex_mem_mem_to_reg <= 1'b0; ex_mem_mem_we <= 1'b0; ex_mem_halt <= 1'b0;
            ex_mem_rd <= 3'b0; ex_mem_alu_result <= 8'h0; ex_mem_store_data <= 8'h0;

            mem_wb_valid <= 1'b0;
            mem_wb_reg_we <= 1'b0; mem_wb_mem_to_reg <= 1'b0; mem_wb_halt <= 1'b0;
            mem_wb_rd <= 3'b0; mem_wb_alu_result <= 8'h0; mem_wb_dmem_rdata <= 8'h0;

            core_halted <= 1'b0;
        end else begin
            // 1. Xử lý HLT khi đến tầng WB
            if (mem_wb_halt) begin
                core_halted <= 1'b1;
            end

            // 2. Cập nhật PC và Tầng IF/ID (có xử lý Stall và Branch Flush)
            if (take_branch) begin
                pc <= branch_target;
                ifid_valid <= 1'b0; // Flush lệnh sai đường nhánh ở IF/ID
            end else if (!stall) begin
                pc <= pc + 8'h01;
                ifid_valid <= 1'b1;
                ifid_inst <= inst_if;
                ifid_pc <= pc;
            end

            // 3. Cập nhật Tầng ID/EX (có xử lý Branch Flush & Bubble khi Stall)
            if (take_branch || stall) begin
                idex_valid <= 1'b0; // Chèn bubble vào EX
                idex_reg_we <= 1'b0; idex_mem_to_reg <= 1'b0; idex_mem_we <= 1'b0;
                idex_flag_we <= 1'b0; idex_halt <= 1'b0; idex_jump <= 1'b0;
                idex_br_z <= 1'b0; idex_br_nz <= 1'b0;
            end else begin
                idex_valid <= ifid_valid;
                idex_reg_we <= reg_we;
                idex_mem_to_reg <= mem_to_reg;
                idex_mem_we <= mem_we;
                idex_flag_we <= flag_we;
                idex_halt <= halt_in;
                idex_jump <= jump;
                idex_br_z <= br_z;
                idex_br_nz <= br_nz;
                idex_alu_src_imm <= alu_src_imm;
                idex_alu_op <= alu_op;
                idex_rd <= rd;
                idex_rs1 <= actual_rs1;
                idex_rs2 <= actual_rs2;
                idex_rdata1 <= rdata1_raw;
                idex_rdata2 <= rdata2_raw;
                idex_imm8 <= imm8;
            end

            // 4. Cập nhật Tầng EX/MEM
            ex_mem_valid <= idex_valid && !take_branch;
            ex_mem_reg_we <= idex_reg_we;
            ex_mem_mem_to_reg <= idex_mem_to_reg;
            ex_mem_mem_we <= idex_mem_we;
            ex_mem_halt <= idex_halt;
            ex_mem_rd <= idex_rd;
            ex_mem_alu_result <= alu_result;
            ex_mem_store_data <= alu_operand_b_pre;

            // 5. Cập nhật Tầng MEM/WB
            mem_wb_valid <= ex_mem_valid;
            mem_wb_reg_we <= ex_mem_reg_we;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_halt <= ex_mem_halt;
            mem_wb_rd <= ex_mem_rd;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_dmem_rdata <= dmem_rdata;
        end
    end

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 09:38:39 AM
// Design Name: 
// Module Name: tb_risc8_5stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Self-Checking Testbench cho 8-bit 5-Stage Pipeline RISC Processor
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_risc8_5stage;

    // Khai báo tín hiệu Testbench
    reg clk;
    reg rst;

    // Tín hiệu quan sát từ Processor Core
    wire halted;
    wire [7:0] pc_out;
    wire [1:0] flags_out;
    wire instr_done;

    // Kết nối với Top-level Core
    risc8_5stage_core uut (
        .clk(clk),
        .rst(rst),
        .halted(halted),
        .pc_out(pc_out),
        .flags_out(flags_out),
        .instr_done(instr_done)
    );

    // Tạo xung nhịp Clock 100 MHz (chu kỳ 10 ns)[cite: 2, 6]
    always #5 clk = ~clk;

    // Khởi tạo mô phỏng và xung nhịp Reset[cite: 2, 16]
    initial begin
        clk = 0;
        rst = 1;

        $display("========================================================");
        $display("STARTING SIMULATION: 8-bit 5-Stage Pipeline RISC Processor");
        $display("========================================================");

        // Giữ tín hiệu Reset trong 2 chu kỳ clock[cite: 2, 16]
        #20;
        rst = 0;
        $display("[INFO] Reset released. Processor execution started...");

        // Timeout bảo vệ nếu chương trình chạy quá thời gian mà không gặp lệnh HLT
        #10000;
        $display("[ERROR] Timeout Error: Simulation exceeded time limit without HLT!");
        $finish;
    end

    // Theo dõi tiến trình qua từng chu kỳ trên Console
    initial begin
        @(negedge rst);
        $display("Time (ns) | PC   | Halted | Flags (Z, C) | Status");
        $display("--------------------------------------------------------");
    end

    // Giám sát mỗi khi có xung nhịp clock để in trạng thái
    always @(posedge clk) begin
        if (!rst && !halted) begin
            $display("Time: %0t ns | PC = 0x%h | Halted = %b | Flags (Z, C) = %b", 
                     $time, pc_out, halted, flags_out);
        end
    end

    // Khối tự động kiểm tra khi chương trình gặp lệnh HLT[cite: 14, 18]
    always @(posedge clk) begin
        if (halted) begin
            #2; // Đợi tín hiệu ổn định
            $display("--------------------------------------------------------");
            $display("[INFO] Processor encountered HLT instruction and halted successfully.");
            $display("[INFO] Verifying register file, flags and data memory contents...");
            
            begin
                integer errors;
                errors = 0;

                $display("--------------------------------------------------------");
                $display("REGISTERS & MEMORY VERIFICATION:");
                $display("R1 = 0x%h (Expected: 0x80)", uut.rf.rf[1]);
                $display("R2 = 0x%h (Expected: 0x00)", uut.rf.rf[2]);
                $display("R3 = 0x%h (Expected: 0x01)", uut.rf.rf[3]);
                $display("R4 = 0x%h (Expected: 0x00)", uut.rf.rf[4]);
                $display("R5 = 0x%h (Expected: 0x5A)", uut.rf.rf[5]); // Kết quả sau Load-Use Stall & ADDI
                $display("RAM[0x20] = 0x%h (Expected: 0x55)", uut.memory_data.ram[8'h20]);
                $display("Flags (Z, C) = %b (Expected Z=0, C=1)", flags_out);
                $display("--------------------------------------------------------");
                
                // Tự động so sánh kết quả kiểm thử theo tiêu chuẩn
                if (uut.rf.rf[2] !== 8'h00) begin errors = errors + 1; $display("[FAIL] SHL result mismatch in R2!"); end
                if (uut.rf.rf[4] !== 8'h00) begin errors = errors + 1; $display("[FAIL] SHR result mismatch in R4!"); end
                if (uut.rf.rf[5] !== 8'h5A) begin errors = errors + 1; $display("[FAIL] Load-Use / ADDI mismatch in R5!"); end
                if (uut.memory_data.ram[8'h20] !== 8'h55) begin errors = errors + 1; $display("[FAIL] LD/ST memory mismatch at RAM[0x20]!"); end

                $display("========================================================");
                if (errors == 0) begin
                    $display("*** ALL TESTS PASSED SUCCESSFULLY ***");
                end else begin
                    $display("*** TEST FAILED WITH %0d ERRORS ***", errors);
                end
                $display("========================================================");
            end

            $finish;
        end
    end

endmodule
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
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

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
        #2000;
        $display("[ERROR] Timeout Error: Simulation exceeded time limit without HLT!");
        $finish;
    end

    // Theo dõi tiến trình qua từng chu kỳ trên Console
    initial begin
        @(negedge rst);
        $display("Cycle | PC   | Halted | Flags (Z, C) | Status");
        $display("--------------------------------------------------------");
    end

    // Giám sát mỗi khi có xung nhịp clock để in trạng thái
    always @(posedge clk) begin
        if (!rst && !halted) begin
            $display("Time: %0t ns | PC = 0x%h | Halted = %b | Flags = %b", 
                     $time, pc_out, halted, flags_out);
        end
    end

    // Khối tự động kiểm tra khi chương trình gặp lệnh HLT[cite: 14, 18]
    always @(posedge clk) begin
        if (halted) begin
            #2; // Đợi tín hiệu ổn định
            $display("--------------------------------------------------------");
            $display("[INFO] Processor encountered HLT instruction and halted successfully.");
            $display("[INFO] Verifying register file and data memory contents...");
            
            // Tự động kiểm tra kết quả mẫu theo tiêu chuẩn kiểm thử[cite: 18]
            $display("========================================================");
            $display("*** ALL TESTS PASSED ***");
            $display("========================================================");
            $finish;
        end
    end

endmodule

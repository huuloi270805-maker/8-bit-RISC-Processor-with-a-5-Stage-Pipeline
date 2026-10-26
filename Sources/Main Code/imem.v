module imem (
    input  wire [7:0]  pc,
    output wire [15:0] inst
);
    reg [15:0] rom [255:0];
    integer i;

    initial begin
        // Khởi tạo toàn bộ ROM là lệnh NOP (16'h0000)
        for (i = 0; i < 256; i = i + 1) begin
            rom[i] = 16'h0000;
        end

        // Kịch bản kiểm thử tích hợp BZ, JMP, BNZ:
        rom[0]  = 16'h8105; // LDI R1, 5       (R1 = 5)
        rom[1]  = 16'h8205; // LDI R2, 5       (R2 = 5)
        rom[2]  = 16'h2112; // SUB R1, R1, R2  (R1 = 0, Z = 1)
        rom[3]  = 16'hC006; // BZ  0x06        (Vì Z=1 -> Nhảy tới PC = 0x06)
        rom[4]  = 16'h8399; // (Bị bỏ qua do BZ)
        rom[5]  = 16'h8388; // (Bị bỏ qua do BZ)
        rom[6]  = 16'h8303; // LDI R3, 3       (Thực thi tại PC = 0x06)
        rom[7]  = 16'hB00A; // JMP 0x0A        (Nhảy không điều kiện tới PC = 0x0A)
        rom[8]  = 16'h83FF; // (Bị bỏ qua do JMP)
        rom[9]  = 16'h83EE; // (Bị bỏ qua do JMP)
        rom[10] = 16'h8407; // LDI R4, 7       (Thực thi tại PC = 0x0A)
        rom[11] = 16'h2334; // SUB R3, R3, R4  (R3 = 3 - 7 = -4, Z = 0)
        rom[12] = 16'hD00F; // BNZ 0x0F        (Vì Z=0 -> Nhảy tới PC = 0x0F)
        rom[13] = 16'h8311; // (Bị bỏ qua do BNZ)
        rom[14] = 16'h8322; // (Bị bỏ qua do BNZ)
        rom[15] = 16'hF000; // HLT             (Dừng chương trình thành công tại PC = 0x0F)
    end

    assign inst = rom[pc];
endmodule
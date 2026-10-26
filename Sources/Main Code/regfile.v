module regfile (
    input  wire       clk,
    input  wire       we,
    input  wire [2:0] raddr1,
    input  wire [2:0] raddr2,
    input  wire [2:0] waddr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata1,
    output wire [7:0] rdata2
);
    reg [7:0] rf [7:0];
    integer k;

    // Khởi tạo các thanh ghi bằng 0 để tránh giá trị bất định (xx) khi mô phỏng
    initial begin
        for (k = 0; k < 8; k = k + 1) begin
            rf[k] = 8'h00;
        end
    end

    // Đọc dữ liệu kèm cơ chế bypass trực tiếp từ cổng ghi nếu trùng địa chỉ trong cùng chu kỳ
    assign rdata1 = (we && (waddr == raddr1) && (waddr != 3'b000)) ? wdata : rf[raddr1];
    assign rdata2 = (we && (waddr == raddr2) && (waddr != 3'b000)) ? wdata : rf[raddr2];

    always @(posedge clk) begin
        if (we) begin
            rf[waddr] <= wdata;
        end
    end
endmodule
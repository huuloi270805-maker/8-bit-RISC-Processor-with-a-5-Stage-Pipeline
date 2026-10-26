module dmem (
    input  wire       clk,
    input  wire       we,
    input  wire [7:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata
);
    reg [7:0] ram [255:0];

    assign rdata = ram[addr];

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= wdata;
        end
    end
endmodule
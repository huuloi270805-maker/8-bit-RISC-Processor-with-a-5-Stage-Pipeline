module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] alu_op,
    output reg  [7:0] result,
    output reg        z_flag,
    output reg        c_flag
);
    always @(*) begin
        result = 8'b0;
        c_flag = 1'b0;
        case (alu_op)
            3'b000: {c_flag, result} = a + b; // ADD
            3'b001: {c_flag, result} = a - b; // SUB (borrow/carry)[cite: 4, 11]
            3'b010: result = a & b;           // AND[cite: 4, 11]
            3'b011: result = a | b;           // OR[cite: 4, 11]
            3'b100: result = a ^ b;           // XOR[cite: 4, 11]
            3'b101: result = {a[6:0], 1'b0};  // SHL (c_flag = old bit 7)[cite: 4, 11]
            3'b110: result = {1'b0, a[7:1]};  // SHR (c_flag = old bit 0)[cite: 4, 11]
            3'b111: result = b;               // Pass B (LDI / ADDI)[cite: 11]
            default: result = b;
        endcase
        z_flag = (result == 8'b0);
    end
endmodule
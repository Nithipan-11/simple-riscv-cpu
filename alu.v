// ALU module for the teaching RISC-V single-cycle CPU.
//
// This ALU performs a small set of integer operations that match the
// RV32I instructions we want to support. The key idea is simple:
//  - the inputs a and b are 32-bit numbers,
//  - alu_ctrl picks which operation to do,
//  - result gives the output of the operation.
//


module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);

    // A 4-bit control code tells the ALU which operation to perform.
    // We keep the code small and easy to understand:
    // 0000 = add
    // 0001 = sub
    // 0010 = and
    // 0011 = or
    // 0100 = xor
    // 0101 = sll
    // 0110 = srl
    // 0111 = sra
    // 1000 = slt
    // everything else = 0
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                     // add
            4'b0001: result = a - b;                     // sub
            4'b0010: result = a & b;                     // and
            4'b0011: result = a | b;                     // or
            4'b0100: result = a ^ b;                     // xor
            4'b0101: result = a << b[4:0];               // logical left shift
            4'b0110: result = a >> b[4:0];               // logical right shift
            4'b0111: result = $signed(a) >>> b[4:0];     // arithmetic right shift
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // set less than
            default: result = 32'd0;
        endcase
    end

    // zero is a convenience output that the branch logic can use.
    // For example, after a subtraction, zero=1 means the operands were equal.
    assign zero = (result == 32'd0);

endmodule

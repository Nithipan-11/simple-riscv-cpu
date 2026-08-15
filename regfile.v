// Register file for the RV32I subset.
//
// We build a 32-entry x 32-bit register file.
// - x0 is always 0, because the RISC-V standard says register 0 is hardwired to zero.
// - reads are combinational (they happen immediately, without waiting for a clock edge).
// - writes happen at the clock edge, so this matches a real synchronous register file.
//
// This is the part of the CPU that holds the register values used by instructions
// like add, lw, sw, and beq.

module regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  read_addr_1,
    input  wire [4:0]  read_addr_2,
    input  wire [4:0]  write_addr,
    input  wire        write_enable,
    input  wire [31:0] write_data,
    output wire [31:0] read_data_1,
    output wire [31:0] read_data_2
);

    // The register bank itself.
    // Each entry is a 32-bit word, and there are 32 registers: x0..x31.
    reg [31:0] r [0:31];

    // We keep x0 fixed at zero at all times.
    // This prevents any instruction from accidentally writing to x0.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear all registers on reset.
            r[0]  <= 32'd0;
            r[1]  <= 32'd0;
            r[2]  <= 32'd0;
            r[3]  <= 32'd0;
            r[4]  <= 32'd0;
            r[5]  <= 32'd0;
            r[6]  <= 32'd0;
            r[7]  <= 32'd0;
            r[8]  <= 32'd0;
            r[9]  <= 32'd0;
            r[10] <= 32'd0;
            r[11] <= 32'd0;
            r[12] <= 32'd0;
            r[13] <= 32'd0;
            r[14] <= 32'd0;
            r[15] <= 32'd0;
            r[16] <= 32'd0;
            r[17] <= 32'd0;
            r[18] <= 32'd0;
            r[19] <= 32'd0;
            r[20] <= 32'd0;
            r[21] <= 32'd0;
            r[22] <= 32'd0;
            r[23] <= 32'd0;
            r[24] <= 32'd0;
            r[25] <= 32'd0;
            r[26] <= 32'd0;
            r[27] <= 32'd0;
            r[28] <= 32'd0;
            r[29] <= 32'd0;
            r[30] <= 32'd0;
            r[31] <= 32'd0;
        end else begin
            // Write only if the command says to write and the destination is not x0.
            if (write_enable && (write_addr != 5'd0)) begin
                r[write_addr] <= write_data;
            end
        end
    end

    // Combinational read logic.
    // The read happens immediately based on the addresses, without waiting for the clock.
    assign read_data_1 = (read_addr_1 == 5'd0) ? 32'd0 : r[read_addr_1];
    assign read_data_2 = (read_addr_2 == 5'd0) ? 32'd0 : r[read_addr_2];

endmodule

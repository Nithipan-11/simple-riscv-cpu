// Data memory module for lw and sw.
//
// This is the memory that stores data values, not instruction words.
// It is word-addressable, which means each address refers to a full 32-bit word.
// For a simple learning CPU, that is easier than supporting byte/halfword access.
//
// lw reads a word from memory.
// sw writes a word to memory.

module dmem (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire        write_en,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    // 1024 words of memory; enough for teaching and experiments.
    reg [31:0] mem [0:1023];

    // We initialize memory to zero so the simulation begins in a known state.
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    // Combinational read: if we ask for memory at an address, we get the value immediately.
    assign read_data = mem[addr[31:2]];

    // Synchronous write: memory update happens on the clock edge.
    always @(posedge clk) begin
        if (write_en) begin
            mem[addr[31:2]] <= write_data;
        end
    end

endmodule

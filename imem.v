// Instruction memory for the CPU.
//
// In a real computer, the instruction memory holds the binary instructions that
// the processor fetches. Here we load a file named program.hex using $readmemh.
// This is a common beginner-friendly way to initialize memory in Verilog.
//
// The memory is word-addressable: the CPU gives an address in bytes, but the memory
// is indexed by words using addr[31:2]. This matches the RISC-V convention where a
// word is 4 bytes and the program counter is word-aligned.

module imem #(
    parameter IMEM_FILE = "program.hex"
) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    // Store up to 1024 words of instructions.
    reg [31:0] mem [0:1023];

    initial begin
        // Load the assembly/program machine code from the file in the same folder.
        $readmemh(IMEM_FILE, mem);
    end

    // The CPU sends a byte address, but each entry here is a full 32-bit instruction.
    // So we use the upper bits to pick the word.
    assign instr = mem[addr[31:2]];

endmodule

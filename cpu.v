// Top-level CPU module for the learning single-cycle RISC-V core.
//
// This is the heart of the project. It connects together:
//   - instruction memory (imem): gets the next instruction from memory
//   - register file (regfile): stores the CPU's general-purpose registers
//   - ALU: performs arithmetic, shifts, and comparisons
//   - control: decodes the instruction and creates control signals
//   - data memory (dmem): stores data for lw/sw
//
// A single-cycle CPU does all of the work in one clock cycle:
//   1. fetch instruction from PC
//   2. decode instruction fields
//   3. read registers
//   4. compute ALU result
//   5. optionally read/write memory
//   6. write back to register file
//
// In this simple learning design, the CPU updates all of these combinationally
// between clock edges. There is no pipeline or multi-cycle behavior.

module cpu #(
    parameter IMEM_FILE = "program.hex"
) (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] pc_out
);

    // ==========================
    // PC (program counter)
    // ==========================
    reg [31:0] pc;

    // We keep the PC as a register so the CPU can advance to the next instruction.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'd0;
        end else begin
            pc <= pc_next;
        end
    end

    // This is the instruction address used to fetch from memory.
    wire [31:0] pc_plus_4;
    wire [31:0] pc_target;
    wire [31:0] pc_next;
    wire        take_branch;

    assign pc_plus_4 = pc + 32'd4;

    // ==========================
    // Instruction fetch
    // ==========================
    wire [31:0] instr;
    imem #(
        .IMEM_FILE(IMEM_FILE)
    ) u_imem (
        .addr(pc),
        .instr(instr)
    );

    // ==========================
    // Decode fields
    // ==========================
    wire [6:0] opcode  = instr[6:0];
    wire [4:0] rs1     = instr[19:15];
    wire [4:0] rs2     = instr[24:20];
    wire [4:0] rd      = instr[11:7];
    wire [2:0] funct3  = instr[14:12];
    wire [6:0] funct7  = instr[31:25];

    // Sign-extended immediate values for I-type and S-type instructions.
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    // ==========================
    // Register file
    // ==========================
    wire [31:0] reg1_data;
    wire [31:0] reg2_data;
    wire        reg_write;
    wire        alu_src;
    wire        mem_write;
    wire        mem_to_reg;
    wire        branch;
    wire        branch_ne;
    wire [3:0]  alu_ctrl;

    regfile u_regfile (
        .clk(clk),
        .reset(reset),
        .read_addr_1(rs1),
        .read_addr_2(rs2),
        .write_addr(rd),
        .write_enable(reg_write),
        .write_data(write_back_data),
        .read_data_1(reg1_data),
        .read_data_2(reg2_data)
    );

    // ==========================
    // Control logic
    // ==========================
    control u_control (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .branch_ne(branch_ne),
        .alu_ctrl(alu_ctrl)
    );

    // ==========================
    // ALU operands
    // ==========================
    // For most instructions the second ALU input is rs2.
    // However, I-type and S-type instructions use an immediate value.
    // A simple single-bit alu_src is not enough to distinguish all formats,
    // so we choose the correct immediate based on the opcode.
    wire [31:0] alu_b;
    assign alu_b = (opcode == 7'b0100011) ? imm_s :
                   ((opcode == 7'b0000011) || (opcode == 7'b0010011)) ? imm_i :
                   reg2_data;

    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .a(reg1_data),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );

    // ==========================
    // Data memory
    // ==========================
    wire [31:0] mem_read_data;
    dmem u_dmem (
        .clk(clk),
        .addr(alu_result),
        .write_en(mem_write),
        .write_data(reg2_data),
        .read_data(mem_read_data)
    );

    // ==========================
    // Writeback path
    // ==========================
    wire [31:0] write_back_data;
    assign write_back_data = mem_to_reg ? mem_read_data : alu_result;

    // ==========================
    // Branch logic
    // ==========================
    wire branch_equal = branch & alu_zero;
    wire branch_not_equal = branch_ne & ~alu_zero;
    assign take_branch = branch_equal | branch_not_equal;

    // For branch instructions, the next PC is relative to the current PC.
    assign pc_target = pc + imm_b;

    // The next PC is either the next sequential instruction or the branch target.
    assign pc_next = take_branch ? pc_target : pc_plus_4;

    assign pc_out = pc;

endmodule

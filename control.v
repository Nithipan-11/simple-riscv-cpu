// Control unit for the single-cycle RV32I CPU.
//
// This module decodes the instruction and turns it into control signals:
//   - reg_write: should the instruction write a value back to the register file?
//   - alu_src: should the ALU use an immediate value instead of the second register?
//   - mem_write: is this a store instruction writing to data memory?
//   - mem_to_reg: should the write-back value come from memory (lw) or the ALU?
//   - branch: is this a beq branch?
//   - branch_ne: is this a bne branch?
//   - alu_ctrl: which ALU operation should run?
//
// In a real processor, the control unit is one of the most important pieces:
// it decides what each instruction means and sets up the datapath correctly.

module control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        branch_ne,
    output reg [3:0]  alu_ctrl
);

    always @(*) begin
        // Default values: do nothing unless the instruction needs something.
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        branch_ne  = 1'b0;
        alu_ctrl   = 4'b0000;

        case (opcode)
            // ==========================
            // R-type instructions
            // ==========================
            7'b0110011: begin
                reg_write = 1'b1;

                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = 4'b0001;   // sub
                        else
                            alu_ctrl = 4'b0000;   // add
                    end
                    3'b001: alu_ctrl = 4'b0101;     // sll
                    3'b010: alu_ctrl = 4'b1000;     // slt
                    3'b100: alu_ctrl = 4'b0100;     // xor
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = 4'b0111;   // sra
                        else
                            alu_ctrl = 4'b0110;   // srl
                    end
                    3'b110: alu_ctrl = 4'b0011;     // or
                    3'b111: alu_ctrl = 4'b0010;     // and
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            // ==========================
            // I-type ALU instructions
            // ==========================
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;

                case (funct3)
                    3'b000: alu_ctrl = 4'b0000;     // addi
                    3'b010: alu_ctrl = 4'b1000;     // slti
                    3'b100: alu_ctrl = 4'b0100;     // xori
                    3'b110: alu_ctrl = 4'b0011;     // ori
                    3'b111: alu_ctrl = 4'b0010;     // andi
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            // ==========================
            // Load word (lw)
            // ==========================
            7'b0000011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                mem_to_reg = 1'b1;
                alu_ctrl  = 4'b0000; // address calculation is just add base + offset
            end

            // ==========================
            // Store word (sw)
            // ==========================
            7'b0100011: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_ctrl  = 4'b0000; // address calculation is add base + offset
            end

            // ==========================
            // Branch instructions
            // ==========================
            7'b1100011: begin
                // Branch compare depends on funct3
                branch    = (funct3 == 3'b000); // beq
                branch_ne = (funct3 == 3'b001); // bne
                alu_ctrl  = 4'b0001; // subtraction: compare rs1 - rs2
            end

            default: begin
                // Unknown opcode: do nothing.
            end
        endcase
    end

endmodule

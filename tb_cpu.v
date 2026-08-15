// Testbench for the simple single-cycle RISC-V CPU.
//
// This file exercises a small sample program to demonstrate:
//   - addi to set a register
//   - add to compute a sum
//   - sw to store a value to memory
//   - lw to read it back from memory
//   - beq to skip an instruction and branch correctly
//
// We print a register trace each clock cycle so we can observe the CPU state.

`timescale 1ns/1ps

module tb_cpu;

    reg clk;
    reg reset;
    wire [31:0] pc;

    // Instantiate the CPU under test.
    cpu uut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc)
    );

    integer cycle;
    integer i;

    // A simple helper to print register values each cycle.
    task print_trace;
        begin
            $display("cycle=%0d pc=%0d x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d x6=%0d mem0=%0d",
                     cycle,
                     pc,
                     uut.u_regfile.r[1],
                     uut.u_regfile.r[2],
                     uut.u_regfile.r[3],
                     uut.u_regfile.r[4],
                     uut.u_regfile.r[5],
                     uut.u_regfile.r[6],
                     uut.u_dmem.mem[0]);
        end
    endtask

    // 10 ns clock.
    always #5 clk = ~clk;

    initial begin
        // Start in a known state.
        clk   = 1'b0;
        reset = 1'b1;
        cycle = 0;

        // Wait a moment to make the reset take effect.
        #12;
        reset = 1'b0;

        // Run for enough cycles to finish the sample program.
        for (i = 0; i < 20; i = i + 1) begin
            #10;
            cycle = cycle + 1;
            print_trace;
        end

        $finish;
    end

endmodule

`timescale 1ns/1ps
module tb_nba;
    reg clk, reset;
    wire [31:0] pc;

    cpu #(.IMEM_FILE("program_nba.hex")) uut (.clk(clk), .reset(reset), .pc_out(pc));

    integer cycle, i;

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; cycle = 0;
        #12; reset = 0;
        for (i = 0; i < 40; i = i + 1) begin
            #10; cycle = cycle + 1;
        end
        $display("---- final state ----");
        $display("x1 (Brunson)     = %0d", uut.u_regfile.r[1]);
        $display("x2 (Harper)      = %0d", uut.u_regfile.r[2]);
        $display("x3 (Wembanyama)  = %0d", uut.u_regfile.r[3]);
        $display("x4 (Bridges)     = %0d", uut.u_regfile.r[4]);
        $display("x5 (Champagnie)  = %0d", uut.u_regfile.r[5]);
        $display("x6 (Hart)        = %0d", uut.u_regfile.r[6]);
        $display("x7 (max scorer)  = %0d  (expect 45)", uut.u_regfile.r[7]);
        $display("x8 (sum of six)  = %0d  (expect 130)", uut.u_regfile.r[8]);
        $display("mem[6] (sum)     = %0d  (expect 130)", uut.u_dmem.mem[6]);
        $display("mem[7] (max)     = %0d  (expect 45)", uut.u_dmem.mem[7]);
        $finish;
    end
endmodule

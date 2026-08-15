# Simple Single-Cycle RV32I CPU

This project is a beginner-friendly RISC-V CPU built in Verilog. It supports a small subset of RV32I instructions and keeps the datapath easy to read:

- R-type: add, sub, and, or, xor, sll, srl, sra, slt
- I-type: addi, andi, ori, xori, slti, lw
- S-type: sw
- B-type: beq, bne

The design uses a single-cycle architecture, which means each instruction is processed in one clock cycle. That makes the behavior easier to understand than a pipelined processor, even though it is less efficient in real hardware.

## How the datapath works

At a high level, a CPU does this each cycle:

1. Fetch the next instruction from instruction memory using the PC.
2. Decode the opcode and control fields.
3. Read source registers from the register file.
4. Compute the result in the ALU.
5. Optionally read or write data memory.
6. Write the result back to a destination register.
7. Update the PC for the next instruction.

The structure here follows that flow:

- `imem.v` stores the instruction words.
- `regfile.v` stores the CPU registers.
- `control.v` decides what each instruction should do.
- `alu.v` does the arithmetic and logic.
- `dmem.v` stores data for `lw` and `sw`.
- `cpu.v` connects everything together in one cycle.

## File overview

- `alu.v` — arithmetic/logic unit; one 4-bit control value chooses the operation.
- `regfile.v` — 32 x 32-bit register file; x0 is hardwired to zero.
- `imem.v` — reads `program.hex` with `$readmemh`.
- `dmem.v` — word-addressable memory used by `lw` and `sw`.
- `control.v` — opcode/funct3/funct7 decoder that drives control signals.
- `cpu.v` — the main datapath and PC update logic.
- `tb_cpu.v` — testbench with a 10 ns clock and register trace output.
- `program.hex` — simple sample program.

## Sample program

The included sample program demonstrates:

- addi x1, x0, 5
- addi x2, x0, 7
- add x3, x1, x2
- sw x3, 0(x0)
- lw x4, 0(x0)
- beq x1, x1, 8
- addi x5, x0, 99   // should be skipped
- addi x6, x0, 42   // should execute after the branch

The intended result is:

- x1 = 5
- x2 = 7
- x3 = 12
- x4 = 12
- x5 = 0 (because the branch skips the instruction that would set it)
- x6 = 42
- mem[0] = 12

## Simulating with Icarus Verilog

From a terminal, in the project folder:

1. Compile:
   `iverilog -g2012 -o sim tb_cpu.v cpu.v control.v alu.v regfile.v imem.v dmem.v`
2. Run:
   `vvp sim`

You should see a trace similar to the following:

```text
cycle=1 pc=4 x1=5 x2=0 x3=0 x4=0 x5=0 x6=0 mem0=0
cycle=2 pc=8 x1=5 x2=7 x3=0 x4=0 x5=0 x6=0 mem0=0
cycle=3 pc=12 x1=5 x2=7 x3=12 x4=0 x5=0 x6=0 mem0=0
cycle=4 pc=16 x1=5 x2=7 x3=12 x4=0 x5=0 x6=0 mem0=12
cycle=5 pc=20 x1=5 x2=7 x3=12 x4=12 x5=0 x6=0 mem0=12
cycle=6 pc=28 x1=5 x2=7 x3=12 x4=12 x5=0 x6=42 mem0=12
```

The exact cycle count may vary a little depending on how long the simulation runs, but the final register values should match the expected results above.

## Suggested next steps

This project is intentionally simple so students can see the basic structure of a processor. Good follow-up ideas:

- Add more RV32I instructions such as lui, auipc, jal, jalr, and bltu.
- Support byte and half-word memory access.
- Add a simple assembler so you can write assembly instead of raw hex.
- Explore pipelining to improve performance.
- Synthesize the design for an FPGA board.

## Why this design matters

Even though this is a simplified CPU, it includes the basics of real processor design: control logic, register file, ALU, memory, and branch handling. Understanding this project is a very good stepping stone toward larger CPU designs and more advanced architecture topics.

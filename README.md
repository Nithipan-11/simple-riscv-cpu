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
- `imem.v` — reads a hex program with `$readmemh`. Which file it loads is set by the `IMEM_FILE` parameter (default `"program.hex"`) — see [Simulating with Icarus Verilog](#simulating-with-icarus-verilog) below.
- `dmem.v` — word-addressable memory used by `lw` and `sw`.
- `control.v` — opcode/funct3/funct7 decoder that drives control signals.
- `cpu.v` — the main datapath and PC update logic; forwards `IMEM_FILE` down to `imem.v`.
- `tb_cpu.v` — testbench with a 10 ns clock and register trace output for the sample program below.
- `program.hex` — simple sample program.
- `tb_nba.v` — testbench for the NBA Finals stats demo.
- `program_nba.hex` — machine code for the NBA Finals stats demo.
- `nba_finals_g5.asm` — the assembly source for that demo.
- `asm.py` — a small two-pass assembler for turning `.asm` files like the one above into hex machine code.

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

Both demos below share the same `cpu.v` and `imem.v`. Which hex file gets loaded is controlled by the `IMEM_FILE` parameter on the `cpu` module (it defaults to `"program.hex"`), so `tb_cpu.v` and `tb_nba.v` can each point at their own program without renaming files or touching `imem.v`.

### Demo 1: register/memory sample program (`tb_cpu.v` / `program.hex`)

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
cycle=6 pc=28 x1=5 x2=7 x3=12 x4=12 x5=0 x6=0 mem0=12
cycle=7 pc=32 x1=5 x2=7 x3=12 x4=12 x5=0 x6=42 mem0=12
```

Note the branch at pc=20 (`beq x1, x1, 8`) jumps straight from pc=20 to pc=28, skipping the `addi x5, x0, 99` instruction at pc=24 — that's why x5 stays 0. Because register writes are synchronous, a value written by the instruction at a given pc shows up in the trace one cycle after that pc is fetched (e.g. x6 is written by the instruction at pc=28, so it reads 42 starting at cycle=7, not cycle=6).

The exact cycle count may vary a little depending on how long the simulation runs, but the final register values should match the expected results above.

### Demo 2: NBA Finals Game 5 stats demo (`tb_nba.v` / `program_nba.hex`)

This demo loads real point totals from the box score of NBA Finals 2026 Game 5 (Knicks 94, Spurs 90) as constants for six players, then uses the CPU's own ALU and branch logic to compute:

- the sum of those six players' points (a chain of `add` instructions), and
- the game's top scorer (a chain of `slt`/`beq` comparisons that tracks a running max),

storing both results to data memory with `sw` along the way. See `nba_finals_g5.asm` for the commented source.

1. Compile:
   `iverilog -g2012 -o sim_nba tb_nba.v cpu.v control.v alu.v regfile.v imem.v dmem.v`
2. Run:
   `vvp sim_nba`

Expected output:

```text
---- final state ----
x1 (Brunson)     = 45
x2 (Harper)      = 25
x3 (Wembanyama)  = 19
x4 (Bridges)     = 14
x5 (Champagnie)  = 14
x6 (Hart)        = 13
x7 (max scorer)  = 45  (expect 45)
x8 (sum of six)  = 130  (expect 130)
mem[6] (sum)     = 130  (expect 130)
mem[7] (max)     = 45  (expect 45)
```

## Writing your own programs with asm.py

`asm.py` is a small two-pass assembler for the instruction subset this CPU supports (see the top of this README). It lets you write labeled assembly instead of hand-encoding hex, resolving `label:` targets for `beq`/`bne` in a first pass and emitting one machine code word per instruction in a second pass. `nba_finals_g5.asm` is an example source file.

Run it with a `.asm` file and it prints one annotated line per instruction to stdout:

```
python3 asm.py nba_finals_g5.asm
```

Each line looks like `02d00093   # pc=  0  addi x1, x0, 45`. Since `$readmemh` doesn't understand the trailing `#` comment, strip everything after the hex word before saving it as a `.hex` file that `imem.v` can load, e.g.:

```
python3 asm.py nba_finals_g5.asm | awk '{print $1}' > program_nba.hex
```

## Suggested next steps

This project is intentionally simple so students can see the basic structure of a processor. Good follow-up ideas:

- Add more RV32I instructions such as lui, auipc, jal, jalr, and bltu.
- Support byte and half-word memory access.
- Extend `asm.py` with pseudo-instructions (li, mv, ...) and more directives.
- Explore pipelining to improve performance.
- Synthesize the design for an FPGA board (this project has only been simulated with Icarus Verilog so far).

## Why this design matters

Even though this is a simplified CPU, it includes the basics of real processor design: control logic, register file, ALU, memory, and branch handling. Understanding this project is a very good stepping stone toward larger CPU designs and more advanced architecture topics.

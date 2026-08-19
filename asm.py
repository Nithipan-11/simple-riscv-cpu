#!/usr/bin/env python3
"""
Minimal assembler for the simple-riscv-cpu instruction subset:
R-type: add sub and or xor sll srl sra slt
I-type: addi andi ori xori slti lw
S-type: sw
B-type: beq bne
Syntax: one instruction per line, "label:" lines allowed, "#" comments allowed.
Registers: x0-x31. Memory operand syntax: imm(rs1), e.g. "sw x1, 0(x0)".
"""
import sys, re

REGS = {f"x{i}": i for i in range(32)}

R_TYPE = {
    "add":  (0b0110011, 0b000, 0b0000000),
    "sub":  (0b0110011, 0b000, 0b0100000),
    "sll":  (0b0110011, 0b001, 0b0000000),
    "slt":  (0b0110011, 0b010, 0b0000000),
    "xor":  (0b0110011, 0b100, 0b0000000),
    "srl":  (0b0110011, 0b101, 0b0000000),
    "sra":  (0b0110011, 0b101, 0b0100000),
    "or":   (0b0110011, 0b110, 0b0000000),
    "and":  (0b0110011, 0b111, 0b0000000),
}
I_TYPE = {
    "addi": (0b0010011, 0b000),
    "slti": (0b0010011, 0b010),
    "xori": (0b0010011, 0b100),
    "ori":  (0b0010011, 0b110),
    "andi": (0b0010011, 0b111),
    "lw":   (0b0000011, 0b000),
}
B_TYPE = {
    "beq": (0b1100011, 0b000),
    "bne": (0b1100011, 0b001),
}

def reg(tok):
    tok = tok.strip().rstrip(',')
    return REGS[tok]

def parse_mem_operand(tok):
    # "0(x0)" -> (0, 'x0')
    m = re.match(r'^(-?\d+)\((x\d+)\)$', tok.strip())
    imm = int(m.group(1))
    rs1 = REGS[m.group(2)]
    return imm, rs1

def assemble(lines):
    # pass 1: collect labels -> instruction index
    labels = {}
    instrs = []
    for raw in lines:
        line = raw.split('#', 1)[0].strip()
        if not line:
            continue
        if line.endswith(':'):
            labels[line[:-1]] = len(instrs)
            continue
        instrs.append(line)

    out = []
    for idx, line in enumerate(instrs):
        parts = line.replace(',', ' ').split()
        op = parts[0]
        pc = idx * 4

        if op in R_TYPE:
            opcode, funct3, funct7 = R_TYPE[op]
            rd, rs1, rs2 = reg(parts[1]), reg(parts[2]), reg(parts[3])
            word = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

        elif op in I_TYPE:
            opcode, funct3 = I_TYPE[op]
            rd = reg(parts[1])
            if op == "lw":
                imm, rs1 = parse_mem_operand(parts[2])
            else:
                rs1 = reg(parts[2])
                imm = int(parts[3])
            word = ((imm & 0xfff) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

        elif op == "sw":
            rs2 = reg(parts[1])
            imm, rs1 = parse_mem_operand(parts[2])
            imm11_5 = (imm >> 5) & 0x7f
            imm4_0 = imm & 0x1f
            word = (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (0b010 << 12) | (imm4_0 << 7) | 0b0100011

        elif op in B_TYPE:
            opcode, funct3 = B_TYPE[op]
            rs1, rs2 = reg(parts[1]), reg(parts[2])
            target_label = parts[3]
            target_pc = labels[target_label] * 4
            imm = target_pc - pc
            imm12 = (imm >> 12) & 1
            imm11 = (imm >> 11) & 1
            imm10_5 = (imm >> 5) & 0x3f
            imm4_1 = (imm >> 1) & 0xf
            word = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_1 << 8) | (imm11 << 7) | opcode

        else:
            raise ValueError(f"unsupported instruction: {op}")

        out.append((pc, line, word & 0xffffffff))
    return out

if __name__ == "__main__":
    src_path = sys.argv[1]
    with open(src_path) as f:
        lines = f.readlines()
    assembled = assemble(lines)
    for pc, line, word in assembled:
        print(f"{word:08x}   # pc={pc:3d}  {line}")

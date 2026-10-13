#!/usr/bin/env python3
"""
encode.py — montador minimo para o ISA limitado do PBL03.

So entende exatamente as instrucoes que o riscvsingle suporta:
add, sub, and, or, xor, addi, andi, slli, srli,
lw, lb, sw, sb, beq, bne, bge, bltu, jal, jalr, lui, auipc, ecall.

Uso: escreva o programa na lista PROGRAM abaixo (uma tupla por
instrucao) e rode `python3 encode.py` para gerar program.hex
(formato aceito por $readmemh no imem.sv).
"""

REG = {f"x{i}": i for i in range(32)}
# apelidos ABI uteis
ABI = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7, "s0": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15,
    "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
}
REG.update(ABI)


def r(name):
    return REG[name]


def u(val, bits):
    return val & ((1 << bits) - 1)


def rtype(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (r(rs2) << 20) | (r(rs1) << 15) | (funct3 << 12) | (r(rd) << 7) | opcode


def itype(imm, rs1, funct3, rd, opcode):
    return (u(imm, 12) << 20) | (r(rs1) << 15) | (funct3 << 12) | (r(rd) << 7) | opcode


def stype(imm, rs2, rs1, funct3, opcode):
    imm = u(imm, 12)
    return ((imm >> 5) << 25) | (r(rs2) << 20) | (r(rs1) << 15) | (funct3 << 12) | ((imm & 0x1F) << 7) | opcode


def btype(imm, rs2, rs1, funct3, opcode):
    imm = u(imm, 13)
    b12 = (imm >> 12) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    b11 = (imm >> 11) & 1
    return (b12 << 31) | (b10_5 << 25) | (r(rs2) << 20) | (r(rs1) << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode


def utype(imm, rd, opcode):
    return (u(imm, 20) << 12) | (r(rd) << 7) | opcode


def jtype(imm, rd, opcode):
    imm = u(imm, 21)
    b20 = (imm >> 20) & 1
    b10_1 = (imm >> 1) & 0x3FF
    b11 = (imm >> 11) & 1
    b19_12 = (imm >> 12) & 0xFF
    return (b20 << 31) | (b19_12 << 12) | (b11 << 20) | (b10_1 << 21) | (r(rd) << 7) | opcode


# ---- mnemonicos ----
def add(rd, rs1, rs2):  return rtype(0b0000000, rs2, rs1, 0b000, rd, 0b0110011)
def sub(rd, rs1, rs2):  return rtype(0b0100000, rs2, rs1, 0b000, rd, 0b0110011)
def and_(rd, rs1, rs2): return rtype(0b0000000, rs2, rs1, 0b111, rd, 0b0110011)
def or_(rd, rs1, rs2):  return rtype(0b0000000, rs2, rs1, 0b110, rd, 0b0110011)
def xor(rd, rs1, rs2):  return rtype(0b0000000, rs2, rs1, 0b100, rd, 0b0110011)

def addi(rd, rs1, imm): return itype(imm, rs1, 0b000, rd, 0b0010011)
def andi(rd, rs1, imm): return itype(imm, rs1, 0b111, rd, 0b0010011)
def slli(rd, rs1, sh):  return itype(sh & 0x1F, rs1, 0b001, rd, 0b0010011)
def srli(rd, rs1, sh):  return itype(sh & 0x1F, rs1, 0b101, rd, 0b0010011)

def lw(rd, imm, rs1):   return itype(imm, rs1, 0b010, rd, 0b0000011)
def lb(rd, imm, rs1):   return itype(imm, rs1, 0b000, rd, 0b0000011)
def sw(rs2, imm, rs1):  return stype(imm, rs2, rs1, 0b010, 0b0100011)
def sb(rs2, imm, rs1):  return stype(imm, rs2, rs1, 0b000, 0b0100011)

def beq(rs1, rs2, imm): return btype(imm, rs2, rs1, 0b000, 0b1100011)
def bne(rs1, rs2, imm): return btype(imm, rs2, rs1, 0b001, 0b1100011)
def bge(rs1, rs2, imm): return btype(imm, rs2, rs1, 0b101, 0b1100011)
def bltu(rs1, rs2, imm):return btype(imm, rs2, rs1, 0b110, 0b1100011)

def jal(rd, imm):       return jtype(imm, rd, 0b1101111)
def jalr(rd, rs1, imm): return itype(imm, rs1, 0b000, rd, 0b1100111)

def lui(rd, imm20):     return utype(imm20, rd, 0b0110111)
def auipc(rd, imm20):   return utype(imm20, rd, 0b0010111)

def ecall():            return itype(0, "zero", 0b000, "zero", 0b1110011)


# ============================================================
# Programa de teste (sanity check do core) — ver explicacao no
# chat: soma valores, testa branch/loop, testa lui/auipc, store
# e load de byte/word.
# ============================================================
PROGRAM = [
    lui("s0", 0x00002),       # 0: s0 = 0x00002000 (base de dados)
    addi("t0", "zero", 5),    # 4: t0 = 5
    addi("t1", "zero", 10),   # 8: t1 = 10
    add("t2", "t0", "t1"),    # c: t2 = 15
    sw("t2", 0, "s0"),        # 10: mem[0x2000] = 15
    lw("t3", 0, "s0"),        # 14: t3 = mem[0x2000]  (espera 15)
    addi("t4", "zero", 65),   # 18: t4 = 65 ('A')
    sb("t4", 4, "s0"),        # 1c: mem[0x2004] = 65 (byte)
    lb("t5", 4, "s0"),        # 20: t5 = mem[0x2004]  (espera 65)
    addi("a0", "zero", 0),    # 24: a0 = 0 (contador do loop)
    addi("a1", "zero", 3),    # 28: a1 = 3 (limite)
    # loop:
    addi("a0", "a0", 1),      # 2c: a0++
    bltu("a0", "a1", -4),     # 30: enquanto a0 < a1, volta para 'addi a0,a0,1'
    auipc("a2", 0),           # 34: a2 = PC atual (0x34)
    ecall(),                  # 38: sinaliza fim (placar/observacao em a0)
]

with open("program.hex", "w") as f:
    for instr in PROGRAM:
        f.write(f"{instr:08x}\n")

print(f"Gerado program.hex com {len(PROGRAM)} instrucoes.")

//------------------------------------------------------------------------------
// Funcoes de codificacao (assembler minimo) das 22 instrucoes
//------------------------------------------------------------------------------
`ifndef RISCV_ENCODE
`define RISCV_ENCODE

function automatic bit [31:0] rv_r(bit [6:0] f7, int rs2, int rs1, bit [2:0] f3, int rd, bit [6:0] op);
  return {f7, rs2[4:0], rs1[4:0], f3, rd[4:0], op};
endfunction

function automatic bit [31:0] rv_i(int imm, int rs1, bit [2:0] f3, int rd, bit [6:0] op);
  return {imm[11:0], rs1[4:0], f3, rd[4:0], op};
endfunction

function automatic bit [31:0] rv_s(int imm, int rs2, int rs1, bit [2:0] f3);
  return {imm[11:5], rs2[4:0], rs1[4:0], f3, imm[4:0], 7'b0100011};
endfunction

function automatic bit [31:0] rv_b(int imm, int rs2, int rs1, bit [2:0] f3);
  return {imm[12], imm[10:5], rs2[4:0], rs1[4:0], f3, imm[4:1], imm[11], 7'b1100011};
endfunction

function automatic bit [31:0] rv_u(int imm20, int rd, bit [6:0] op);
  return {imm20[19:0], rd[4:0], op};
endfunction

function automatic bit [31:0] rv_j(int imm, int rd);
  return {imm[20], imm[10:1], imm[11], imm[19:12], rd[4:0], 7'b1101111};
endfunction

// R-type
function automatic bit [31:0] rv_add (int rd, int rs1, int rs2); return rv_r(7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011); endfunction
function automatic bit [31:0] rv_sub (int rd, int rs1, int rs2); return rv_r(7'b0100000, rs2, rs1, 3'b000, rd, 7'b0110011); endfunction
function automatic bit [31:0] rv_and (int rd, int rs1, int rs2); return rv_r(7'b0000000, rs2, rs1, 3'b111, rd, 7'b0110011); endfunction
function automatic bit [31:0] rv_or  (int rd, int rs1, int rs2); return rv_r(7'b0000000, rs2, rs1, 3'b110, rd, 7'b0110011); endfunction
function automatic bit [31:0] rv_xor (int rd, int rs1, int rs2); return rv_r(7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011); endfunction

// I-type (aritmeticas)
function automatic bit [31:0] rv_addi(int rd, int rs1, int imm);   return rv_i(imm, rs1, 3'b000, rd, 7'b0010011); endfunction
function automatic bit [31:0] rv_andi(int rd, int rs1, int imm);   return rv_i(imm, rs1, 3'b111, rd, 7'b0010011); endfunction
function automatic bit [31:0] rv_xori(int rd, int rs1, int imm);   return rv_i(imm, rs1, 3'b100, rd, 7'b0010011); endfunction
function automatic bit [31:0] rv_slli(int rd, int rs1, int shamt); return rv_i(shamt & 31, rs1, 3'b001, rd, 7'b0010011); endfunction
function automatic bit [31:0] rv_srli(int rd, int rs1, int shamt); return rv_i(shamt & 31, rs1, 3'b101, rd, 7'b0010011); endfunction

// Loads / stores
function automatic bit [31:0] rv_lw(int rd, int rs1, int imm);  return rv_i(imm, rs1, 3'b010, rd, 7'b0000011); endfunction
function automatic bit [31:0] rv_lb(int rd, int rs1, int imm);  return rv_i(imm, rs1, 3'b000, rd, 7'b0000011); endfunction
function automatic bit [31:0] rv_lbu(int rd, int rs1, int imm); return rv_i(imm, rs1, 3'b100, rd, 7'b0000011); endfunction
function automatic bit [31:0] rv_sw(int rs2, int rs1, int imm); return rv_s(imm, rs2, rs1, 3'b010); endfunction
function automatic bit [31:0] rv_sb(int rs2, int rs1, int imm); return rv_s(imm, rs2, rs1, 3'b000); endfunction

// Desvios (offset em bytes, relativo ao PC da propria instrucao)
function automatic bit [31:0] rv_beq (int rs1, int rs2, int off); return rv_b(off, rs2, rs1, 3'b000); endfunction
function automatic bit [31:0] rv_bne (int rs1, int rs2, int off); return rv_b(off, rs2, rs1, 3'b001); endfunction
function automatic bit [31:0] rv_blt (int rs1, int rs2, int off); return rv_b(off, rs2, rs1, 3'b100); endfunction
function automatic bit [31:0] rv_bge (int rs1, int rs2, int off); return rv_b(off, rs2, rs1, 3'b101); endfunction
function automatic bit [31:0] rv_bltu(int rs1, int rs2, int off); return rv_b(off, rs2, rs1, 3'b110); endfunction

// Saltos, lui, auipc, ecall
function automatic bit [31:0] rv_jal  (int rd, int off);        return rv_j(off, rd); endfunction
function automatic bit [31:0] rv_jalr (int rd, int rs1, int imm); return rv_i(imm, rs1, 3'b000, rd, 7'b1100111); endfunction
function automatic bit [31:0] rv_lui  (int rd, int imm20);      return rv_u(imm20, rd, 7'b0110111); endfunction
function automatic bit [31:0] rv_auipc(int rd, int imm20);      return rv_u(imm20, rd, 7'b0010111); endfunction
function automatic bit [31:0] rv_ecall();                       return 32'h00000073; endfunction

// Instrucao que termina o programa neste perfil (ecall, ou jal x0,0 = salto para si mesmo)
function automatic bit [31:0] rv_end();
`ifdef RV_PROFILE_COLEGA
  return rv_jal(0, 0);
`else
  return rv_ecall();
`endif
endfunction

`endif

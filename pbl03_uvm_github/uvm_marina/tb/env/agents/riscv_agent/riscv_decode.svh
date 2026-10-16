//------------------------------------------------------------------------------
// Decodificador padrao RV32I (estrito) + perfil de cada DUT
//
// rv_decode   : o que a instrucao E, segundo a especificacao RISC-V.
//               Encodings invalidos (funct7/funct3 fora do padrao) => K_OTHER.
// rv_supported: o DUT implementa essa instrucao? (depende do perfil)
//               Nao suportada => o DUT deve IGNORAR (PC+4, nenhum efeito).
// rv_is_end   : a instrucao que termina o programa (ecall ou jal x0,0)
//------------------------------------------------------------------------------
`ifndef RISCV_DECODE
`define RISCV_DECODE

typedef enum int {
  K_ADD, K_SUB, K_AND, K_OR, K_XOR,
  K_ADDI, K_ANDI, K_XORI, K_SLLI, K_SRLI,
  K_LW, K_LB, K_LBU, K_SW, K_SB,
  K_BEQ, K_BNE, K_BLT, K_BGE, K_BLTU,
  K_JAL, K_JALR, K_LUI, K_AUIPC, K_ECALL,
  K_OTHER
} rv_kind_e;

function automatic rv_kind_e rv_decode(bit [31:0] instr);
  bit [6:0] op = instr[6:0];
  bit [2:0] f3 = instr[14:12];
  bit [6:0] f7 = instr[31:25];
  case (op)
    7'b0110011: begin                                   // R-type
      if (f7 == 7'b0100000)
        return (f3 == 3'b000) ? K_SUB : K_OTHER;
      if (f7 == 7'b0000000) begin
        case (f3)
          3'b000: return K_ADD;
          3'b111: return K_AND;
          3'b110: return K_OR;
          3'b100: return K_XOR;
          default: return K_OTHER;
        endcase
      end
      return K_OTHER;
    end
    7'b0010011: begin                                   // I-type aritmetica
      case (f3)
        3'b000: return K_ADDI;
        3'b111: return K_ANDI;
        3'b100: return K_XORI;
        3'b001: return (f7 == 7'b0000000) ? K_SLLI : K_OTHER;
        3'b101: return (f7 == 7'b0000000) ? K_SRLI : K_OTHER;   // srai (f7=0100000) => K_OTHER
        default: return K_OTHER;
      endcase
    end
    7'b0000011: begin
      case (f3)
        3'b010: return K_LW;
        3'b000: return K_LB;
        3'b100: return K_LBU;
        default: return K_OTHER;
      endcase
    end
    7'b0100011: begin
      case (f3)
        3'b010: return K_SW;
        3'b000: return K_SB;
        default: return K_OTHER;
      endcase
    end
    7'b1100011: begin
      case (f3)
        3'b000: return K_BEQ;
        3'b001: return K_BNE;
        3'b100: return K_BLT;
        3'b101: return K_BGE;
        3'b110: return K_BLTU;
        default: return K_OTHER;
      endcase
    end
    7'b1101111: return K_JAL;
    7'b1100111: return (f3 == 3'b000) ? K_JALR : K_OTHER;
    7'b0110111: return K_LUI;
    7'b0010111: return K_AUIPC;
    7'b1110011: return (instr == 32'h0000_0073) ? K_ECALL : K_OTHER;
    default:    return K_OTHER;
  endcase
endfunction

// O DUT implementa essa instrucao?
function automatic bit rv_supported(rv_kind_e k);
`ifdef RV_PROFILE_COLEGA
  // 19: add addi and andi xor xori srli lw sw lbu sb beq bne blt bge jal jalr lui auipc
  return !(k inside {K_SUB, K_OR, K_SLLI, K_LB, K_BLTU, K_ECALL, K_OTHER});
`else
  // 22: add sub and or xor addi andi slli srli lw lb sw sb beq bne bge bltu jal jalr lui auipc ecall
  return !(k inside {K_XORI, K_LBU, K_BLT, K_OTHER});
`endif
endfunction

// Instrucao que termina o programa
function automatic bit rv_is_end(bit [31:0] instr);
`ifdef RV_PROFILE_COLEGA
  return (instr == 32'h0000_006F);          // jal x0,0 : salta para si mesmo
`else
  return (instr == 32'h0000_0073);          // ecall
`endif
endfunction

`endif

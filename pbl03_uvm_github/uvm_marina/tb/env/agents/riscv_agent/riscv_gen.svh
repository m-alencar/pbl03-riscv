//------------------------------------------------------------------------------
// Gerador de programas aleatorios (funcao pura: mesmos dados 'rnd' => mesmo programa)
//
// Regras (para o programa sempre terminar e ser verificavel):
//   * prologo: x1..x29 recebem valores aleatorios (lui+addi); x31 = base da dmem
//   * x30 e x31 sao reservados (x30 so para o par auipc/jalr; x31 = base)
//   * desvios e jal so para frente (nunca loop infinito)
//   * jalr sempre no par:  auipc x30,0 ; jalr rd,x30,imm   (salto para frente)
//   * nenhum salto cai no jalr de um par (x30 ficaria desatualizado)
//   * epilogo: sw de x0..x29 na memoria (o valor de cada registrador aparece em
//     WriteData e e comparado) + instrucao de fim (ecall ou jal x0,0, conforme o perfil)
//   * so gera instrucoes do perfil do DUT (RV_PROFILE_MARINA / RV_PROFILE_COLEGA)
//
// Precisa de rnd.size() >= 4*N + 32 palavras aleatorias.
//------------------------------------------------------------------------------
`ifndef RISCV_GEN
`define RISCV_GEN

typedef bit [31:0] rv_word_q[$];

localparam int RVS_RALU = 0, RVS_IALU = 1, RVS_LUI = 2, RVS_AUIPC = 3, RVS_LOAD = 4,
               RVS_STORE = 5, RVS_BRANCH = 6, RVS_JAL = 7, RVS_AUIPC30 = 8, RVS_JALR = 9;

// escolhe o destino (indice de slot) de um salto para frente
function automatic int rv_pick_target(int i0, int k, int n_slots, int kind[]);
  int t = i0 + k;
  if (t > n_slots) t = n_slots;
  while (t < n_slots && kind[t] == RVS_JALR) t++;
  return t;
endfunction

function automatic rv_word_q rv_gen_program(int N, bit [31:0] rnd[]);
  rv_word_q  words;
  int        kind[];
  bit [31:0] v, hi;
  int        lo;

  // ---------------- prologo
  for (int r = 1; r <= 29; r++) begin
    v  = rnd[4*N + r];
    lo = int'({{20{v[11]}}, v[11:0]});
    hi = v - 32'(lo);
    words.push_back(rv_lui(r, int'(hi >> 12)));
    words.push_back(rv_addi(r, r, lo));
  end
  words.push_back(rv_addi(31, 0, `RV_DATA_BASE));

  // ---------------- corpo, passo 1: tipo de cada slot
  kind = new[N];
  for (int i = 0; i < N; i++) begin
    int unsigned c = rnd[4*i] % 100;
    if      (c < 20) kind[i] = RVS_RALU;
    else if (c < 38) kind[i] = RVS_IALU;
    else if (c < 42) kind[i] = RVS_LUI;
    else if (c < 46) kind[i] = RVS_AUIPC;
    else if (c < 58) kind[i] = RVS_LOAD;
    else if (c < 70) kind[i] = RVS_STORE;
    else if (c < 82) kind[i] = RVS_BRANCH;
    else if (c < 87) kind[i] = RVS_JAL;
    else if (c < 92) begin
      if (i + 1 < N) begin
        kind[i]   = RVS_AUIPC30;
        kind[i+1] = RVS_JALR;
        i++;
      end else kind[i] = RVS_RALU;
    end
    else kind[i] = RVS_RALU;
  end

  // ---------------- corpo, passo 2: gera as instrucoes
  for (int i = 0; i < N; i++) begin
    bit [31:0] r0 = rnd[4*i];
    bit [31:0] r1 = rnd[4*i+1];
    bit [31:0] r2 = rnd[4*i+2];
    bit [31:0] r3 = rnd[4*i+3];
    int rs1 = int'(r1[7:0])  % 30;
    int rs2 = int'(r1[15:8]) % 30;
    int rd  = 1 + int'(r3[7:0]) % 29;
    int imm = int'({{20{r2[11]}}, r2[11:0]});
    int sel, tgt;
    if (r3[11:8] == 4'h0) rd = 0;           // as vezes escreve em x0 (deve ser ignorado)

    case (kind[i])
      RVS_RALU: begin
`ifdef RV_PROFILE_COLEGA
        sel = int'(r0[15:8]) % 3;                 // add, and, xor
        case (sel)
          0: words.push_back(rv_add(rd, rs1, rs2));
          1: words.push_back(rv_and(rd, rs1, rs2));
          default: words.push_back(rv_xor(rd, rs1, rs2));
        endcase
`else
        sel = int'(r0[15:8]) % 5;                 // add, sub, and, or, xor
        case (sel)
          0: words.push_back(rv_add(rd, rs1, rs2));
          1: words.push_back(rv_sub(rd, rs1, rs2));
          2: words.push_back(rv_and(rd, rs1, rs2));
          3: words.push_back(rv_or (rd, rs1, rs2));
          default: words.push_back(rv_xor(rd, rs1, rs2));
        endcase
`endif
      end
      RVS_IALU: begin
        sel = int'(r0[15:8]) % 4;
        case (sel)
          0: words.push_back(rv_addi(rd, rs1, imm));
          1: words.push_back(rv_andi(rd, rs1, imm));
`ifdef RV_PROFILE_COLEGA
          2: words.push_back(rv_xori(rd, rs1, imm));
`else
          2: words.push_back(rv_slli(rd, rs1, int'(r2[4:0])));
`endif
          default: words.push_back(rv_srli(rd, rs1, int'(r2[4:0])));
        endcase
      end
      RVS_LUI:   words.push_back(rv_lui  (rd, int'(r2[19:0])));
      RVS_AUIPC: words.push_back(rv_auipc(rd, int'(r2[19:0])));
      RVS_LOAD: begin
        if (r0[16]) words.push_back(rv_lw(rd, 31, 4 * int'(r2[5:0])));   // 0..252
`ifdef RV_PROFILE_COLEGA
        else        words.push_back(rv_lbu(rd, 31, int'(r2[7:0])));      // 0..255
`else
        else        words.push_back(rv_lb(rd, 31, int'(r2[7:0])));       // 0..255
`endif
      end
      RVS_STORE: begin
        if (r0[16]) words.push_back(rv_sw(rs2, 31, 4 * int'(r2[5:0])));
        else        words.push_back(rv_sb(rs2, 31, int'(r2[7:0])));
      end
      RVS_BRANCH: begin
        sel = int'(r0[15:8]) % 4;
        if (r3[15:12] < 4'd5) rs2 = rs1;     // com frequencia compara um registrador com ele mesmo
        tgt = rv_pick_target(i, 1 + int'(r2[1:0]), N, kind);
        case (sel)
          0: words.push_back(rv_beq (rs1, rs2, 4 * (tgt - i)));
          1: words.push_back(rv_bne (rs1, rs2, 4 * (tgt - i)));
`ifdef RV_PROFILE_COLEGA
          2: words.push_back(rv_blt (rs1, rs2, 4 * (tgt - i)));
          default: words.push_back(rv_bge (rs1, rs2, 4 * (tgt - i)));
`else
          2: words.push_back(rv_bge (rs1, rs2, 4 * (tgt - i)));
          default: words.push_back(rv_bltu(rs1, rs2, 4 * (tgt - i)));
`endif
        endcase
      end
      RVS_JAL: begin
        tgt = rv_pick_target(i, 1 + int'(r2[1:0]), N, kind);
        words.push_back(rv_jal(rd, 4 * (tgt - i)));
      end
      RVS_AUIPC30: begin
        // par: auipc x30,0 (slot i) ; jalr rd,x30,imm (slot i+1)
        tgt = rv_pick_target(i + 1, 1 + int'(r2[1:0]), N, kind);
        words.push_back(rv_auipc(30, 0));
        // imm as vezes impar: o jalr deve zerar o bit 0 do destino (cai no mesmo alvo)
        words.push_back(rv_jalr(rd, 30, 4 * (tgt - i) + int'(r3[16])));
        i++;
      end
      default: words.push_back(rv_addi(0, 0, 0));   // RVS_JALR nunca chega aqui sozinho
    endcase
  end

  // ---------------- epilogo: despeja x0..x29 e termina
  for (int r = 0; r <= 29; r++)
    words.push_back(rv_sw(r, 31, `RV_DUMP_OFFSET + 4*r));
  words.push_back(rv_end());

  return words;
endfunction

`endif

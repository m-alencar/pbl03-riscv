//------------------------------------------------------------------------------
// riscv_ref_model: simulador de conjunto de instrucoes (ISS) - o "gabarito".
// Recebe o PROGRAMA (do driver), executa instrucao por instrucao com
// regs[32] / mem / pc e publica o riscv_trace ESPERADO de cada ciclo.
// E escrito a partir da especificacao da ISA (nao copia a estrutura do RTL).
// Instrucao fora do perfil do DUT (rv_supported) = ignorada, como o DUT deve fazer.
//------------------------------------------------------------------------------
`ifndef RISCV_REF_MODEL
`define RISCV_REF_MODEL

class riscv_ref_model extends uvm_component;

  `uvm_component_utils(riscv_ref_model)

  uvm_analysis_imp  #(riscv_program, riscv_ref_model) prog_export;   // programa vindo do driver
  uvm_analysis_port #(riscv_trace)                    rm2sb_port;    // trace esperado

  bit [31:0] regs[32];
  bit [7:0]  mem[`RV_DMEM_BYTES];
  bit [31:0] imem[`RV_IMEM_WORDS];

  function new(string name = "riscv_ref_model", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    prog_export = new("prog_export", this);
    rm2sb_port  = new("rm2sb_port", this);
  endfunction

  // chamado pelo driver a cada programa
  function void write(riscv_program p);
    run_program(p);
  endfunction

  // ---- acesso a memoria de dados (endereco usa so os 12 bits baixos, como o DUT)
  function bit [31:0] rd_word(bit [31:0] addr);
    bit [11:0] a = addr[11:0];
    return {mem[a + 12'd3], mem[a + 12'd2], mem[a + 12'd1], mem[a]};
  endfunction

  function bit [31:0] rd_byte_sext(bit [31:0] addr);
    bit [11:0] a = addr[11:0];
    return {{24{mem[a][7]}}, mem[a]};
  endfunction

  function bit [31:0] rd_byte_zext(bit [31:0] addr);
    bit [11:0] a = addr[11:0];
    return {24'h0, mem[a]};
  endfunction

  function void wr_word(bit [31:0] addr, bit [31:0] d);
    bit [11:0] a = addr[11:0];
    mem[a]           = d[7:0];
    mem[a + 12'd1]   = d[15:8];
    mem[a + 12'd2]   = d[23:16];
    mem[a + 12'd3]   = d[31:24];
  endfunction

  function void wr_byte(bit [31:0] addr, bit [31:0] d);
    bit [11:0] a = addr[11:0];
    mem[a] = d[7:0];
  endfunction

  // ---- execucao do programa
  function void run_program(riscv_program p);
    bit [31:0] pc, next_pc, instr;
    bit [31:0] a, b, res, addr;
    bit [31:0] immI, immS, immB, immJ, immU;
    bit [4:0]  rd, rs1, rs2;
    bit        wr, taken;
    rv_kind_e  kind;
    riscv_trace t;
    bit ended = 0;

    foreach (regs[i]) regs[i] = 32'h0;
    foreach (imem[i]) imem[i] = 32'h0;
    for (int i = 0; i < p.words.size() && i < `RV_IMEM_WORDS; i++) imem[i] = p.words[i];
    foreach (mem[i]) mem[i] = p.init_data[i];

    pc = 32'h0;
    for (int n = 0; n < p.max_cycles && !ended; n++) begin
      instr = imem[pc[13:2]];
      rd  = instr[11:7];
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      a   = regs[rs1];
      b   = regs[rs2];
      immI = {{20{instr[31]}}, instr[31:20]};
      immS = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      immB = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      immJ = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      immU = {instr[31:12], 12'b0};

      next_pc = pc + 32'd4;
      wr      = 0;
      res     = 32'h0;
      taken   = 0;

      t = riscv_trace::type_id::create("exp");
      t.pc        = pc;
      t.instr     = instr;
      t.memwrite  = 1'b0;
      t.aluresult = 32'hx;
      t.writedata = 32'hx;
      t.ecall     = 1'b0;
      t.start     = (n == 0);

      // instrucao fora do perfil do DUT => ignorada (PC+4, sem efeitos)
      kind = rv_decode(instr);
      if (!rv_supported(kind)) kind = K_OTHER;

      case (kind)
        K_ADD:  begin res = a + b;   wr = 1; end
        K_SUB:  begin res = a - b;   wr = 1; end
        K_AND:  begin res = a & b;   wr = 1; end
        K_OR:   begin res = a | b;   wr = 1; end
        K_XOR:  begin res = a ^ b;   wr = 1; end
        K_ADDI: begin res = a + immI; wr = 1; end
        K_ANDI: begin res = a & immI; wr = 1; end
        K_XORI: begin res = a ^ immI; wr = 1; end
        K_SLLI: begin res = a << instr[24:20]; wr = 1; end
        K_SRLI: begin res = a >> instr[24:20]; wr = 1; end
        K_LW: begin
          addr = a + immI;
          t.aluresult = addr;
          res = rd_word(addr);       wr = 1;
        end
        K_LB: begin
          addr = a + immI;
          t.aluresult = addr;
          res = rd_byte_sext(addr);  wr = 1;
        end
        K_LBU: begin
          addr = a + immI;
          t.aluresult = addr;
          res = rd_byte_zext(addr);  wr = 1;
        end
        K_SW: begin
          addr = a + immS;
          t.memwrite = 1'b1; t.aluresult = addr; t.writedata = b;
          wr_word(addr, b);
        end
        K_SB: begin
          addr = a + immS;
          t.memwrite = 1'b1; t.aluresult = addr; t.writedata = b;
          wr_byte(addr, b);
        end
        K_BEQ:  begin taken = (a == b);                    if (taken) next_pc = pc + immB; end
        K_BNE:  begin taken = (a != b);                    if (taken) next_pc = pc + immB; end
        K_BLT:  begin taken = ($signed(a) <  $signed(b));  if (taken) next_pc = pc + immB; end
        K_BGE:  begin taken = ($signed(a) >= $signed(b));  if (taken) next_pc = pc + immB; end
        K_BLTU: begin taken = (a < b);                     if (taken) next_pc = pc + immB; end
        K_JAL:  begin res = pc + 32'd4; wr = 1; next_pc = pc + immJ; end
        K_JALR: begin res = pc + 32'd4; wr = 1; next_pc = (a + immI) & 32'hFFFF_FFFE; end
        K_LUI:  begin res = immU;      wr = 1; end
        K_AUIPC:begin res = pc + immU; wr = 1; end
        default: ;   // K_OTHER / nao suportada: ignorada
      endcase

      // fim do programa: ecall (perfil Marina) ou jal x0,0 (perfil Colega).
      // No perfil Colega o "fim" e um salto para si mesmo: o ISS para aqui.
      if (rv_is_end(instr)) begin
        t.ecall = 1'b1;
        next_pc = pc;
      end

      if (wr && rd != 5'd0) regs[rd] = res;   // x0 e sempre zero
      t.taken = taken;

      `uvm_info(get_type_name(), {"TRACE FROM REF MODEL: ", t.convert2string()}, UVM_HIGH)
      rm2sb_port.write(t);

      if (t.ecall) ended = 1;
      pc = next_pc;
    end
    if (!ended)
      `uvm_warning(get_type_name(), $sformatf("ISS: programa '%s' nao chegou ao ecall em %0d ciclos", p.tag, p.max_cycles))
  endfunction

endclass : riscv_ref_model

`endif

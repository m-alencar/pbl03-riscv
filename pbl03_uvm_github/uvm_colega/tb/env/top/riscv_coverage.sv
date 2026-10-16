//------------------------------------------------------------------------------
// riscv_coverage: cobertura funcional (amostrada no trace esperado do ISS)
//------------------------------------------------------------------------------
`ifndef RISCV_COVERAGE
`define RISCV_COVERAGE

class riscv_coverage #(type T = riscv_trace) extends uvm_subscriber #(T);

  `uvm_component_utils(riscv_coverage)

  rv_kind_e    kind;
  bit          taken;
  bit          rd_is_x0;
  bit          writes_rd;
  bit [4:0]    shamt;
  bit [1:0]    byte_off;

  covergroup riscv_cg;
    option.per_instance = 1;

    // cada uma das 22 instrucoes foi executada?
    cp_kind: coverpoint kind {
      bins instr[] = {[K_ADD:K_ECALL]};
`ifdef RV_PROFILE_COLEGA
      ignore_bins nao_suportadas = {K_SUB, K_OR, K_SLLI, K_LB, K_BLTU, K_ECALL};
`else
      ignore_bins nao_suportadas = {K_XORI, K_LBU, K_BLT};
`endif
    }

    // cada desvio foi tomado e nao tomado?
    cp_br: coverpoint kind {
      bins beq  = {K_BEQ};
      bins bne  = {K_BNE};
      bins bge  = {K_BGE};
`ifdef RV_PROFILE_COLEGA
      bins blt  = {K_BLT};
`else
      bins bltu = {K_BLTU};
`endif
    }
    cp_taken: coverpoint taken {
      bins not_taken = {0};
      bins taken_b   = {1};
    }
    cx_branch: cross cp_br, cp_taken;

    // deslocamentos: shamt 0, intermediario, 31
    cp_shamt: coverpoint shamt iff (kind == K_SLLI || kind == K_SRLI) {
      bins zero = {0};
      bins mid  = {[1:30]};
      bins max  = {31};
    }

    // escrita em x0 (deve ser ignorada) x escrita normal
    cp_rd_x0: coverpoint rd_is_x0 iff (writes_rd) {
      bins x0     = {1};
      bins not_x0 = {0};
    }

    // alinhamento do endereco em lb/sb (4 posicoes dentro da palavra)
    cp_byte_off: coverpoint byte_off iff (kind == K_LB || kind == K_LBU || kind == K_SB) {
      bins off[] = {[0:3]};
    }
  endgroup

  function new(string name = "riscv_coverage", uvm_component parent);
    super.new(name, parent);
    riscv_cg = new();
  endfunction

  function void write(T t);
    kind     = rv_decode(t.instr);
    taken    = t.taken;
    rd_is_x0 = (t.instr[11:7] == 5'd0);
    writes_rd = !(kind inside {K_SW, K_SB, K_BEQ, K_BNE, K_BLT, K_BGE, K_BLTU, K_ECALL, K_OTHER});
    shamt    = t.instr[24:20];
    byte_off = t.aluresult[1:0];
    riscv_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COVERAGE", $sformatf("cobertura funcional = %0.2f%%", riscv_cg.get_inst_coverage()), UVM_LOW)
  endfunction

endclass

`endif

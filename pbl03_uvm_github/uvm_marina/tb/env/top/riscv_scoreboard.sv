//------------------------------------------------------------------------------
// riscv_scoreboard: o JUIZ. Compara, ciclo a ciclo, o trace esperado (ISS)
// com o trace real (monitor).
//
// Campos comparados (com !==, entao X no DUT conta como erro):
//   pc        sempre            (primeiro: se o fluxo de controle divergiu, o resto nao importa)
//   instr     sempre            (confere que o DUT esta executando o que foi carregado)
//   memwrite  sempre
//   aluresult so load/store     (e o endereco; nas outras instrucoes nao tem significado)
//   writedata so store          (sb: so o byte baixo)
//   ecall     sempre
//
// No primeiro erro de um programa, 1 uvm_error e o scoreboard ignora os itens
// restantes ate o proximo programa (evita erros em cascata).
//------------------------------------------------------------------------------
`ifndef RISCV_SCOREBOARD
`define RISCV_SCOREBOARD

`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

class riscv_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(riscv_scoreboard)

  uvm_analysis_imp_exp #(riscv_trace, riscv_scoreboard) exp_export;   // do ISS
  uvm_analysis_imp_act #(riscv_trace, riscv_scoreboard) act_export;   // do monitor

  riscv_trace exp_q[$];
  riscv_trace act_q[$];

  bit          skip;            // 1: ignorando itens ate o proximo programa
  bit          prog_failed;
  int unsigned cyc;             // ciclo dentro do programa
  int unsigned n_cycles, n_programs, n_prog_fail, n_errors;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_export = new("exp_export", this);
    act_export = new("act_export", this);
  endfunction

  function void write_exp(riscv_trace t);
    exp_q.push_back(t);
    process();
  endfunction

  function void write_act(riscv_trace t);
    act_q.push_back(t);
    process();
  endfunction

  // ALUResult so e comparado quando o ISS executou o acesso (aluresult conhecido):
  // lb/lh/sh nao suportados viram NOP no ISS e o endereco do DUT nao tem significado.
  function bit is_ldst(bit [31:0] instr);
    return (instr[6:0] == 7'b0000011) || (instr[6:0] == 7'b0100011);
  endfunction

  function void fail(string msg, riscv_trace e, riscv_trace a);
    n_errors++;
    if (!prog_failed) begin
      prog_failed = 1;
      n_prog_fail++;
    end
    `uvm_error("MISMATCH", $sformatf("programa %0d, ciclo %0d: %s\n  esperado: %s\n  obtido  : %s",
               n_programs, cyc, msg, e.convert2string(), a.convert2string()))
    skip = 1;
  endfunction

  function void compare(riscv_trace e, riscv_trace a);
    n_cycles++;
    if (a.pc !== e.pc)               begin fail("PC diferente", e, a);        return; end
    if (a.instr !== e.instr)         begin fail("INSTRUCAO diferente", e, a); return; end
    if (a.memwrite !== e.memwrite)   begin fail("MEMWRITE diferente", e, a);  return; end
    if (is_ldst(e.instr) && !$isunknown(e.aluresult) && (a.aluresult !== e.aluresult))
                                     begin fail("ENDERECO (ALUResult) diferente", e, a); return; end
    if (e.memwrite) begin
      if (e.instr[14:12] == 3'b000) begin   // sb: so o byte baixo vai para a memoria
        if (a.writedata[7:0] !== e.writedata[7:0])
          begin fail("DADO do sb diferente", e, a); return; end
      end else begin
        if (a.writedata !== e.writedata)
          begin fail("DADO do sw diferente", e, a); return; end
      end
    end
    if (a.ecall !== e.ecall)         begin fail("ECALL diferente", e, a);     return; end
    if (e.ecall) skip = 1;           // fim normal do programa; ignora o que vier depois
  endfunction

  function void process();
    riscv_trace e, a;
    while (1) begin
      if (skip) begin
        while (exp_q.size() && !exp_q[0].start) void'(exp_q.pop_front());
        while (act_q.size() && !act_q[0].start) void'(act_q.pop_front());
        if (exp_q.size() && act_q.size()) skip = 0;   // os dois comecam um programa novo
        else return;
      end
      if (exp_q.size() == 0 || act_q.size() == 0) return;

      e = exp_q.pop_front();
      a = act_q.pop_front();

      if (e.start != a.start) begin                   // fluxos desalinhados
        if (e.start) exp_q.push_front(e);
        if (a.start) act_q.push_front(a);
        n_errors++;
        `uvm_error("MISALIGN", $sformatf("programa %0d: numero de ciclos diferente entre ISS e DUT", n_programs))
        if (!prog_failed) begin prog_failed = 1; n_prog_fail++; end
        skip = 1;
        continue;
      end
      if (e.start) begin
        n_programs++;
        prog_failed = 0;
        cyc = 0;
      end else cyc++;

      compare(e, a);
    end
  endfunction

  function void report_phase(uvm_phase phase);
    string test_name;
    if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) test_name = "TEST CASE";

    `uvm_info("SB_SUMMARY", $sformatf("programas=%0d  falhos=%0d  ciclos comparados=%0d  erros=%0d",
              n_programs, n_prog_fail, n_cycles, n_errors), UVM_LOW)

    if (n_cycles == 0)
      `uvm_error("SB_EMPTY", "nenhum ciclo foi comparado: o teste nao exercitou o DUT")

    if (n_errors == 0 && n_cycles > 0) begin
      $write("%c[7;32m", 27);
      $display("-----------------------------------------------");
      $display("------ INFO : %0s PASSED ------", test_name);
      $display("-----------------------------------------------");
      $write("%c[0m", 27);
    end else begin
      $write("%c[7;31m", 27);
      $display("-----------------------------------------------");
      $display("------ ERROR : %0s FAILED ------", test_name);
      $display("-----------------------------------------------");
      $write("%c[0m", 27);
    end
  endfunction

endclass : riscv_scoreboard

`endif

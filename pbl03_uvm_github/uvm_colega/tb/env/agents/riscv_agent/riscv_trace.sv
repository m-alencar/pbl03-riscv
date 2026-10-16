//------------------------------------------------------------------------------
// riscv_trace: item de OBSERVACAO. Um item = um ciclo do processador.
// Campos 'logic' (4 estados) e comparacao com !== para enxergar X/Z do RTL.
//------------------------------------------------------------------------------
`ifndef RISCV_TRACE
`define RISCV_TRACE

class riscv_trace extends uvm_sequence_item;

  logic [31:0] pc;
  logic [31:0] instr;
  logic        memwrite;
  logic [31:0] aluresult;   // so tem significado para load/store (endereco)
  logic [31:0] writedata;   // so tem significado para store
  logic        ecall;
  bit          start;       // 1 no primeiro ciclo de cada programa
  bit          taken;       // so preenchido pelo ISS (desvio tomado?), usado na cobertura

  `uvm_object_utils(riscv_trace)

  function new(string name = "riscv_trace");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("pc=%h instr=%h (%s) memwrite=%b alu=%h wdata=%h ecall=%b%s",
                     pc, instr, rv_decode(instr).name(), memwrite, aluresult, writedata, ecall,
                     start ? " [start]" : "");
  endfunction

endclass

`endif
